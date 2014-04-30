function SingleMinMaxData(obj, pdid, dir)
%Exports all MinMax data from the database to Excel Files and Mat Files
%   This rountine will export a .mat and .xlsb file of Min/Max data from the parameter
%   specified by it's public data id
%   
%   Usage: SingleMinMaxData(obj, pdid, dir)
%   
%   Inputs -
%   dir:      Location of the base directory where the files should be stored
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 27, 2012
%   Adapted - Chris Remington - Sept 17, 2012
%       - Modified to only export one parameter, where another master function will loop
%           and call this function to export all of the parameters of data
    
    % Get a listing of all software versions present in tblDataInBuild
    s = fetch(obj.conn, 'SELECT MAX([SoftwareVersion]) As MaxSW FROM [dbo].[tblErrTable]');
    % Get the name of the parameter
    name = obj.GetDataInfo(pdid, max(s.MaxSW), 'Data');
    
    % Display the current parameter
    fprintf('Working on parameter: %s\n', name)
    
    % Pull the data from the database
    [output, rawData] = pullMinMaxData(obj, pdid, name);
    
    % Generate the sheet name
    % If the parameter name is larger than 31 characters
    if length(name)>31
        % Trim the length of the name to 31 characters
        sheetName = name(1:31);
    else
        % Keep the full name as the sheet name
        sheetName = name;
    end
    
    % Try to make spreadsheet (this will (should) overwrite the old data)
    try
        xlswrite(fullfile(dir, 'Excel', [name '.xlsb']), output, sheetName)
    catch ex
        % If it failed because the directory doesn't exist, make it
        if strcmp(ex.identifier, 'MATLAB:COM:E2148140012')
            % Make the directory
            mkdir(fullfile(dir, 'Excel'))
            % Recall the code the generate the spreadsheet
            xlswrite(fullfile(dir, 'Excel', [name '.xlsb']), output, sheetName)
        else
            % Rethrow the original exception as it is unknown
            rethrow(ex)
        end
    end
    
    % Try to make the mat file (this will overwrite the old data)
    try
        generateMatFile(rawData, dir, name);
    catch ex
        % If it failed because the directory doesn't exist, make it
        if strcmp(ex.identifier, 'MATLAB:save:couldNotWriteFile')
            % Make the directory
            mkdir(fullfile(dir, 'MatData'))
            % Retry to make the mat file
            generateMatFile(rawData, dir, name);
        else
            % Rethrow the original exception
            rethrow(ex)
        end
    end
    
end

function [output, data] = pullMinMaxData(obj, pdid, name)
%Subroutine to pull and format the raw data from the database
%   This will take the raw data from the database and place into a cell array
%   that can then be written to an excel spreadsheet
    
    % Generate the sql call
    % Define the colums to pull from the database
    parameters = '[datenum],[ECMRunTime],[DataMin],[DataMax],[CalibrationVersion],[TruckName],[Family],[ConditionID]';
    
    % Put the sql together
    sql = ['SELECT ' parameters ' '...
           'FROM [dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ' ...
           'ON [tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] '...
           'WHERE [PublicDataID] = ' sprintf('%.0f',pdid) ' And [EMBFlag] = 0 '...
           'ORDER BY [TruckName], [datenum]'];
    
    % Fetch the data from the database
    data = fetch(obj.conn, sql, 10000);
    
    % Generate the output cell array
    output = cell(length(data.datenum)+1,8);
    % Initalize the header row
    output(1,:) = {'Date and Time', 'ECM_Run_Time', 'Truck Name', 'Family', 'Software', 'Min/Max Set ID', [name '_Min'], [name '_Max']};
    
    % Format and write the colums of data to the cell array
    output(2:end,1) = cellstr(datestr(data.datenum, 'dd-mmm-yyyy HH:MM:SS.FFF'));
    output(2:end,2) = num2cell(data.ECMRunTime);
    output(2:end,3) = data.TruckName;
    output(2:end,4) = data.Family;
    output(2:end,5) = num2cell(data.CalibrationVersion);
    output(2:end,6) = num2cell(data.ConditionID);
    output(2:end,7) = num2cell(data.DataMin);
    output(2:end,8) = num2cell(data.DataMax);
    
end

function generateMatFile(rawData, dir, name)
%Take raw MinMax data and create a user-friendly .mat file output
%   
%   
    
    % Create the variables to save in the mat file
    eval([name '_Min = rawData.DataMin;']); % The minimum parameter values
    eval([name '_Max = rawData.DataMax;']); % The maximum parameter values
    abs_time = rawData.datenum;             % Absoulte time value in matlab datenum format
    ECM_Run_Time = rawData.ECMRunTime;      % Approximated ECM_Run_Time
    TruckName = rawData.TruckName;          % Name of the truck
    EngineFamily = rawData.Family;          % Engine family (X1, X2, X3, Black)
    Software = rawData.CalibrationVersion;  % Software version the truck was running
    MinMaxSetID = rawData.ConditionID;      % ID number of the MinMax data set this value came from
    
    % Save the data to a mat file
    save(fullfile(dir, 'MatData', [name '.mat']), [name '_Min'], [name '_Max'], 'abs_time', ...
         'ECM_Run_Time', 'TruckName', 'EngineFamily', 'Software', 'MinMaxSetID');
    
end
