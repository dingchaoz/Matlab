function CANapeAddCSVFile(obj, fullFileName, truckID)
%This will parse an CANape csv file and populate the data into the database.
%   This function is designed to read in a .csv file from the MinMax
%   screen on a HD datalogger and parse out the data. It will decode the
%   Event Driven data, connect it with PC_Timestamp and ECM_Run_Time, and
%   add it to the database. It will also look for sets of MinMax data,
%   attempt to use the first few header parameters of the MinMax data (if
%   present) to calculate various "MinMax Data Conditions" of that set,
%   compare both broadcast values to ensure the Min and Max are noted
%   correctly, and add all the given data to the database.
%   
%   Inputs---
%   fillFilePath: Path to the csv file to load into the database
%   truckID:      truckID to assosiate with the data put in the database
%   
%   Outputs---    None
%   
%   Original Version - Dingchao Zhang - Dec 5, 2014

    %% Prerequisite Code
    % Get the name of the truckID to ensure that its a valid truck
    % This will throw an error if an invalid truckID is specified
    truckName = obj.getTruckName(truckID);
    obj.event.write('-----------------------------------------------------------');
    obj.event.write(['Truck - ' truckName]);
    obj.event.write(['File  - ' fullFileName]);
    obj.warning.write(['File  - ' fullFileName]);
    
  
%     %% Correct for capitolization errors in the "_Calibration_Version" parameter
%     if exist('i_calibration_version','var')
%         % Set it to the standard spelling
%         i_Calibration_Version = i_calibration_version;
%     elseif exist('i_calibration_Version','var')
%         % Set it to the standard spelling
%         i_Calibration_Version = i_calibration_Version;
%     elseif exist('i_Calibration_version','var')
%         % Set it to the standard spelling
%         i_Calibration_Version = i_Calibration_version;
%     end
%     
  
%     %% Calibration Checker
%     % If this log file has an updated calibration version
%     if exist('i_Calibration_Version','var')
%         % Convert it to a number
%         cal = obj.dot2num(i_Calibration_Version{1});
%         % This new number will be updated below
%         % If the cal version couldn't be interpreted as a number
%         if isnan(cal)
%             % Throw an error on this condition
%             error('CapabilityUploader:AddCSVFile:InvaildSoftwareVer', ...
%                   'The software version specified in the .csv file was %s and couldn''t be interpreted into numerical format.', i_Calibration_Version{1});
%         end
%     else
%         % Need to pull out the software version currenty stored in the cache
%         cal = obj.getLastSoftware(truckID);
%         % If getLastSoftware returned a nan, meaning that it wasn't in the cache
%         if isnan(cal)
%             % Throw an error to halt execution
%             error('CapabilityUploader:AddCSVFile:CalibrationMissingInHeader', ...
%                 'i_Calibration_Version is not in the header of the file and has no cached version.');
%         end
%     end
    
