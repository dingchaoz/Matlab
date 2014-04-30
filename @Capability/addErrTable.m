function recordsAdded = addErrTable(obj, fileName, software)
%Append a new errtable.xml to the database table tblErrTable
%   This is a copy of the addErrorTable method, but will instead use the C2ST
%   errtable.xml file as input instead of the error_table text file in the build files
%   
%   This will keep stacking newer errtable.xml files in with the older ones
%   so that there is a persistant record of all errtable.xml files over all
%   software versions.
%   
%   If you don't specify the file name or the calibration version, you'll get a pop-up
%   dialog that will prompt you to choose a .csv file, then you will get a command prompt
%   in the Matlab workspace that will direct you to enter a software version.
%   
%   Usage: recordsAdded = addErrTable(obj, fileName, software)
%          recordsAdded = addErrTable(obj)
%          recordsAdded = addErrTable(obj, [], software)
%          recordsAdded = addErrTable(obj, fileName, [])
%   
%   Inputs---
%   fileName: (optional) Full path of an error_table file
%   software: (optional) The software version of that file (in numeric format)
%   
%   Output--- returns the number of records uploaded to the database
%   
%   Original Version - Chris Remington - June 4, 2012
%   Adapted - Chris Remington - May 6, 2013
%       - Modified to use the C2ST errtable.xml as an input because this is avaiable
%           is a standard format for all Cummins ECM software builds
    
    %% Preliminary Error Checking
    
    % If no file name or an empty name was passed in
    if ~exist('fileName','var') || isempty(fileName)
        % Open a prompt for the user to select a file
        [fname,pathname] = uigetfile('*.xml','Select errtable.xml file');
        fileName = fullfile(pathname, fname);
    end
    
    % If no software version or an empty was passed in
    if ~exist('software','var') || isempty(software)
        % Prompt for a software version
        software = input('Please enter the numeric software version: ');
    end
    
    % If the file specified does not exist
    if ~exist(fileName, 'file')
        % Bad file name specified, throw an error
        error('Capability:addErrTable:FileDoesNotExist', 'File name specified does not exist: %s', fileName);
    end
    
    % Check if there is already data from this software version
    d = fetch(obj.conn, sprintf('SELECT [Error_Table_ID] FROM [tblErrTable] WHERE [SoftwareVersion] = %.0f', software));
    % If the return dataset is not empty, there was already data present for this software
    if ~isempty(d)
        % Write a line to the command window
        fprintf('There are already %.0f records present in the database for software version %.0f\r', length(d.Error_Table_ID), software)
        % Set an error noting this condition
        error('Capability:addErrTable:RecordsAlreadyExist', ...
            'There are already %.0f records present in the database for software version %.0f', ...
            length(d.Error_Table_ID), software)
    end
    
    %% Read in and process the data
    
    % Read in the errtable
    errTable = readErrTable(fileName);
    
    % Get the list of all columns in the errTable
    fieldNames = fields(errTable);
    % If there aren't the same number of columns as expected, throw an error
    if length(fieldNames) ~= 41
        % Throw an error noting this condition
        error('Capability:addErrTable:UnexpectedColumnLength','There were %.0f columns in the errtable.xml file when 41 were expected.',length(fieldNames))
    end
    % Pull out the list of eliminated system errors
    eliminated = errTable.SysErrorEliminate_Flag;
    % For each field in the errTable
    for i = 1:length(fieldNames)
        % Trim the entries from each column that have been eliminated from the error table
        errTable.(fieldNames{i}) = errTable.(fieldNames{i})(~eliminated);
    end
    
    % Remove the 'SysErrorEliminate_Flag' field as we're done with it
    errTable = rmfield(errTable, 'SysErrorEliminate_Flag');
    
    % Generate the software column in the structure
    errTable.SoftwareVersion = repmat(software,length(errTable.Error_Table_ID),1);
    % Generate the error index column
    errTable.Error_Index = (1:length(errTable.Error_Table_ID))';
    
    %% Upload the data to the database
    
    % Keep track of time
    tic
    disp('Starting upload')
    
    % Upload the dataset into the database
    fastinsert(obj.conn, 'dbo.tblErrTable', fields(errTable),errTable)
    
    % Query that database to return the count of records present
    d = fetch(obj.conn, sprintf('SELECT Count([Error_Table_ID]) As NumLines FROM [tblErrTable] WHERE [SoftwareVersion] = %.0f GROUP BY [SoftwareVersion]',software));
    % If something other than an empty set was returned
    if ~isempty(d)
        % Pull out the numeric value
        recordsAdded = d.NumLines;
    else
        % Throw an error as something should have been uplaoded
        error('Capability:addErrTable:NoRecordsAdded', 'Unknown failue, no records with the specified software were found after the data was uploaded.');
    end
    
    % Print elapsed time
    toc
end

function errTable = readErrTable(fileName)
%Parse a C2ST errtable.xml file and return a Matlab format data-set
%   This will read in the errtable.xml output of C2ST and parse it into a structure
%   that can be used in Matlab
%   
%   Original Version - Chris Remington - May 2, 2013
    
    % Use xlsread to read in the file as it is really an Excel file in .xml format
    [~, ~, rawData] = xlsread(fileName);
    
    % Loop through each column
    for i = 1:size(rawData,2)
        % If the data is numeric
        if sum(cellfun(@isnumeric,rawData(2:end,i))) == size(rawData,1)-1
            % Convert it to a double and add to the structure
            errTable.(rawData{1,i}) = cell2mat(rawData(2:end,i));
        else
            % Leave it as a cell array and add to the structure
            errTable.(rawData{1,i}) = rawData(2:end,i);
        end
    end
end
