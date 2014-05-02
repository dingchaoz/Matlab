function uploadCalibratables(matFile,program,family)
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
    conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W3-A22649;instanceName=CAPABILITYDB;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));
    
    % Clear out the old data entry from the database
    curs = exec(conn,sprintf('DELETE FROM [dbo].[tblCals] WHERE [Family] = ''%s''',family));
    % Close and clear the cursor
    close(curs);clear curs;
    
    % Open the new file for reading
    fid = fopen(matFile,'r');
    % Read in the binary data bit-by-bit and put into a logical array
    A = fread(fid,Inf,'ubit1=>logical');
    
    % Upload the data and engine family to the database
    fastinsert(conn,'[dbo].[tblCals]',{'Family','MatFile'},{family,A});
    
    % Close the file
    fclose(fid);
    
    % Close the database connection
    close(conn)
    
end