%     % If this log file has an updated calibration revision number
%     if ~exist('Calibration_Revision_Number','var')
%         % Try to get a the last revision number from the database
%         Calibration_Revision_Number = obj.getLastCalRev(truckID);
%         % If this is a NaN (never assigned in the database), ignore it becuase 
%         % calibration revision number isn't crucial to be able to add the data 
%         % to the database currently
%         if isnan(Calibration_Revision_Number)
%         end
%     end
%     
%     % If this log file has an updated ECM Code
%     if exist('i_ECM_Code','var')
%         % Saw a case of an Atlantic _ECM_Code that was 1103620.04 and was a double
%         if isnumeric(i_ECM_Code)
%             % Convert the number to a string
%             i_ECM_Code = sprintf('%.2f',i_ECM_Code);
%         else
%             % Pull the string out of the cell
%             i_ECM_Code = i_ECM_Code{1};
%         end
%     else
%         % Try to get a the last revision number from the database
%         i_ECM_Code = obj.getLastECMCode(truckID);
%         % If this is a NaN (never assigned in the database), ignore it becuase 
%         % calibration revision number isn't crucial to be able to add the data 
%         % to the database currently
%         if strcmp('null',i_ECM_Code)
%         end
%     end
    
    %% Calterm and Logger Configuration Manager Update
    % Get the ETDVersion from the file name
    pathParts = toklin(fullFileName, '\');
    % Get the file parts of the file name
    fileParts = toklin(pathParts{end},'_');
    % Take the first one as this will be the ETDVersion
    ETDVersion = fileParts{1};
    % Capture the Filedate from the filename string to mark the newest data point processed
    Pdate = [fileParts(4:8),strtok(fileParts(9),'.')];
    Fdate = datestr([str2num(Pdate{1}),str2num(Pdate{2}),str2num(Pdate{3}),str2num(Pdate{4}),str2num(Pdate{5}),str2num(Pdate{6})]);
    LastFileDatenum = datenum(Fdate);
    
    % Import CANape CSV file
    data_Array = CANape_import(fullFileName, 3);  
    ts = data_Array{:, 1};
    Key_Switch = data_Array{:, 2};
    ECM_Run_Time = data_Array{:, 3};
    systime = data_Array{:, 4};
    EventDriven_Data = data_Array{:, 5};
    ExtID = data_Array{:, 6};
    SEID = data_Array{:, 7};
    Min_Max_Data = data_Array{:, 8};
    Min_Max_PublicDataID = data_Array{:, 9};
    MMM_Update_Rate = data_Array{:, 10};
    cal_ver = data_Array{:, 11};
    
    
%     If MMM_Update_Rate is logged in the file
    if exist('MMM_Update_Rate')
%         % Denan it
%         MMMRate = nonan(MMM_Update_Rate);
%         % If the values aren't all zero (i.e., MMM logger is turned on)
%         if length(MMMRate) < 1
%             MMMOverlay = 'Empty';
%         elseif mean(MMMRate) > 0
            % Set the indicator to Yes
            MMMOverlay = 'Yes';
%         else
%             % Set the indicator to No
%             MMMOverlay = 'No';
%         end
%     else
%         % Note that the MMM_Update_Parameter isn't logged
%         MMMOverlay = 'Not Logged';
    end
    % Get the size of the file being processed
    dirData = dir(fullFileName);
    fileSize = sprintf('%.0f KB',dirData(1).bytes/1024);
    
    % Get the cal information
%     for i = 1 : length(cal_ver)
%         if ~isempty(cal_ver{i}) && isnumeric(cal_ver{i})
%             cal = cal_ver{i};
%         
%             warning('No calibration version information');
%             
%         end
%         break;
%     end

   cal = str2double(cal_ver{10});
%    i = 2;
%    while isempty(cal)
%        i = i + 1;
%        cal = cal_ver(i);
%        if ~isempty(cal);
%            break;
%        end
%    end
    % Manually assign the Nan values temporarily
    Calibration_Revision_Number = [];
    i_ECM_Code = [];
    CaltermVersion  = [];
    InitialMonitorRate  = [];
    ScreenMonitorType  = [];
    LogMode  = [];
    
    % Update the informational columns for this truck in the tbiTrucks table
    update(obj.conn, 'tblTrucks', ...
        {'SoftwareCache','RevisionCache',             'ECMCode',  'LastFileDatenum','LastFileDateTime',         'ETDVersion','CaltermVersion','InitialMonitorRate','ScreenMonitorType','LogMode', 'MMMTurnedOn', 'LastFileSize'}, ...
        {cal,             Calibration_Revision_Number, i_ECM_Code, LastFileDatenum, datestr(LastFileDatenum,31), ETDVersion,  CaltermVersion,  InitialMonitorRate,  ScreenMonitorType,  LogMode,   MMMOverlay,    fileSize},...
        sprintf('WHERE [TruckID] = %0.f',truckID));
    
    %% Check Variable Existance and if empty
    % Check for the variable we know we need, throw a custom error if they don't exist
    
    % Check for EventDrivenDataValue
    if isempty('ECM_Run_Time')
        warning('CapabilityUploader:AddCSVFile:Emptyvalue',...
            'ECM_Run_Time is empty.')
        
    % Check for ExtID
    elseif isempty('ExtID')
        warning('CapabilityUploader:AddCSVFile:Emptyvalue',...
            'ExtID is empty.')
        
    % Check for SystemErrorID
    elseif isempty('SEID')
        warning('CapabilityUploader:AddCSVFile:Emptyvalue',...
            'SEID is empty.')
        
    % Check for MinMax_DataValue
    elseif isempty('Min_Max_Data')
        warning('CapabilityUploader:AddCSVFile:Emptyvalue',...
            'Min_Max_Data is empty.')
        
       % Check for PublicDataID
    elseif isempty('Min_Max_PublicDataID')
        warning('CapabilityUploader:AddCSVFile:Emptyvalue',...
            'Min_Max_PublicDataID is empty.')
        
    % Check for ECM_Run_Time
    elseif isempty('EventDriven_Data')
        warning('CapabilityUploader:AddCSVFile:EventDriven_Data',...
            'EventDriven_Data is empty.')
    end
    
    %% Interpolate the ECM_Run_Time
    try
        % Create the interpolated version of ECM_Run_Time
        ECM_Run_Time_interp = interpECMRunTime(ECM_Run_Time);
    catch ex
        if strcmp(ex.identifier, 'CapabilityUploader:AddCSVFile:interpECMRunTime:failToLocateStartingECMRunTime');
            % Instead of keeping the error, just set all ECM_Run_Time values to a NaN so they
            % get uploaded into the database as a null. Then, we at least get to keep the data
            % in one form, all be it with less meta-data.
            ECM_Run_Time_interp = zeros(size(ECM_Run_Time));
            ECM_Run_Time_interp(:) = NaN;
            % Journal this in the warning log
            obj.warning.write('Dropped ECM_Run_Time from the event driven data - There were 100 lines without an update at the start of the file.');
        else
            % Rethrow the original error
            rethrow(ex);
        end
    end
    
    %% Initalize Outputs
    % Initialize an output variable to dump values into.
    numRecord = sum(~strcmp('NaN', SEID)&~strcmp('NaN', EventDriven_Data));
    % This is what will get loaded into the database
    % 9 columns of data and as many rows as have data
    eventDecoded = cell(numRecord, 9);
    % Initalize the logical array to hold whether each line is excess data or not
    excessDataFlag(1:numRecord,1) = false;
    % Start a counter for the number of blank lines in the file (all values are a NaN)
    blankLines = 0; % this should be 1 to 5 for normal files
    
    % Initalize the write index for the above vector
    writeIdxEvent = 1;
    
    %% Loop through data
    % Loop through the entire .csv file, make sense of the data
    for i = 1:length(SEID)
%         
%         % Look for an updated ECM_Run_Time
%         if ~isnan(ECM_Run_Time(i))
%             % If there was also EventDriven data on this line
%             if ~strcmp(EventDriven_Data{i}, 'NaN') || ~strcmp(MinMax_Data{i}, 'NaN')
%                 % Write a line to the error log
%                 obj.warning.write('CapabilityUploader:AddCSVFile:MultipleDataOnOneLine - Both ECM_Run_Time and Event Driven or MinMax data found on the same line. - This is advisory');
%                 obj.event.write('CapabilityUploader:AddCSVFile:MultipleDataOnOneLine - Both ECM_Run_Time and Event Driven or MinMax data found on the same line. - This is advisory');
%             end
%             
%         elseif ~strcmp(EventDriven_Data{i}, 'NaN')
            % Event Driven Data
            % There is event driven data on this line without ECM_Run_Time
            
            % Flag whether or not this data point was excess event driven data or not
            % and skip it
            % If this was from dpf filt eff (se 4758) on old s/w for Pacific, skip it too
%             if isExcessEvent(obj,SEID) || (SEID==4758&&cal<710007&&strcmp('HDPacific',obj.program))
%                 % Set the flag for this line to true
%                 excessDataFlag(writeIdxEvent) = true;
%                 % Don't decode this data
%                 % Incrememnt the writeIdxEvent
%                 writeIdxEvent = writeIdxEvent + 1;
%                 
%                 % Should somehow note that excess event data was present and ignored
%                 % Maybe a way to track the system errors that are active
%                 
%                 % Continue to the next loop itaration
%                 continue
%             end

            
            % Try to find a match for this xSEID
%             try
                % Send this data into the decoder
             if ~isempty(EventDriven_Data{i})
                decodedData = obj.decodeCANapeEvent(str2double(SEID{i}) + str2double(ExtID{i})*65536, str2double(EventDriven_Data{i}));
%             catch ex
%                 % Failed to locate decoding information for this xSEID
%                 error('CapabilityUploader:AddCSVFile:EVDDInfoMissing', 'Failed to locate decoding information for SEID %0.f with ExtID %0.f = xSEID of %0.f with software %.0f',SEID,ExtID,SEID + ExtID*65536,cal);
%             end
            
            % Add the info to a new line of the eventDecoded cell array
            % colNames = {datenum, ECMRunTime, SEID, ExtID, DataValue, CalibrationVersion, TruckID, EMBFlag, TripFlag}
                eventDecoded(writeIdxEvent,:) = {LastFileDatenum, ECM_Run_Time_interp(i), str2double(SEID{i}), str2double(ExtID{i}), decodedData, cal, truckID, 0, 0};
            
            % Increment the writeIdxEvent
                writeIdxEvent = writeIdxEvent + 1;
             end
%         elseif ~strcmp(MinMax_Data{i}, 'NaN')
%             % MinMax line, ignore
%         else
%             %% No Data on Line, note Datalink Dropout
%             % There was a datalink dropout in the middle of the file or
%             % the end of the file
%             %obj.warning.write(['CapabilityUploader:AddCSVFile - Datalink dropout on line ' num2str(i) ' for file ' fullFileName]);
%             % Comment this out, some file have thousands of blank lines making the log
%             % files huge
%             %obj.event.write(['CapabilityUploader:AddCSVFile - Datalink dropout on line ' num2str(i) ' for file ' fullFileName]);
%             % Instead sum the number of blank line, then write one event log with that
%             % Add to the summation the number of blank lines
%             blankLines = blankLines + 1;
%         end
        
    end
    
    % Log the number of blank lines in the event log
    obj.event.write(sprintf('CapabilityUploader:AddCSVFile - There were %.0f blank lines in file %s',blankLines,fullFileName));
    % Update this value in the database
    update(obj.conn, 'tblTrucks', {'BlankLines'}, {blankLines}, ...
        sprintf('WHERE [TruckID] = %.0f',truckID));
    
    %% Do the MinMax separatly
    %   This is needed for the current logic necessary to discern MinMax
    % data sets differently for each other (one set per key-off event).
    %   This logic should be implemeted above so that the script only needs
    % to loop through the data once, but this was an stop-gap solution.
    %   That, however, will require a ton of flags and assorted other
    % complicated logic control measures, it may be best for simplicity to
    % leave the MinMax logic separate from the event driven logic.
    
    % If there was any MinMax data that was not a NaN or empty value
    if any(~strncmp('',Min_Max_PublicDataID,1))
        
%         % If MMM_Update_Rate wasn't logged
%         if ~exist('MMM_Update_Rate','var')
%             % Set it to an empty set to that processMinMaxData will set it to null in the database
%             MMM_Update_Rate = [];
%             % Log a warning that this vehicle doesn't have MMM_Update_Rate logged
%             obj.warning.write('MMM_Update_Rate was not logged in the file, setting to null.')
%         end
        
        % Process it and add it to the database
        obj.processCANapeMinMaxData(LastFileDatenum, ECM_Run_Time, MMM_Update_Rate, Min_Max_PublicDataID, Min_Max_Data, cal, truckID);
        
        % Update tblTrucks saying that there was MinMax data
        update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'Yes'}, ...
            sprintf('WHERE [TruckID] = %0.f',truckID));
        
    else % All values of Min/Max data were NaN
