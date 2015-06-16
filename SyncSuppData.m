function SyncSuppData(varargin)
%Update all supporting files into the database
%   Automatically update and upload errtable.xml files to the correct IUPR
%   databases in one shot, and check the number of rows against the
%   error_table file if it is in the same directory
%   
%   Original Version - Chris Remington - January 20, 2014
%   Revised - Yiyuan Chen - 2015/06/09
%       - Modified to skip an error and move to the next upload
    
    % Define the staring data folder
    %rootDir = 'D:\Matlab\NewIUPR_DB\data';
    rootDir = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\Storage\suppdata';
%     rootDir = 'D:\Users\kz429\data crunching\GUI code\suppdata';
    
    % If the user didn't pass in any programs
    if nargin < 1
        % Get the folder listings present
        dirData = dir(rootDir);
        programs = {dirData(cell2mat({dirData(:).isdir})).name}';
        programs = programs(3:end);
    else
        % Use what the user passed in
        programs = varargin;
    end
    
    % For each engine program
    for i = 2:length(programs)
        
        try
            % Open the connections to the right databases
            capdb = Capability(programs{i});
        catch ex
            % Failure connecting, show a message
            fprintf('Skipping processing on %s because there was an error connecting to the database\r',programs{i});
            % Show the raw error
            disp(ex.getReport)
            % Skip this engine program
            continue
        end
        
        % Look for the software versions present
        swDir = fullfile(rootDir,programs{i},'swinfo');
        swDirList = dir(swDir);
        swVers = {swDirList(cell2mat({swDirList(:).isdir})).name}';
        
        % Loop through each software version
        for j = 3:length(swVers)
            try
                %% errtable.xml
                % Full path to where the error_table file should be
                errorTableFile = fullfile(swDir,swVers{j},'error_table');
                % Check if there is an error_table present to compare with the errtable.xml
                if exist(errorTableFile,'file')
                    try
                        % Get the number of rows
                        errorTableRows = GetErrorTableRows(errorTableFile);
                    catch ex
                        disp('!!!!!!!!! Failed to properly read in the error_table file.')
                        disp(ex.getReport);
                    end
                else
                    % Set the rows to NaN
                    errorTableRows = NaN;
                end
                
                % Is there already data present for this software version
                data = fetch(capdb.conn, sprintf('SELECT COUNT([Error_Table_ID]) As DataPts FROM [dbo].[tblErrTable] WHERE [SoftwareVersion] = %s',swVers{j}));
                
                % If the result was zero data points present
                if data.DataPts == 0
                    % Calculate the file name
                    fileName = fullfile(swDir,swVers{j},'errtable.xml');
                    % If the errtable.xml file is present
                    if exist(fileName,'file')
                        % Display a message the data is going to be uploaded
                        fprintf('Software version %s - Adding errtable.xml to %s database.\r',swVers{j},programs{i});
                        % Upload the errtable.xml file
                        capdb.addErrTable(fileName,str2double(swVers{j}))
                    else
                        % Display a warning that the file wasn't found
                        fprintf('errtable.xml file %s wasn''t found, skipping this software upload.\r',fileName)
                        % Skip the rest of the checks
                        %continue
                    end
                    
                    % Count the number of records added
                    data = fetch(capdb.conn, sprintf('SELECT COUNT([Error_Table_ID]) As DataPts FROM [dbo].[tblErrTable] WHERE [SoftwareVersion] = %s',swVers{j}));
                    
                else
                    % Display a message
                    fprintf('Software version %s - errtable.xml already in %s database - %.0f records are present.\r',swVers{j},programs{i},data.DataPts);
                end
                
                if isnan(errorTableRows)
                    % Say that it was missing
                    disp('error_table wasn''t found for this software.');
                elseif errorTableRows~=data.DataPts
                    % Note that they don't match
                    disp('========>!!! errtable.xml and error_table do NOT match length.')
                else
                    % They match length
                    %disp('errtable.xml and error_table match length.')
                end
                
                %% datainbuild.csv
                
                % Is there already data present for this software version
                data2 = fetch(capdb.conn, sprintf('SELECT COUNT([Data]) As DataPts FROM [dbo].[tblDataInBuild] WHERE [Calibration] = %s',swVers{j}));
                
                % If the result was zero data points present
                if data2.DataPts == 0
                    % Calculate the file name
                    fileName2 = fullfile(swDir,swVers{j},'datainbuild.csv');
                    % If the errtable.xml file is present
                    if exist(fileName2,'file')
                        % Display a message the data is going to be uploaded
                        fprintf('Software version %s - Adding datainbuld.csv to %s database.\r',swVers{j},programs{i});
                        % Upload the errtable.xml file
                        capdb.addDataInBuild(fileName2,str2double(swVers{j}))
                    else
                        % Display a warning that the file wasn't found
                        fprintf('datainbuild.csv file %s wasn''t found, skipping this software upload.\r',fileName2)
                        % Skip the rest of the checks
                        %continue
                    end
                    
                    % Count the number of records added
                    %data2 = fetch(capdb.conn, sprintf('SELECT COUNT([Data]) As DataPts FROM [dbo].[tblDataInBuild] WHERE [Calibration] = %s',swVers{j}));
                    
                else
                    % Display a message
                    fprintf('Software version %s - datainbuild.csv already in %s database - %.0f records are present.\r',swVers{j},programs{i},data2.DataPts);
                end
                
            catch ME
                disp(' ')
                disp(ME.message)
                disp(' ')
                continue
            end
            
        end % software version
        
        try
            %% evdd.xlsx For Each Program
            % Upload the newest event driven decoding information
            fprintf('Uploading evdd info...\r')
            % Calculate the name of the evdd file
            evddFile = fullfile(rootDir,programs{i},[programs{i} '_evdd.xlsx']);
            % Upload the information to the database
            capdb.uploadEvdd(evddFile);
            %% Processing Information
            % Upload the newest plot and processing information
            fprintf('Uploading processing info...\r')
            % Calculate the name of the processing info file
            processingFile = fullfile(rootDir,programs{i},[programs{i} '_Processing Information.xlsx']);
            % Upload the informtaion to the database
            capdb.uploadProcessingInfo(processingFile);
            
        catch ex
            % Show the error message and let the code move on
            disp(ex.getReport)
        end
        
    end % program
    
end % function

function recordsAdded = GetErrorTableRows(fileName)
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
%   Hacked - Chris Remington - October 14, 2013
%     - Modified to just return the number of system errors in the build
    
    %% Read in the raw data file
    % Keep track of time
    %tic
    %disp('Starting file read')
    
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
    %formatted(:,end-1) = {cal};
    % Add the System Error Number (Index + 1) to each line
    formatted(:,end) = num2cell(1:length(data{i}))';
    % Print elapsed time
    %toc
    
    % Pluch out the row count
    recordsAdded = size(formatted,1);
    
end
