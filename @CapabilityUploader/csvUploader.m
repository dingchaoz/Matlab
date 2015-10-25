function [filesP,timeP,filesE,timeE] = csvUploader(obj, rootDir, truckID)
%Upload directory of .csv files for a specified truck id number
%   This uses Calterm .csv files and assumes that the system time is in UTC which is how
%   the abs_time vertors are created
%   
%   Returns the number of files processed, errored on, and time for each
%   
%   Usage: [filesP,timeP,filesE,timeE] = csvUploader(obj, rootDir, truckID)
%   
%   Inputs - 
%   rootDir:  Root directory for the truck where data is stored
%   truckID:  ID number of the truck to be processed
%   
%   Outputs - 
%   filesP:   Total number of files successfully processed
%   timeP:    Total time spent processing successful files
%   filesE:   Total number of files processing failed
%   timeE:    Total time spent processing failed files
%   
%   Original Version - Chris Remington - January 10, 2014
%     - Integrated stand-alone code into the object
%   Revised - Chris Remington - Multiple
%     - Many changes in the middle
%   Revised - Chris Remington - February 21, 2014
%     - Added better error handling
%       > When an unknown function name is encounted, all processing is stopped
%       > When an unknown SEID / ExtID is encounted, all processing on that vehicle is
%         stopped, but other vehicles are allowed to continue
%       > In both of these cases, the file is not moved to the error folder
%   Revised - Chris Remington - March 12, 2014
%     - Added error handling for when the connection to the database is interrupted.
%       New behavior is for the automated process to stop and not move the files to the
%       error folder when it couldn't upload the data because the problem isn't with the
%       files
%   Revised - Chris Remington - April 29, 2014
%     - Added error handling for the case when a user trys to upload data but doesn't 
%       have parmissions to do so
%   Revised -Dingchao Zhang - 2015/10/25
%  Update fileID, cal ver, cal rev info in the tblprocessedfiles
    
    %% Initalization
    % Set the number of files processed and time to do it to zero to start
    filesP = 0;
    timeP = 0;
    filesE = 0;
    timeE = 0;
    
    %% Create a File List
    
    % Empty cell array to hold the file names to process
    fileList = {};
    % Get the directory information
    %dirData = dir(fullfile(rootDir, '*MinMax*.csv*'));
    dirData = dir(fullfile(rootDir, '*Max*.csv*'));
    % Look through each listing in the directory
    for i = 1:length(dirData)
        % If the listing wasn't a directory (or can add any other additional conditions)
        if ~dirData(i).isdir % && dirData(i).datenum > datenum(2014,1,1)
            % Add this file name to the processing list
            fileList = [fileList;{dirData(i).name}];
        end
    end
    % If there was no files found
    if isempty(fileList)
        % Exit the function
        return
    end
    
    % Set the directory to move processed files into
    moveToDir = fullfile(rootDir, 'processed');
    % Create that if it doesn't exist already
    if ~exist(moveToDir, 'dir');
        % Create it
        mkdir(moveToDir)
    end
    % Set the directory to move files that were errored-out
    errorDir = fullfile(rootDir, 'error');
    % Create that if it doesn't exist already
    if ~exist(errorDir, 'dir');
        % Create it
        mkdir(errorDir)
    end
    % Set the directory to move files that were duplicates
    duplicateDir = fullfile(rootDir, 'error', 'duplicates');
    % Create that if it doesn't exist already
    if ~exist(duplicateDir, 'dir');
        % Create it
        mkdir(duplicateDir)
    end
    
    %% Upload Files
    
    % Upload each csv file to the database
    for i = 1:length(fileList)
        % Set the full file path
        fullFilePath = fullfile(rootDir, fileList{i});
        time=tic;
        try
            % Check using the new way with the database table
            if CheckProcessedFile(obj, fileList{i}, truckID)
                error('CapabilityUploader:csvUploader:FileAlreadyProcessed','File:  %s\nTruck: %s\nThe specified file was already present in the processed folder for the specified truck.', fileList{i}, obj.getTruckName(truckID));
            end
            
            % Try to upload the file
            obj.AddCSVFile(fullFilePath, truckID);
            
            % Add this file id to the processed files table
            AddProcessedFile(obj, fileList{i}, truckID)
            
            % Move the file to a processed folder
            trymovefile(fullFilePath, fullfile(moveToDir, fileList{i}));
            
            % Log that this file completed successfully
            obj.event.write('Success!');
            % Incrememnt the files processed
            filesP = filesP + 1;
            % Add to the total processing time for this file
            timeP = timeP + toc(time);
        catch ex
            % If it was a "No Data In File" error, handle it separatly
            if strcmp(ex.identifier, 'CapabilityUploader:AddCSVFile:NoData')
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Move the file to the error directory
                trymovefile(fullFilePath, fullfile(errorDir, fileList{i}));
            % Elseif the file has already been processed before
            elseif strcmp(ex.identifier, 'CapabilityUploader:csvUploader:FileAlreadyProcessed')
                disp(['File was already present in the processed folder: ' fullFilePath]);
                %obj.warning.write('File was already present in the processed folder.');
                %obj.error.write('-----------------------------------------------------------');
                %obj.error.write(['File was already present in the processed folder: ' fullFilePath]);
                %obj.error.write(getReport(ex));
                obj.event.write('Duplicated file, skipping and moving to duplicates folder.');
                obj.event.write(getReport(ex));
                % Move the file to a separate folder to denote duplicates
                trymovefile(fullFilePath, fullfile(duplicateDir, fileList{i}));
            elseif strcmp(ex.identifier, 'CapabilityUploader:AddCSVFile:ParameterMissing')
                disp(['Missing parameters on file: ' fullFilePath]);
                obj.warning.write('File was missing some required parameters.');
                %obj.error.write('-----------------------------------------------------------');
                obj.error.write(['File was missing some required parameters: ' fullFilePath]);
                %obj.error.write(getReport(ex));
                obj.event.write(['File was missing some required parameters: ' fullFilePath]);
                obj.event.write(getReport(ex));
                % Move the file to a separate folder to denote duplicates
                trymovefile(fullFilePath, fullfile(errorDir, fileList{i}));
            % Elseif there was a java exception (saw this once where the connection
            % somehow got closed, this error should stop everything)
            elseif strncmp(getReport(ex), 'Java exception occurred:', 24)
                % Throw a fit, stop working on this truck
                disp(['Java error on file ' fullFilePath]);
                disp(getReport(ex));
                % Write to the logs, etc.
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Java error on file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.error.write('======> Stopping all data proccessing now.');
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Throw an error to stop execution
                error('csvUploader:JavaError', ...
                      'A java error occured, stopping all data processing now.');
            % Somehow I found a different failure error when I manually close the connection
            % to the connection from SQL Server Management Studio
            elseif ~isempty(strfind(getReport(ex),'Invalid or closed connection')) || ~isempty(strfind(getReport(ex),'Connection reset by peer: socket write error'))
                % Throw a fit, stop working on this truck
                disp(['Connection error while processing file ' fullFilePath]);
                disp(getReport(ex));
                % Write to the logs, etc.
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Connection error while processing file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.error.write('======> Stopping all data proccessing now.');
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Throw an error to stop execution
                error('csvUploader:ConnectionError', ...
                      'A connection error occured, stopping all data processing now.');
            % Add a check for when the evdd info isn't present, skip the rest of the files
            elseif strcmp(ex.identifier, 'CapabilityUploader:AddCSVFile:EVDDInfoMissing')
                % Show a message and the exact error
                disp('Missing Event Driven data decoding information, skipping the rest of the files for this vehicle.')
                disp(ex.getReport)
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Error on file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.error.write(sprintf('======> Stopping all data proccessing on %s.',obj.getTruckName(truckID)));
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Break out of the loop of .csv files for this unit
                break
            % Added this so that in the case a user is missing a function that is required to 
            % process data all files don't end up in the error folder even though they
            % may have been fine
            elseif strncmp(ex.message, 'Undefined function ',19)
                % Report and log the error
                disp(ex.getReport)
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Error on file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.error.write('======> Stopping all data proccessing now.');
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Kill data processing, don't move anything anywhere
                rethrow(ex)
            % The user doesn't have permission to either SELECT, UPDATE, or INSERT data
            elseif strcmp(ex.identifier,'database:database:cursorError') && any(strfind('permission was denied',ex.message))
                % Report and log the error
                disp(ex.getReport)
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Error on file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.error.write('======> Stopping all data proccessing now.');
                obj.event.write('Failure! User doesn''t have the right permissions.');
                obj.event.write(getReport(ex));
                % Kill data processing, don't move anything anywhere
                rethrow(ex)
            else % otherwise, treat it like an unknown failure
                % Report and log an error, then move on to the next file
                disp(['Error on file ' fullFilePath]);
                disp(ex.getReport)
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Error on file ' fullFilePath]);
                obj.error.write(getReport(ex));
                obj.event.write('Failure!');
                obj.event.write(getReport(ex));
                % Move the file to the error directory
                trymovefile(fullFilePath, fullfile(errorDir, fileList{i}));
            end
            % Increment the number of files errored
            filesE = filesE + 1;
            % Incrememnt the time that this file took
            timeE = timeE + toc(time);
        end
        toc(time);
    end
    % Done
    disp([num2str(i) ' files processed']);
    obj.event.write([num2str(i) ' files processed']);
