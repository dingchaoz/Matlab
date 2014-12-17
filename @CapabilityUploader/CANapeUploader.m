function CANapeUploader(obj)
%Processes CANape raw .csv files and uploads data to database for program object is connected to
%   This function will read in the raw .csv files from the network, process and decode the
%   data contained in them, and upload the results into the program database.
%   
%   Usage:CANapeUploader(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Dingchao Zhang - Dec 5, 2014

    
    %% Initalize
    filesPt = 0;
    timePt = 0;
    filesEt = 0;
    timeEt = 0;
    
    %% Automated File Finder and Mover
    totalStart = tic;
    
    % Calculate the root directory of the data
    if strcmp(obj.program,'HDPacific')
        % Override HDPacific to be the Pacific folder
        startDir = '\\CIDCSDFS01\US.COL.IOB\Users\ks692\CANape_trucks\HDPacific';
    else
        % Use the program name for all the rest
        startDir = ['\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\' obj.program];
    end
    
    % Blank array for folder to work on
    truckList = {};
    % Look for all truck folders that exist
    truckDirData = dir(startDir);
    % For each listing in the directory
    for i = 3:length(truckDirData)
        % If this was a folder (not a file inappropriatly placed in the wrong directory)
        if truckDirData(i).isdir
            % Append this onto the truckList
            truckList = [truckList;{truckDirData(i).name}];
        end
    end
    
    % For each truck that has data
    for i = 1:length(truckList)
        % Try to get the truck ID of this truck
        try
            truckID = obj.getTruckID(truckList{i});
        catch ex
            if strcmp('Capability:getTruckID:NoMatch',ex.identifier)
                % Add this truck name to the tblTrucks table
                truckID = obj.addTruck(truckList{i});
                
                % Log that this truck name was added to the table
                obj.error.write('-----------------------------------------------------------');
                obj.error.write(['Added entry to trucks table for vehicle ' truckList{i} '.']);
            else
                % Rethrow the original, unknown exception
                rethrow(ex)
            end
        end
        
        % Check if data should be processed for this truck
        if ~obj.getTruckProcessData(truckID)
            % Write a warning log entry
            obj.warning.write(sprintf('==========> Data processing on truck %s is being skipped.',truckList{i}));
            % Continue on to the next vehicle
            continue
        end
        
        % Assign the workingDir
        workingDir = fullfile(startDir, truckList{i});
        % Start the clock ticking
        startTime = tic;
        % Call csvUploader to process and move all files for this truck
        [filesP,timeP,filesE,timeE] = obj.CANapecsvUploader(workingDir, truckID);
        % Log the running time for this truck
        toc(startTime);
        obj.event.write(['Elapsed time is ' num2str(toc(startTime)) ' seconds.']);
        
        % Log this trucks progress
        % Header = {'Truck Name,Successful Files,Time,Time/File,Failed Files,Time,Time/File,Total Files,Total Time,Time/File'};
        obj.timer.write(sprintf('%s,%.0f,%.2f,%.2f,%.0f,%.2f,%.2f,%.0f,%.2f,%.2f', ...
            truckList{i},filesP,timeP,timeP/filesP,filesE,timeE,timeE/filesE, ...
            filesP+filesE,timeP+timeE,(timeP+timeE)/(filesP+filesE)));
        
        %% Track Total Process Progress and Time
        % Capture the total number of files processed
        filesPt = filesPt + filesP;
        timePt = timePt + timeP;
        filesEt = filesEt + filesE;
        timeEt = timeEt + filesE;
    end
    
    disp('Total Ending time');
    toc(totalStart);
    
    % Write the time results to the log file
    obj.timer.write('-------------------------------------------------------------------------------------------');
    obj.timer.write(sprintf('Successfully Processed:   %4.0f files in %5.1f seconds = %.2f seconds per file.',filesPt,timePt,timePt/filesPt));
    obj.timer.write(sprintf('Unsuccessfully Processed: %4.0f files in %5.1f seconds = %.2f seconds per file.',filesEt,timeEt,timeEt/filesEt));
    obj.timer.write(sprintf('Total Files Processed:    %4.0f files in %5.1f seconds = %.2f seconds per file.',filesPt+filesEt,timePt+timeEt,(timePt+timeEt)/(filesPt+timeEt)));
    
    %% Call sqlcmd
    % Split current directory into parts
    %fileParts = toklin(pwd,'\');
    % Calculate full path to the .sql file
    %sqlFilePath = fullfile(fileParts{1:end-1},'suppdata',obj.program,[obj.program '_FixData.sql']);
    % New location on the network
    sqlFilePath = fullfile('\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\Storage\suppdata',obj.program,[obj.program '_FixData.sql']);
    % Check that the file exists
    if exist(sqlFilePath,'file')
        % Display that the sql script is being called
        disp(['Running ' obj.program '_FixData.sql....'])
        % Execute the [program]_FixData.sql commands after new data has been uploaded to the database
        dos(sprintf('sqlcmd -S tcp:%s\\%s -E -i \"%s\"',obj.server,obj.instanceName,sqlFilePath))
    else
        % Warn that this couldn't be run
        disp('Failed to run the data cleaning .sql script')
        % Log the error
        obj.error.write('-----------------------------------------------------------');
        obj.error.write('Failed to find the FixData.sql file')
    end
end