%         Try to find if there was a Key_Switch transition from 1 to 0 yet still no Min/Max data
%         if exist('Key_Switch','var') && any(diff(nonan(Key_Switch))==-1)
%             Warn that Min/Max data may be missing from this .csv file
%             obj.warning.write('There was no Min/Max data in the file yet a Key_Switch transition from 1 to 0 was logged.');
%             obj.event.write('There was no Min/Max data in the file yet a Key_Switch transition from 1 to 0 was logged.');
            
            % Update tblTrucks saying that there should have been MinMax data and wasn't
            update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
                sprintf('WHERE [TruckID] = %0.f',truckID));
            
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No MinMax data in file ' fullFileName]);
        obj.event.write(['No MinMax data in file ' fullFileName]);
     end

    
    %% Write the Formatted Output to the database
    
    % Separate the data into two cell arrays, one with good data, one with excess data
    goodEventDecoded = eventDecoded(1:(writeIdxEvent - 1), :);
    %excessEventDecoded = eventDecoded(excessDataFlag, :);
    
    % Define Event Driven column names
    colNamesED = {'datenum', 'ECMRunTime', 'SEID', 'ExtID', 'DataValue', 'CalibrationVersion', 'TruckID', 'EMBFlag', 'TripFlag'};
    % If there was any good data in the file
    if size(goodEventDecoded,1) > 0
        startUpload = tic;disp('Tic - Uploading good event driven data to the database.')
        % Upload the good Event Driven data to the database normally
        fastinsert(obj.conn, '[dbo].[tblEventDrivenData]', colNamesED, goodEventDecoded);
        toc(startUpload)
        
        % Update tblTrucks saying that there was event driven data
        update(obj.conn, '[dbo].[tblTrucks]', {'EventData'}, {'Yes'}, ...
            sprintf('WHERE [TruckID] = %0.f',truckID));
        
    else
        % These was no good event driven data in the .csv file
        % Check how large the input vectors were, if they were over 100 long and there was
        % absolutely no event driven data (excess or good)
        if length(EventDriven_xSEID) > 100 && writeIdxEvent == 1
            % Print a warning in the log files that there should have been data present
            obj.warning.write('There was no Event Driven data in this file, yet it it contained over 100 lines.');
            obj.event.write('There was no Event Driven data in this file, yet it it contained over 100 lines.');
            
            % Update tblTrucks saying that there should have been event driven data
            update(obj.conn, '[dbo].[tblTrucks]', {'EventData'}, {'No'}, ...
                sprintf('WHERE [TruckID] = %0.f',truckID));
            
        end
    end
    