end

function AddProcessedFile(obj, file, truckID)
%Add a file name to the processed files table
    try
        % Insert this file into the processed files table in the database
        fastinsert(obj.conn, 'tblProcessedFiles', {'TruckID','FileName','CalVersion','CalRev'}, {truckID,file,obj.FileID,obj.CalVer,obj.CalRev})
    catch ex
        % If this was a unique key violation
        if strncmp(['Java exception occurred: ' char(10) 'java.sql.BatchUpdateException: Violation of UNIQUE KEY constraint'],ex.message,91)
            % Then this file was already processed for this truck
            % You really should never be able to get this error was there should be a
            % check for the existance of this file before a call to this function
            error('csvUploader:AddProcessedFile:AlreadyPresent','Tried to add the file %s to the [tblProcessedFile] table for truck id %.0f but it was already present in the database.',file,truckID)
        else
            % Rethrow the original exception as it is unknown
            rethrow(ex)
        end
    end
    
end

function present = CheckProcessedFile(obj, file, truckID)
%Check is a file name is listed as already having been processed
    try
        % Look for this file in the database alreadyfetch(obj.conn, sprintf('SELECT [FileName],[TruckID] FROM [dbo].[tblProcessedFiles] WHERE [FileName] = ''%s'' And [TruckID] = %.0f',file,truckID));
        data = 1;
        % If there was no data returned
        if isempty(data)
            % Return false as the file has not been processed yet
            present = false;
        else
            % Return true as the file was already processed
            present = true;
        end
    catch ex
        % Unknown error, rethrow exception for now
        rethrow(ex)
    end
end

function trymovefile(source, destination)
%Use only when it's ok if there was an error and the file didn't actually get moved
%   For files that were already processed, they should have already been added to the
%     processed files table
%   For files with an error in the data, they will just have an error again the next time
%     and hopefully will be able to be move because Matlab released the file lock for the
%     next session
%   
    try
        % Try to move the file
        movefile(source, destination);
    catch ex
        % If moving the file failed (sometimes matlab doesn't close it fast enough
        % or close it at all after reading it)
        if strcmp('MATLAB:MOVEFILE:OSError',ex.identifier)
            % Do nothing because it was already added to the procedded files table
            % so it won't be processed again
        else
            % Rethrow the original exception as it is an unknow error
            rethrow(ex)
        end
    end
end
