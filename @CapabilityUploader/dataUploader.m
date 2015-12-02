function dataUploader(obj)
%Processes raw .csv files and uploads data to database for program object is connected to
%   This function will read in the raw .csv files from the network, process and decode the
%   data contained in them, and upload the results into the program database.
%   
%   Usage: dataUploader(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - January 10, 2014
%     - Integrated stand-alone code into the object
%   Revised - Chris Remington - April 4, 2014
%     - Corrected a problem in the logic that looks for truck folder names to process
%   Revised - Yiyuan Chen - 2015/02/04
%     - Added the feature of processing & uploading the number of failed cyclinders for EFI diagnostics 
%     by creating a new parameter with a fake PublicDataID 
    
    %% Initalize
    filesPt = 0;
    timePt = 0;
    filesEt = 0;
    timeEt = 0;

    %% Fetch the maximum conditionID for EFI to process and upload new data only
    if ismember(obj.program,{'DragonCC','DragonMR','Seahawk'})
        % Pick the biggest ConditionID in MinMax Data table before uploading new EFI data 
        % so that only the EFI data uploaded this time will be processed, as below 
        EFImaxConditionID = cell2mat(struct2cell(fetch(obj.conn, 'SELECT Max(ConditionID) FROM dbo.tblMinMaxData')));
    else
    end
    
    %% Automated File Finder and Mover
    totalStart = tic;
    
    % Calculate the root directory of the data
    if strcmp(obj.program,'HDPacific')
        % Override HDPacific to be the Pacific folder
        startDir = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\Pacific';
%     elseif strcmp(obj.program,'Acadia')
%         % Testing new csv upload script to add cal ver and rev status
%         startDir = '\\CIDCSDFS01\US.COL.IOB\Users\ks692\OBD Analysis\Improvement\tblCalsImprovement\Acadia';
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
        [filesP,timeP,filesE,timeE] = obj.csvUploader(workingDir, truckID);
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
    
    %% Process new EFI data separately and upload
    if ismember(obj.program,{'DragonCC','DragonMR','Seahawk'})
        selectwhere = sprintf('WHERE PublicDataID in (93322,93323,93324,93325,93326,93327) AND ConditionID > %d', EFImaxConditionID);
        updatewhere = sprintf('WHERE DataMax >= %.3f OR DataMin <= %.3f', obj.cals.Default.C_FED_q_EFIHighLimit, obj.cals.Default.C_FED_q_EFILowLimit);
        % Select the data of 6 cylinders newly uploaded and flag them if they fail, by adding a column to the temp table created
        addtblEFI = ['SELECT * INTO dbo.tblEFI FROM dbo.tblMinMaxData ' selectwhere ' ORDER BY datenum DESC, PublicDataID ASC; '...
            'ALTER TABLE dbo.tblEFI ADD DataEFI SMALLINT NOT NULL default 0; '...
            'UPDATE dbo.tblEFI SET DataEFI = 1' updatewhere ';'];
%         update(obj.conn, 'tblEFI', {'DataEFI'}, 1, sprintf('WHERE DataMax >= %.3f OR DataMin <= %.3f ', obj.cals.Default.C_FED_q_EFIHighLimit, obj.cals.Default.C_FED_q_EFILowLimit));
        % Count the number of failures for the 6 cyclinders in the same key cycle by adding their failure flags, which is saved as DataMax
        % while updating DataMin to 0 & the fake PublicDataID to 999999, in another temp table 
        addtblEFIcnt = ['SELECT DISTINCT a.datenum, a.ECMRunTime, a.PublicdataID, a.DataMin, a.DataEFI+b.DataEFI+c.DataEFI+d.DataEFI+e.DataEFI+f.DataEFI AS DataMax, a.CalibrationVersion, a.TruckID, a.ConditionID, a.EMBFlag, a.TripFlag '...
            'INTO dbo.tblEFIcnt FROM dbo.tblEFI a, dbo.tblEFI b, dbo.tblEFI c, dbo.tblEFI d, dbo.tblEFI e, dbo.tblEFI f '...
            'WHERE a.PublicDataID=93322 AND b.PublicDataID=93323 AND c.PublicDataID=93324 AND d.PublicDataID=93325 AND e.PublicDataID=93326 AND f.PublicDataID=93327 '...
            'AND a.conditionID=b.ConditionID AND a.conditionID=c.ConditionID AND a.conditionID=d.ConditionID AND a.conditionID=e.ConditionID AND a.conditionID=f.ConditionID ORDER BY datenum DESC; '...
            'UPDATE dbo.tblEFIcnt SET PublicDataID=999999, DataMin=0;'];
        % Insert the data of number of failures to MinMax Data table & delete the 2 temp tables
        insertEFIcnt = 'INSERT INTO dbo.tblMinMaxData SELECT * FROM dbo.tblEFIcnt;';
        deletetbl= 'DROP TABLE dbo.tblEFI; DROP TABLE dbo.tblEFIcnt';
        % Form the entire SQL query for EFI diagnostics
        sqlEFI=[addtblEFI char(13,10)' addtblEFIcnt char(13,10)' insertEFIcnt char(13,10)' deletetbl];
        % Set the property of ErrorHandling in database preference to 'store' instead of 'report' before executing the SQL query
        % to avoid reporting the no results returned error generated by 'SELECT INTO' in cursor.m, while the query can actually be executed 
        setdbprefs('ErrorHandling','store')
        exec(obj.conn, sqlEFI);
    else
    end
    
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