end

%% Interpolate ECM Run Time
function ECM_Run_Time = interpECMRunTime(ECM_Run_Time)
% This function takes in an ECM_Run_Time variable and interpolates the NaNs
%   - If ECM_Run_Time goes in reverse, it will keep the higher value until
%     it gets the the lower value, then continue on like normal if
%     ECM_Run_Time keeps going up.
%   
%   - If ECM_Run_Time goes up by more than 3 inbetween NaNs, it will use
%     the old ECM_Run_Time up the to new one, then continue like normal.
    
    % Look in the first 100 lines for an initial ECM_Run_Time
    for j = 1:101 % saw a legitamate case of 64 lines into file, just set this crazy high
        % If a value is found
        if ~isnan(ECM_Run_Time(j))
            % Set the first j entries of the interpolated ECM_Run_Time to that value
            ECM_Run_Time(1:j) = ECM_Run_Time(j);
            break
        end
    end
    
    % Throw an error if an initial ECM_Run_Time wasn't found
    if j==101
        error('CapabilityUploader:AddCSVFile:interpECMRunTime:failToLocateStartingECMRunTime', ...
            'Failed to find a valid ECM_Run_Time in the first 100 lines of the vector.');
    end
    
    % Now loop through the entire file, interpolating ECM_Run_Time in
    % between the NaNs (j is the index of the last value of ECM_Run_Time)
    for i = (j+1):length(ECM_Run_Time)
        
        % Find the value of the next ECM_Run_Time (a value that isn't a NaN)
        if ~isnan(ECM_Run_Time(i))
            
            % If we've traveled more than 40 variables without an updated
            % ECM_Run_Time, throw an error
%             if i-j > 40 % Max in field is 38, this may need to get bumped even more in the future
%                 error('CapabilityUploader:AddCSVFile:interpECMRunTime - Didn''t find an updated ECM_Run_Time variable in 40 lines, likely ECM data dropped out.');
%             else
                % Check that ECM_Run_Time hasn't gone up by over 3 or gone 
                % backwords (these could create dangerous interpolations 
                % between differenences of over 3 or reversing ECM_Run_Time)
                if (ECM_Run_Time(i) - ECM_Run_Time(j) <= 3) && (ECM_Run_Time(i) - ECM_Run_Time(j) > 0)
                    % Interpolate between the previous and current values
                    ECM_Run_Time(j:i) = linspace(ECM_Run_Time(j), ECM_Run_Time(i), i-j+1);
                else
                    % ECM_Run_Time incremented too much, just set to the last value
                    ECM_Run_Time(j:i-1) = ECM_Run_Time(j);
%                 end
                end
            % Set old index to current index
            j = i;
            
        end
    end
    
    % Go back, and set the NaNs left at the end back to the last known good
    % value of ECM_Run_Time
    ECM_Run_Time(j:end) = ECM_Run_Time(j);
end

%% Find Excess Event Driven data
function b = isExcessEvent(obj,SEID)
    % Returns false if any of these system error ids are passed in
    % 2085 - DPF_DELTAP_HIGH_ERR
    % 3284 - DPF_OUTP_HIGH_ERR
    % 5051 - NOX_OUT_SENSOR_HTR_WARMUP_ERR
    % 5987 - NOX_OUT_SENSOR_SIGNAL_ERR
    % 5988 - NOX_OUT_SENSOR_PWR_ERR
    % 5990 - NOX_OUT_SENSOR_HTR_ERR
    % 6094 - UDD_PUMP_LOW_ERR
    % 6095 - UDD_PUMP_HIGH_ERR
    % 6096 - UDD_SU_HEATER_LOW_ERR
    % 6097 - UDD_SU_HEATER_HIGH_ERR
    % 6098 - UDD_FCV_HIGH_ERR
    % 6099 - UDD_FCV_LOW_ERR
    % 6100 - UTDD_LINEHTR1_HIGH_ERR
    % 6101 - UTDD_LINEHTR1_LOW_ERR
    % 6102 - UTDD_TANKHTR1_HIGH_ERR
    % 6103 - UTDD_TANKHTR1_LOW_ERR
    % 7289 - UDD_POWERCTRL_HIGH_ERR
    % 7290 - UDD_POWERCTRL_LOW_ERR
    % 7450 - PM_OUT_HTR_HIGH_ERR
    % 7451 - PM_OUT_HTR_LOW_ERR
    % 7813 - UREA_LINEHTR1_HIGHSIDE_OL_ERR
    % 7814 - UREA_LINEHTR1_HIGHSIDE_STG_ERR
    % 7815 - UREA_LINEHTR1_HIGHSIDE_STB_ERR
    % 7816 - UREA_LINEHTR1_LOWSIDE_OL_ERR
    % 7818 - UREA_LINEHTR2_HIGHSIDE_OL_ERR
    % 7819 - UREA_LINEHTR2_HIGHSIDE_STG_ERR
    % 7820 - UREA_LINEHTR2_HIGHSIDE_STB_ERR
    % 7821 - UREA_LINEHTR2_LOWSIDE_OL_ERR
    % 7822 - UREA_LINEHTR3_HIGHSIDE_OL_ERR
    % 7823 - UREA_LINEHTR3_HIGHSIDE_STG_ERR
    % 7824 - UREA_LINEHTR3_HIGHSIDE_STB_ERR
    % 7825 - UREA_LINEHTR3_LOWSIDE_OL_ERR
    % September 21, 2012 - Added the following to the excess list:
    % 2896 - UREA_TANKLVL_OOR_HI_ERR
    % 2897 - UREA_TANKLVL_OOR_LO_ERR
    % 2898 - UREA_TANKT_OOR_HI_ERR
    % 2899 - UREA_TANKT_OOR_LO_ERR
    % 6981 - UQS_TMPTR_OOR_HI_ERR
    % 6982 - UQS_TMPTR_OOR_LO_ERR
    % 6996 - UQS_INTERNAL_ERR
    % 7286 - UQS_PERSIST_CONC_NO_VALUE_ERR
    % 8291 - UREA_TANKT_SENS_INT_ERR
    % 8293 - UREA_TANKLVL_SENS_INT_ERR
    % 8680 - UREA_TANKT_CURRENT_OOR_HI_ERR
    % 8681 - UREA_TANKT_CURRENT_OOR_LO_ERR
    % 8682 - UREA_TANKLVL_CURRENT_OOR_HI_ERR
    % 8683 - UREA_TANKLVL_CURRENT_OOR_LO_ERR
    % 8687 - UQS_TMPTR_INTERNAL_ERR
    % 8688 - UQS_TMPTR_CURRENT_OOR_HI_ERR
    % 8689 - UQS_TMPTR_CURRENT_OOR_LO_ERR
    % 8690 - UQS_UNKNOWN_FLUID_TYPE_ERR
    % 8691 - UQS_CONC_VOLTAGE_OOR_HI_ERR
    % 8692 - UQS_CONC_VOLTAGE_OOR_LO_ERR
    % 8693 - UQS_ECU_OVERTEMPERATURE_ERR
    % 8694 - UQS_CONC_CURRENT_OOR_HI_ERR
    % 8695 - UQS_CONC_CURRENT_OOR_LO_ERR
    % a = any(SEID==[2085 3284 5990 5051 5988 5987 7450 7451 6098 6099 7289 7290 6095 ...
    %                6094 6097 6096 7813 7815 7814 7816 7818 7820 7819 7821 7822 7824 ...
    %                7823 7825 6100 6101 6102 6103 ...
    %                2896 2897 2898 2899 6981 6982 6996 7286 8291 8293 8680 8681 8682 ...
    %                8683 8687 8688 8689 8690 8691 8692 8693 8694 8695]);
    
    % Use the system errors defined in the database now
    b = any(SEID==obj.evddIgnore.SEID);
    
end

function calNumber = dot2numB(obj, calDotStr)
% Modified from dot2num to give the byte-swapped version of the software
% Used to check if the LDD software version was recorded wrong

%Return a 6 or 8 digit cal number given a dot separated string
%   Convert a calibration from this format: 4.13.0.6 or 31.2.0.26
%   To this format:                           413006 or 31020026
%   
%   This returns a 6 or 8 digit format, without decimals, that follows this convetion:
%       X.XX.X.XX of version control, but with the dots removed
%     XX.XX.XX.XX of version control, but with the dots removed
%   
%   Examples (HDE Style):    5.0.0.5  --> 500005
%                           4.10.0.18 --> 410018
%   
%   Examples (CMI Style): 31.42.99.32 --> 41429932
%                           31.2.0.26 --> 31020026
%   
%   Usage: calNumber = dot2num(obj, calDotStr)
%   
%   Inputs -
%   calDotStr: Input string of a software version in Calterm dot notation (e.g., 9.20.0.4)
%   
%   Outputs -
%   calNumber: Numeric version of the software in 6 or 8 digit format (e.g., 920004)
%   
%   Original Version - Chris Remington - January 10, 2011
%   Revised - Chris Remington - May 7, 2013
%     - Modified to automatically pick either 6 digit format or 8 digit format based on
%       the major version ( <10 = HDE style 6 digit version control, otherwise 8 digit)
%   Adapted - Chris Remington - May 14, 2013
%     - Modified to be included in the IUPRtool object
%   Adapted - Chris Remington - June 20, 2013
%     - Modified to be included in the database IUPR object
%   Revised - Chris Remington - September 23, 2013
%     - Changed to use the new isLDD flag in the IUPR object so that
%       programs with 7-digit software version have the correct numeric
%       software version ouput
%     - If the first number is > 9, then this will ignor the isLDD flag
%       and output it as an 8-digit software version
%   Revised - Chris Remington - January 31, 2013
%     - Switched to only do something special for HD 6-digit software
%     - LDD 7 digit software just has the leading zero fall off so can be done normally
    
    % If a string was supplied as input
    if ischar(calDotStr)
        % Find the '.' in the string
        IdxDot = strfind(calDotStr, '.');
        % If three '.' were found, continue
        if length(IdxDot) == 3
            % Pull out the four version numbers
            % X.0.0.0
            %num1 = calDotStr(1:(IdxDot(1)-1));
            num4 = calDotStr(1:(IdxDot(1)-1));
            % 0.X.0.0
            %num2 = calDotStr((IdxDot(1)+1):(IdxDot(2)-1));
            num3 = calDotStr((IdxDot(1)+1):(IdxDot(2)-1));
            % 0.0.X.0
            %num3 = calDotStr((IdxDot(2)+1):(IdxDot(3)-1));
            num2 = calDotStr((IdxDot(2)+1):(IdxDot(3)-1));
            % 0.0.0.X
            %num4 = calDotStr((IdxDot(3)+1):end);
            num1 = calDotStr((IdxDot(3)+1):end);
            
            % If this is a HD program using 6-digit software
            if obj.is6Dig
                % Pad position 2 and 4 if necessary
                if length(num2) == 1
                    % Add leading zero
                    num2 = ['0', num2];
                end
                if length(num4) == 1
                    % Add leading zero
                    num4 = ['0', num4];
                end
                % Continue if each part turned out to be the correct length
                if length(num1)==1 && length(num2)==2 && length(num3)==1 && length(num4)==2
                    % Concatinate the four parts together
                    formattedCalString = [num1 num2 num3 num4];
                    % Convert to a double and return that value
                    calNumber = str2double(formattedCalString);
                    % Check if str2double failed to convert the data
                    if isnan(calNumber)
                        % Throw an error
                        error('Capability:dot2num:str2doubleError','There was a problem with str2double converting the interpreted calibration number %s to a number',formattedCalString)
                    end
                else
                    % Individual pieces weren't the right length, return an error
                    error('Capability:dot2num:Error6Digit','There was an problem with the expected number of digits when processing %s',calDotStr);
                end
            else % This is a 7 or 8 digit format calibration number
                % Pad position 2, 3, and 4 if necessary with a leading zero
                if length(num2) == 1
                    % Add leading zero
                    num2 = ['0', num2];
                end
                if length(num3) == 1
                    % Add leading zero
                    num3 = ['0', num3];
                end
                if length(num4) == 1
                    % Add leading zero
                    num4 = ['0', num4];
                end
                % Continue if each part turned out to be the correct length
                if length(num2)==2 && length(num3)==2 && length(num4)==2 % length(num1)==2 && 
                    % Concatinate the four parts together
                    formattedCalString = [num1 num2 num3 num4];
                    % Convert to a double and return that value
                    calNumber = str2double(formattedCalString);
                    % Check if str2double failed to convert the data
                    if isnan(calNumber)
                        % Throw an error
                        error('Capability:dot2num:str2doubleError','There was a problem with str2double converting the interpreted calibration number %s to a number',formattedCalString)
                    end
                else
                    % Individual pieces weren't the right length, return an error
                    error('Capability:dot2num:Error8Digit','There was an problem with the expected number of digits when processing %s',calDotStr);
                end
            end
        else
            % Couldn't find three dots, throw an error
            error('Capability:dot2num:InvalidStringInput','Couldn''t find three dots in the string %s',calDotStr);
        end
    else
        % Input wasn't a string, throw an error
        error('Capability:dot2num:InvalidInput','Input must be a string or a software version is dot notation (e.g., 31.2.0.26)');
    end
end
