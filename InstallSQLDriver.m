%% Add Microsoft SQL Server JDBC drivers to Matlab's Classpath
%   This script will copy the Microsoft SQL Server drivers into the 
%   Matlab installations root folder and add definitions for them 
%   to the Matlab classpath.txt and librarypath.txt definitions
%   
%   Check-list before execution:
%     1) Current Matlab path is the location of this .m file (DO NOT ADD PATH!!!)
%     2) The sqlserver folder is present in the same directory as this script
%   
%   Original Version - Chris Remington - October 12, 2012
%   Revised - Chris Remington - April 29, 2014
%     - Looks at a network location for the driver files instead of a local directory that
%       needs to be copied to the user's matchine

%% Preliminary Action
% Clear all variables and the screen
% clear,clc
% Prompt the user if they have the current working directory set to the location of this
% script
% strResponse = input('Is the current working directory the location of this script?\n(DO NOT DO AN ADDPATH TO THE LOCATION) y/[n]: ', 's');
% if ~strcmp('y',strResponse)
%     % Throw an error warning the user 
%     error('InstallSQLDriver:WrongPath', 'Please set the current working directory to the location of this script and re-run it.');
% end

% Path to driver files
driverPath = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\OBD Capability GUI\CapabilityGUI\sqldriver';

%% Copy SQL Server Driver Files
% Copy the SQL server driven files to the correct location in the matlab root directory

% Check that the 'sqldriver' folder is present on the network
if ~exist(driverPath,'dir')
    % Thow an error
    error('InstallSQLDriver:FolderMissing','Cannot locate the ''sqldriver'' folder that contains the driver files on the network.');
else
    % Check that the files weren't already copied into Matlab's installation directory
    if ~exist(fullfile(matlabroot, 'sqldriver'), 'dir')
        % Copy the folder of drivers to the Matlab directory
        copyfile(driverPath,fullfile(matlabroot,'sqldriver'))
    else
        % Display a warning that the files aren't going to be copied
        warning('InstallSQLDriver:FolderPresent','Already found the ''sqldriver'' folder in the Matlab installation directory. Skipping driver file copy.');
    end
end

%% Check Each File Made It To The Matlab Root Directory
% sqljdbc4.jar
if ~exist(fullfile(matlabroot,'sqldriver\jar\sqljdbc4.jar'), 'file')
    % Throw an error that
    error('InstallSQLDriver:FileMissing','The sqljdbc.jar file wasn''t copied correctly to the Matlab root directory.')
end
% sqljdbc_auth.dll (x86)
if ~exist(fullfile(matlabroot,'sqldriver\dll\x86\sqljdbc_auth.dll'), 'file')
    % Throw an error that
    error('InstallSQLDriver:FileMissing','The 32-bit version of the sqljdbc_auth.dll file wasn''t copied correctly to the Matlab root directory.')
end
% sqljdbc_auth.dll (x64)
if ~exist(fullfile(matlabroot,'sqldriver\dll\x64\sqljdbc_auth.dll'), 'file')
    % Throw an error that
    error('InstallSQLDriver:FileMissing','The 64-bit version of the sqljdbc_auth.dll file wasn''t copied correctly to the Matlab root directory.')
end

%% Modify classpath.txt
% This will add the location of the java (.jar) drivers to the Matlab's java classpath
% listing so they can be utilized by Matlab

% Set the classpath to true by default (meaning that lines will be added to the end of the
% classpath.txt file unless the below code finds them already present)
classpath = true;
% Open a file pointer to the classpath file for reading only
fid = fopen(fullfile(matlabroot, 'toolbox\local\classpath.txt'), 'r');
% Get the first line
l = fgetl(fid);
% Start looping until the end of the file is reached
while ischar(l)
    % If either of these lines match
    if strcmp('## Remington Addition: Added below to connect to SQL Server using a Microsoft provided JDBC class library',l) ...
            || strcmp('$matlabroot/sqldriver/jar/sqljdbc4.jar',l)
        % Additions are already present, set the error flag
        classpath = false;
        % Break out of the loop
        break
    end
    % Get the next line
    l = fgetl(fid);
end
% Close the file
fclose(fid);

% If the additions weren't already found
if classpath
    % Open the classpath.txt file for appending this time
    fid = fopen(fullfile(matlabroot, 'toolbox\local\classpath.txt'), 'a');
    % Append the following lines to the end of the file
    fprintf(fid,'%s\n','## Remington Addition: Add below to connect to SQL Server using a Microsoft provided JDBC class library');
    fprintf(fid,'%s\n','$matlabroot/sqldriver/jar/sqljdbc4.jar');
    % Close the file
    fclose(fid);
else
    % Display a warning that classpath.txt has already been modofied
    warning('InstallSQLDriver:Classpath','The ''classpath.txt'' file has already has the required modifications made.');
end

%% Modify librarypath.txt
% This will add the locations of the Windows SQL Server integrated security drivers for
% both 32-bit and 64-bit windows to Matlab's library path so that the SQL Server driver
% can have access to them
% SQL Server Integrated Security alloys a user to "log-in" to SQL Server using the
% cridentials of the Windows User Accout they are currently logged-in with. This allows
% for both greater security (only specified users on the CED domain can have access to the
% data and they don't need a common or weak password to log-in) and greater ease of use
% (as there is no need to specify a passwork beyond what it already takes to log-in to
% windows)

% Set the librarypath to true by default (meaning that lines will be added to the end of
% the librarypath.txt file unless the below code finds them already present)
librarypath = true;
% Open a file pointer to the librarypath file for reading only
fid = fopen(fullfile(matlabroot, 'toolbox\local\librarypath.txt'), 'r');
% Get the first line
l = fgetl(fid);
% Start looping until the end of the file is reached
while ischar(l)
    % If either of these lines match
    if strcmp('## Remington Addition: Added to enable integrated security on SQLServer with the JDBC driver.',l) ...
            || strcmp('win32=$matlabroot/sqldriver/dll/x86',l) ...
            || strcmp('win64=$matlabroot/sqldriver/dll/x64',l);
        % Additions are already present, set the error flag
        librarypath = false;
        % Break out of the loop
        break
    end
    % Get the next line
    l = fgetl(fid);
end
% Close the file
fclose(fid);

% If the additions weren't already found
if librarypath
    % Open the librarypath.txt file for appending this time
    fid = fopen(fullfile(matlabroot, 'toolbox\local\librarypath.txt'), 'a');
    % Append the following lines to the end of the file
    fprintf(fid,'%s\n','## Remington Addition: Added to enable integrated security on SQLServer with the JDBC driver');
    fprintf(fid,'%s\n','win32=$matlabroot/sqldriver/dll/x86');
    fprintf(fid,'%s\n','win64=$matlabroot/sqldriver/dll/x64');
    % Close the file
    fclose(fid);
else
    % Display a warning that librarypath.txt has already been modofied
    warning('InstallSQLDriver:Librarypath','The ''librarypath.txt'' file has already has the required modifications made.');
end

%% Closing Message
% Print a success message and a note to restart Matlab
disp('Successfully added the Microsoft SQL Server drivers to Matlab');
disp('Please restart Matlab for the changes to take effect.');
