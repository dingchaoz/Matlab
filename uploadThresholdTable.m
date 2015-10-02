function uploadThresholdTable(matFile,program,family,calVersion,calRev)
    
    % Define Conn
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S132377;instanceName=CapabilityDev;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));


    %% Execute SQL query to see if the cal version already exists
    Cal_Ver = exec(conn,sprintf('select CalVersion FROM [dbo].[tblCals1] where CalVersion in (''%s'') and Family = ''%s''' ,calVersion,family));
    % Fetch the query
    Cal_Ver = fetch(Cal_Ver);
    
    %% Execute SQL query to see if the cal revision already exists
    Cal_Rev = exec(conn,sprintf('select CalRev FROM [dbo].[tblCals1] where CalRev in (''%s'') and Family = ''%s''',calRev,family));
    % Fetch the query
    Cal_Rev = fetch(Cal_Rev);
    
    % If the cal version and revision does not exist, insert the cal in
    if strcmp(Cal_Rev.Data,'No Data') || strcmp(Cal_Ver.Data,'No Data')

    
        % Cal file location for test
        % matFile =  '..\tempcal\Acadia\Default\Default_export.mat';
        % 
        % Get all the threshold names from the mat file
        Threshold = who('-file', matFile);

        % Cell array to hold threshold values
        Value = cell(1,length(Threshold));
        
        % Load all threshold names and values
        load(matFile);

        % Fill up value cell array
        for i = 1:length(Threshold)

            Value{i} = eval(Threshold{i}); 
            % Check if the threshold is a single float number
            t = (size(Value{i}) == 1);
            % if it is not, such as instead a matrix or vector
            if t ~= 2
                % Get the first element instead
                Value{i} = Value{i}(1);
            end

        end

       
        
        Family = cell(1,length(Value));
        CalVersion = cell(1,length(Value));
        CalRev = cell(1,length(Value));
        
        Family(1,:) = cellstr(family);
        CalVersion(1,:) = cellstr(num2str(calVersion));
        CalRev(1,:) = cellstr(num2str(calRev));
        
         % Reshape Value and Family to conform to Threshold    
        Value = Value';
        Family = Family';
       

        % Create calTable struct to hold table to be inserted
        calTable = struct('Family',{},'CalVersion',{},'CalRev',{},'Threshold',{},'Value',{});

        calTable(1).Threshold = Threshold;
        calTable(1).Value = Value;
        calTable(1).Family = Family;
        calTable(1).CalVersion = CalVersion;
        calTable(1).CalRev = CalRev;

        % Upload the data and engine family to the database
        fastinsert(conn,'[dbo].[tblCals1]',fields(calTable),calTable);
        
        % Close the database connection
        close(conn)
    
        % Else print cal already uploaded    
        fprintf('Cal Version %s and Revision %s is uploaded to database cal table.\n',calVersion,calRev);
    
    else
        
        % Else print cal already uploaded    
        fprintf('Cal Version %s and Revision %s was already uploaded to database cal table.\n',calVersion,calRev);
    end
     
end
