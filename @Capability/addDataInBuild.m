function recordsAdded = addDataInBuild(obj, fileName, cal)
%Append another version of the datainbuild file to the table tblDataInBuild
%   This will keep stacking newer datainbuild files in with the older ones
%   so that there is a persistant record of all datainbuilds over all
%   calibration versions.
%   
%   If you don't specify the file name or the calibration version, you'll get a pop-up
%   dialog that will prompt you to choose a .csv file, then you will get a command prompt
%   in the Matlab workspace that will direct you to enter a cal version.
%   
%   Usage: recordsAdded = addDataInBuild(obj, fileName, cal)
%          recordsAdded = addDataInBuild(obj)
%   
%   Inputs---
%   fileName: (optional, all or none) Full path of a datainbuild file
%   cal:      (optional, all or none) The cal version of that file (in numeric format)
%   
%   Output--- returns the number of records uploaded to the database
%   
%   Original Version - Chris Remington - January 10, 2011
%   Revised - Chris Remington - June 6, 2012
%       - Added ability to specify no inputs and have dialogs prompt the user for input
%       - Modified the documentation of this function
%   Modified - Chris Remington - September 13, 2012
%       - Modified to account for the two new columns added the the datainbuild.csv output
%           around about the end of June
%   Modified - Chris Remington - October 2, 2012
%       - Modified to upload the column "VersionNotes" added after the "Datavdesc" column
%   Modified - Chris Remington - December 17, 2012
%       - Modified to correctly upload the new column "Scalar_Override_Tool_Unit"
    
    % If no file name or an empty name was passed in, open a prompt to select a file
    if ~exist('fileName','var') || isempty(fileName)
        [fname,pathname] = uigetfile('*.csv','Select datainbuild.csv file from C2ST');
        fileName = fullfile(pathname, fname);
    end
    
    % If no calibration version or an empty was passed in, prompt for a cal version
    if ~exist('cal','var') || isempty(cal)
        %cal = inputdlg('Enter the software version for the specified file:','Datainnbuild.csv Information',1);
        cal = input('Please enter the numeric software version: ');
    end
    
    % Check that the given file name is valid
    if exist(fileName, 'file')
        % Continue
        
        % Check if records already exist for this version of software
        % Do not proceede if the software already exists
        numRecordsNow = obj.getNumDIBParameters(cal);
        if numRecordsNow > 0
            % On error, print the number of records already present for that
            % calibration version, then throw an error.
            disp([num2str(numRecordsNow,'%.0f') ' records for calibration version ' num2str(cal) ' are already in the database.'])
            error('Capability:addDataInBuild', 'Calibration version specified already contains records in the datainbuild table.');
        end
        
        tic
        % Call readDataInBuild to do the heavy lifting
        % This reads the file and puts the output into a cell array
        data = obj.readDataInBuild(fileName, cal);
        
        disp('Finished reading file, starting upload'),toc,tic
        
        % Define the headings of the database columns
        DIBcolumnNames = {'Build', 'Component', 'ComponentView', 'Data', 'DataID', ...
            'DataVID', 'CompInterface', 'DataType', 'DataTypeFormat', ...
            'Unit', 'ArraySize', 'Min', 'Max', 'Accuracy', 'BNumber', ...
            'MaxLatency', 'DefaultValue', 'SoftwareParamType', 'ECMDataType', ...
            'PublicDataID', 'SubfileNumber', 'GroupTeam', 'EditLevel', ...
            'BTypeSizeBytes', 'DisplayDecimalDigits', 'Legacy', 'XAxis', ...
            'YAxis', 'ScalarToolUnitConv', 'ParamName', 'MappedTo', ...
            'VersionNotes', 'ScalarOverrideToolUnit', 'Datavdesc', 'Calibration'};
        
        % Attempt to add this data to the table
        fastinsert(obj.conn, 'tblDataInBuild', DIBcolumnNames, data);
        
        disp('Finished uploading'),toc
        
        % Count the number of records added
        % Query that database to return the count of records
        recordsAdded = obj.getNumDIBParameters(cal);
    else
        % Bad file name specified, throw an error
        error('Capability:addDataInBuild', 'Bad file name specified.');
    end
end
