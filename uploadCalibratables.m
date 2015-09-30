function uploadCalibratables(matFile,program,family,calVersion,calRevision)
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
%   verion info
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S132377;instanceName=CapabilityDev;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));
    
    % Clear out the old data entry from the database
 %curs = exec(conn,sprintf('DELETE FROM [dbo].[tblCals2] WHERE [Family] = ''%s''',family));
%     % Close and clear the cursor
%     close(curs);clear curs;
    
%     sqlquery = 'select max ([CalVersion]) FROM [Acadia].[dbo].[tblCal3]';
   % curs = exec(conn,'select max ([CalVersion]) FROM [Acadia].[dbo].[tblCal3]');
    curs = exec(conn,sprintf('select CalVersion FROM [dbo].[tblCals3] where CalVersion in ''%s''',calVersion));
    curs = fetch(curs);
    
    %results = fetch(conn,sqlquery);


    % Open the new file for reading
    fid = fopen(matFile,'r');
    % Read in the binary data bit-by-bit and put into a logical array
    A = fread(fid,Inf,'ubit1=>logical');
    
    % Upload the data and engine family to the database
    fastinsert(conn,'[dbo].[tblCals3]',{'Family','MatFile','CalVersion','CalRev'},{family,A,calVersion,calRevision});
    
    % Close the file
    fclose(fid);
    
    % Close the database connection
    close(conn)
    
end
