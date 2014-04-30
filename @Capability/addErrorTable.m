function recordsAdded = addErrorTable(obj, fileName, cal)
%Append a new error_table to the database table tblErrorTable
%   This will keep stacking newer error_tables in with the older ones
%   so that there is a persistant record of all error_tables over all
%   calibration versions.
%   
%   If you don't specify the file name or the calibration version, you'll get a pop-up
%   dialog that will prompt you to choose a .csv file, then you will get a command prompt
%   in the Matlab workspace that will direct you to enter a cal version.
%   
%   Usage: recordsAdded = addErrorTable(obj, fileName, cal)
%          recordsAdded = addErrorTable(obj)
%          recordsAdded = addErrorTable(obj, [], cal)
%          recordsAdded = addErrorTable(obj, fileName, [])
%   
%   Inputs---
%   fileName: (optional) Full path of an error_table file
%   cal:      (optional) The cal version of that file (in numeric format)
%   
%   Output--- returns the number of records uploaded to the database
%   
%   Original Version - Chris Remington - June 4, 2012
%   Revised - N/A - N/A
    
    %% Preliminary Error Checking
    
    % If no file name or an empty name was passed in, open a prompt to select a file
    if ~exist('fileName','var') || isempty(fileName)
        [fname,pathname] = uigetfile('*.*','Select error_table file');
        fileName = fullfile(pathname, fname);
    end
    
    % If no calibration version or an empty was passed in, prompt for a cal version
    if ~exist('cal','var') || isempty(cal)
        %cal = inputdlg('Enter the software version for the specified file:','Datainnbuild.csv Information',1);
        cal = input('Please enter the numeric software version: ');
    end
    
    % If the file specified does not exist
    if ~exist(fileName, 'file')
        % Bad file name specified, throw an error
        error('Capability:addErrorTable:FileDoesNotExist', 'File name specified does not exist: %s', fileName);
    end
    
    % Check if there is already data from this cal version
    d = fetch(obj.conn, sprintf('SELECT [SEID] FROM [tblErrorTable] WHERE [SoftwareVersion] = %.0f', cal));
    % If the return dataset is not empty, there was already data present for this cal
    if ~isempty(d)
        % Write a line to the command window
        fprintf('There are already %.0f records present in the database for software version %.0f\r', length(d.SEID), cal)
        % Set an error noting this condition
        error('Capability:addErrorTable:RecordsAlreadyExist', ...
            'There are already %.0f records present in the database for software version %.0f', ...
            length(d.SEID), cal)
    end
    
    %% Read in the raw data file
    % Keep track of time
    tic
    disp('Starting file read')
    
    % Open the file for reading
    fid = fopen(fileName);
    % If the file opened successfully
    if fid > -1
        data = textscan(fid, ...
            '%s %d16 %s %n %n %n %n %d16 %s %d %d16 %d16 %d16 %d16 %s %s %s %u8 %u8 %n %d16 %s %d %n %s %d16 %s %d16 %d16 %d16 %d16 %s %d16 %d %s %s %d16 %s', ...
            'delimiter', '|', 'HeaderLines', 38, 'ReturnOnError', false);
        %'%s %d %s %d %d %d %d %d %s %d %d %d %d %d %s %s %s %d %d %d %d %s %d %d %s %d %s
        %%d %d %d %d %s %d %d %s %s %d %s', 
    else
        % Failed to open the file, throw an error
        error('Capability:addErrorTable:FailedToOpenFile', ...
            'Failed to successfully open file %s', fileName);
    end
    % Close the file
    fclose(fid);
    
    %% Parse and format the data read in
    % Put the data into a big cell matrix that can be uploaded with the database toolbox
    
    % Initalize the output (38+2 columns by as many rows as were read in)
    formatted = cell(length(data{1}),length(data)+2);
    % For each column of data read in
    for i = 1:length(data)
        % If this is a numeric column
        if isnumeric(data{i})
            % Convert it to a cell array
            formatted(:,i) = num2cell(data{i});
        % Elseif this is a cell string column
        elseif iscellstr(data{i})
            % Trim the strings from the characters read in
            formatted(:,i) = strtrim(data{i});
        else
            % Shouldn't be able to get here
            error('Capability:addErrorTable:UnknownError', 'Unknown datatype read in.')
        end
    end
    % Assign the software version to each value in the empty column on the end
    formatted(:,end-1) = {cal};
    % Add the System Error Number (Index + 1) to each line
    formatted(:,end) = num2cell(1:length(data{i}))';
    % Print elapsed time
    toc
    
    %% Upload the data to the database
    
    % Keep track of time
    tic
    disp('Starting upload')
    
    % Define the headings of the database columns
    columnNames = {'Component', 'SEID', 'SystemErrorName', ...
                   'CountdownMode', 'RecSnapshot', 'Persistence', 'CreateFault', ...
                   'FaultCode', 'Lamp', 'J1939SPN', 'J1939FMI', 'J1587PID', 'J1587SID', ...
                   'J1587FMI', 'OBDType', 'OBDLamp', 'OBDCompleteType', 'OBDTrips', ...
                   'OBDOperationCycles', 'OBDCOCCP', 'OBDIOCC', 'OBDClearConfirmType', ...
                   'OBDECF', 'OBDReadinessEnable', 'OBDSimiliarConditions', 'OBDOCCPSC', ...
                   'OBDDerateType', 'OBDDuration1', 'OBDTorque1', 'OBDDuration2', ...
                   'OBDTorque2', 'OBDDenominatorType', 'OBDDenominatorCount', ...
                   'OBDDenominatorTime', 'J2012CodeType', 'J2012CodeNumber', ...
                   'HighPriority', 'OBDAggregateGrouping', 'SoftwareVersion', 'SEN'};
    
    % Attempt to add this data to the table
    fastinsert(obj.conn, 'tblErrorTable', columnNames, formatted);
    
    % Query that database to return the count of records present
    d = fetch(obj.conn, sprintf('SELECT Count([SEID]) As NumLines FROM [tblErrorTable] WHERE [SoftwareVersion] = %.0f GROUP BY [SoftwareVersion]',cal));
    % If something other than an empty set was returned
    if ~isempty(d)
        % Pull out the numeric value
        recordsAdded = d.NumLines;
    else
        % Throw an error as something should have been uplaoded
        error('Capability:addErrorTable:NoRecordsAdded', 'Unknown failue, no records with the specified software were found after the data was uploaded.');
    end
    
    % Print elapsed time
    toc
end
