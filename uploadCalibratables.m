function uploadCalibratables(matFile,xmlFile,program,family,calVersion,calRevision)
%   Uploads the .mat files with the calibratable values into the database
%   
%   Usage: uploadCalibratables(fileList, family)
%   
%   Inputs -
%   matFile: Full path to the .mat file with the calibrations in it
%   program: Name of the engine program (for opening the database connection)
%   family:  Name of the engine family assosiated with the .mat file
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 29, 2012
%   Revised - Chris Remington - January 13, 2014
    
    % Minimal error checking for now
    
    % Open a connection to the database here
    % Maybe in the future this could use the SQLBasics object to get it's connection
    
%   Revised - Dingchao Zhang - Sep 30th, 2015    
%   - Enable script to isert mainline cals' rev and
%   verion info, add xml file binary file into database
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S132377;instanceName=CapabilityDev;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));
    
    %% Execute SQL query to see if the cal version already exists
    Cal_Ver = exec(conn,sprintf('select CalVersion FROM [dbo].[tblCals3] where CalVersion in (''%s'')',calVersion));
    % Fetch the query
    Cal_Ver = fetch(Cal_Ver);
    
    %% Execute SQL query to see if the cal revision already exists
    Cal_Rev = exec(conn,sprintf('select CalRev FROM [dbo].[tblCals3] where CalRev in (''%s'')',calRevision));
    % Fetch the query
    Cal_Rev = fetch(Cal_Rev);
    
    % If the cal version and revision does not exist, insert the cal in
    if strcmp(Cal_Rev.Data,'No Data') || strcmp(Cal_Ver.Data,'No Data')
        
        % Open the new file for reading
        fid = fopen(matFile,'r');
        % Read in the binary data bit-by-bit and put into a logical array
        A = fread(fid,Inf,'ubit1=>logical');

        % Upload the data and engine family to the database
        fastinsert(conn,'[dbo].[tblCals3]',{'Family','MatFile','CalVersion','CalRev'},{family,A,calVersion,calRevision});
        
         % Open the new file for reading
        fid_xml = fopen(xmlFile,'r');
        % Read in the binary data bit-by-bit and put into a logical array
        A_xml = fread(fid_xml,Inf,'ubit1=>logical');

        % Upload the data and engine family to the database
        fastinsert(conn,'[dbo].[tblCals2]',{'Family','MatFile','CalVersion','CalRev'},{family,A_xml,calVersion,calRevision});
        
        
        
        % Close the file
        fclose(fid);

        % Close the database connection
        close(conn)
    
    else
    % Else print cal already uploaded    
         fprintf('Cal Version %s and Revision %s is already uploaded to database cal table.\n',calVersion,calRevision)
    
    end
end
