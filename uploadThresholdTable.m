%   Upload threhold names and values as a table format to tblCals or
%   tblCals1 table in Database
%   
%   Original Version - Dingchao Zhang - Nov 11, 2015
%   Revised - Dingchao Zhang - Dec 18, 2015
%     - Append (1) to all the table threshold names to match with
%     processing list format
    

function uploadThresholdTable(matFile,program,family,calVersion,calRev)
    
    % Define Conn
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S129433;instanceName=CapabilityDB;database=',program,...
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
        
        % Append "(1)" to threshold name ending with tbl to match with processing list
        %%% In the future, maybe certain threhold table's other position's
        %%% threshold will be requested by 3 step onwer, then this part of
        %%% script needs to be updated further

        for i = 1:length(Threshold)
            
            % Split the threhold name using _ as the spliter
            split_thd = strsplit(Threshold{i},'_');
            
            % Compare if the last part of the threshold name is Tbl
            if strcmp(split_thd(length(split_thd)), 'Tbl')
                % If yes, append (1) to the end of the name
                Threshold{i} = strcat(Threshold{i},'(1)');
                
            end

        end

       
        %% Fill up Family, Calver and CalRev to an array of the same length of parameters
        %% so these cell arrays can be uploaded to the database schema
        % Create array of lengths of threshold values
        Family = cell(1,length(Value));
        CalVersion = cell(1,length(Value));
        CalRev = cell(1,length(Value));
        
        %% Fill up the cell array with strings of values
        Family(1,:) = cellstr(family);
        CalVersion(1,:) = cellstr(num2str(calVersion));
        CalRev(1,:) = cellstr(num2str(calRev));
        
         % Transpose Value and Family arrays to conform to Threshold    
        Value = Value';
        Family = Family';
       

        % Create calTable struct to hold table to be inserted
        calTable = struct('Family',{},'CalVersion',{},'CalRev',{},'Threshold',{},'Value',{});
        
        % Fill up the structure of Caltable
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
        fprintf('Cal Version %s and Revision %s is uploaded to database cal table in Family %s of program %s.\n',calVersion,calRev, family,program);
    
    else
        
        % Else print cal already uploaded     
         fprintf('Cal Version %s and Revision %s was already uploaded to database cal table in Family %s of program %s.\n',calVersion,calRev, family,program);
    end
     
end
