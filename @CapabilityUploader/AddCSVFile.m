function AddCSVFile(obj, fullFileName, truckID)
%This will parse a csv file and populate the data into the database.
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
%   Original Version - Chris Remington - January 26, 2012
%   Revised - Chris Remington - June 1, 2012
%       - Modified upload routine to split the "excess" event driven data
%         and upload that into an auxilary database while keeping the "good"
%         event driven data uploaded into the main database. This should 
%         eliminate the need to periodically clean out the main event driven
%         data table (and prevent mistakes related to deleting data)
%   Revised - Chris Remington - August 1, 2012
%       - Modified the last column name in the tblEventDrivenData table from 
%         'DevFlag' to 'TripFlag' to give it better meaning. This code will now
%         default that value to zero as the .csv files are from Calterm loggers
%         that are generally not used on test trips
%   Revised - Chris Remington - August 30, 2012
%       - Modified to skip uploading excess event driven data into the database
%         Only the good event driven data will get uploaded from now on
%   Revised - Chris Remington - September 21, 2012
%       - Further changed to not even decoded the excess event driven data so that process
%         is much faster now
%       - Added additional system errors to the excess event driven list (specifically the
%         CES UQS and DEF Header smart sensor debounce logic diagnostics)
%   Revised - Chris Remington - January 25, 2013
%       - Added error handling for when a non-6 digit format calibration format is present
%         in a .csv file and CalString2Num returns a NaN
%   Revised - Chris Remington - May 24, 2013
%       - Added functionality to track the latest Calterm Version, Screen Monitor Type, 
%         Initial Monitor Rate, and Log Mode for each truck more easily
%   Revised - Chris Remington - June 26, 2013
%       - Changed from  to dot2num. Error handling is different in this function, so I'm
%         not sure if anything major will break
%   Revised - Chris Remington - August 20, 2013
%       - Changed how ECM code was handled in the case that is was all numbers with no
%         letters and converted it into a string
%   Revised - Chris Remington - September 9, 2013
%       - Added functionality to update in the tblTrucks table with a 'Yes' or 'No' for
%         whether or not MinMax and Event Driven data are present in the log files
%   Revised - Chris Remington - October 1, 2013
%       - Added ability for .csv file to be successfully processed if MMM_Update_Rate
%         wasn't present in the log file (will be a null in the database)
%       - Added tracked for the number of 'blank' or all NaN lines were in a file.
%         Normally this is less than 2 or 3, but sometime Calterm 3.6.5 Kishu would
%         trigged excessive lines if additional J1939-71 parameters were being logged on a
%         different screen, make the files very large (should be fixed in Catlerm 3.7.0)
%   Revised - Chris Remington - October 8, 2013
%       - Added tracker for if MMM_Update_Rate is non-zero to check for the MMM Overlay or
%         if MMM_Update_Rate isn't logged
%       - Added tracker for the size of the last file processed for a truck to make sure
%         we aren't getting files that are too big
%   Revised - Chris Remington - Januay 20, 2014
%       - Moved from using a list of excess event driven data defined in the .m file to
%         pull this instead from a database table so it can be customizd for each program
%   Revised - Chris Remington - February 27, 2014
%       - Added custom errors to be thrown when there are parameters needed from the .csv 
%         files are not present
%   Revised - Chris Remington - March 31, 2014
%       - If the software version paremter is mis-capitolized, correct it to the standard 
%         capitolization so it is compatible with the rest of the code
%   Revised - Chris Remington - April 3, 2014
%       - Added little-endian ECM support
%   Revised - Chris Remington - April 4, 2014
%       - Added logic to check if the calibration version was recorded in reverse as
%         is sometimes the case for the V8 programs
%   Revised - Yiyuan Chen - 2015/03/06
%       - Added the feature of processing DPF_Incomplete_Regen when uploading its capability data  
%   Revised -Dingchao Zhang - March 18th, 2015
%       -Added update tblTrucks saying that there should have been MinMax data
%       - and wasn't in the condition of no key switch from 1 to 0
%   Revised - Yiyuan Chen - 2015/03/19
%       - Added the feature of processing DPF_TOO_FREQUENT_REGEN_ERR when uploading its capability data
%   Revised - Yiyuan Chen - 2015/03/25
%       - Added the feature of processing DOSER_USEDUP_DFM_ERR when uploading its capability data
%   Revised - Yiyuan Chen - 2015/04/05
%       - Added the feature of processing some more special diagnostics when uploading its capability data
%   Revised - Dingchao Zhang - 2015/10/25
%       - Add lines to update cal rev, ver, fileID info in tbleventdriven 

    %% Prerequisite Code
    % Get the name of the truckID to ensure that its a valid truck
    % This will throw an error if an invalid truckID is specified
    truckName = obj.getTruckName(truckID);
    obj.event.write('-----------------------------------------------------------');
    obj.event.write(['Truck - ' truckName]);
    obj.event.write(['File  - ' fullFileName]);
    obj.warning.write(['File  - ' fullFileName]);
    
    % If the input was properly specified as a single string (one row)
    if ischar(fullFileName) && size(fullFileName,1) == 1
        % If the file name provided exists
        if exist(fullFileName, 'file')
            % Call Dan's script
            obj.readCaltermIII_EcmDataOnly(fullFileName);
            
            % Check if Dan's script indicated a failure in it's own way
            if readFailed == 1
                % Dan's script indicated a soft failure
                obj.event.write(['Soft failure, skipping ' fullFileName]);
                obj.error.write(['Soft failure, skipping ' fullFileName]);
                % Throw a hard error
                error('CapabilityUploader:AddCSVFile', 'Soft failure on file %s', fullFileName);
            elseif readFailed == 2
                % Dan's script indicated a "No Data in File" error
                % Don't log this to the error log, just the event log
                obj.event.write(['Soft failure, skipping ' fullFileName]);
                % Throw a hard error
                error('CapabilityUploader:AddCSVFile:NoData', 'No data in file %s.', fullFileName);
            end
        else
            % The file specified doesn't exist
            obj.event.write(['File does not exist - ' fullFuleName]);
            obj.error.write(['File does not exist - ' fullFuleName]);
            % Exit the function
            return
        end
    else
        % Throw an error
        error('CapabilityUploader:AddCSVFile', 'Filename input is not a 1D character array.');
    end
    
    % You can only make it here if:
    % - Valid truckID was specified
    % - Dan's script was supplied with a good file name and ran properly
    
    %% Correct for capitolization errors in the "_Calibration_Version" parameter
    if exist('i_calibration_version','var')
        % Set it to the standard spelling
        i_Calibration_Version = i_calibration_version;
    elseif exist('i_calibration_Version','var')
        % Set it to the standard spelling
        i_Calibration_Version = i_calibration_Version;
    elseif exist('i_Calibration_version','var')
        % Set it to the standard spelling
        i_Calibration_Version = i_Calibration_version;
    end
    
    %% LDD Backward Cal Fixer
    % Sometime the MinMax file is recorded by Calterm in little-endian mode
    % If software version was present and this is a program with a little-endian ECM
    if exist('i_Calibration_Version','var') && obj.littleendian
        % Get the backward version of this software
        correctSw = dot2numB(obj,i_Calibration_Version{1});
        % Check if this is a knwon software version
        if any(correctSw==obj.knownSw)
            % Convert it back to a dot string as if it had been read from the file
            dotString = obj.num2dot(correctSw);
            % Write a message to the error log
            obj.error.write('-----------------------------------------------------------')
            obj.error.writef('Corrected reversed software version of %s to %s for file %s\r',i_Calibration_Version{1},dotString,fullFileName);
            % Similar message in the event log
            obj.event.writef('Corrected reversed software version of %s to %s for file %s\r',i_Calibration_Version{1},dotString,fullFileName);
            
            % Set i_Calibration_Version to the corrected / reversed version
            i_Calibration_Version = {dotString};
            
            % If ECM_Rum_Time exists and has a non-NaN enrty, byte-swap it manually
            if exist('ECM_Run_Time','var') && sum(isnan(ECM_Run_Time)) < length(ECM_Run_Time)
                % Raw Hex
                rawHex = dec2hex(nonan(ECM_Run_Time*5));
                % Flipped Hex
                rawHex = rawHex(:,[7 8 5 6 3 4 1 2]);
                % Decoded hex
                ECM_Run_Time(~isnan(ECM_Run_Time)) = hex2dec(cellstr(rawHex))/5;
            end
            
            % If MMM_Update_Rate exists and has a non-NaN enrty, byte-swap it manually
            if exist('MMM_Update_Rate','var') && sum(isnan(MMM_Update_Rate)) < length(MMM_Update_Rate)
                % Raw Hex
                rawHex = dec2hex(nonan(MMM_Update_Rate));
                % Flipped Hex
                rawHex = rawHex(:,[7 8 5 6 3 4 1 2]);
                % Decoded hex
                MMM_Update_Rate(~isnan(MMM_Update_Rate)) = hex2dec(cellstr(rawHex));
            end
        end % else backward is also an unknown software version so just try to use it
    end
    
    %% Calibration Checker
    % If this log file has an updated calibration version
    if exist('i_Calibration_Version','var')
        % Convert it to a number
        cal = obj.dot2num(i_Calibration_Version{1});
        % This new number will be updated below
        % If the cal version couldn't be interpreted as a number
        if isnan(cal)
            % Throw an error on this condition
            error('CapabilityUploader:AddCSVFile:InvaildSoftwareVer', ...
                  'The software version specified in the .csv file was %s and couldn''t be interpreted into numerical format.', i_Calibration_Version{1});
        end
    else
        % Need to pull out the software version currenty stored in the cache
        cal = obj.getLastSoftware(truckID);
        % If getLastSoftware returned a nan, meaning that it wasn't in the cache
        if isnan(cal)
            % Throw an error to halt execution
            error('CapabilityUploader:AddCSVFile:CalibrationMissingInHeader', ...
                'i_Calibration_Version is not in the header of the file and has no cached version.');
        end
    end
    
    % If this log file has an updated calibration revision number
    if ~exist('Calibration_Revision_Number','var')
        % Try to get a the last revision number from the database
        Calibration_Revision_Number = obj.getLastCalRev(truckID);
        % If this is a NaN (never assigned in the database), ignore it becuase 
        % calibration revision number isn't crucial to be able to add the data 
        % to the database currently
        if isnan(Calibration_Revision_Number)
        end
    end
    
    % If this log file has an updated ECM Code
    if exist('i_ECM_Code','var')
        % Saw a case of an Atlantic _ECM_Code that was 1103620.04 and was a double
        if isnumeric(i_ECM_Code)
            % Convert the number to a string
            i_ECM_Code = sprintf('%.2f',i_ECM_Code);
        else
            % Pull the string out of the cell
            i_ECM_Code = i_ECM_Code{1};
        end
    else
        % Try to get a the last revision number from the database
        i_ECM_Code = obj.getLastECMCode(truckID);
        % If this is a NaN (never assigned in the database), ignore it becuase 
        % calibration revision number isn't crucial to be able to add the data 
        % to the database currently
        if strcmp('null',i_ECM_Code)
        end
    end
    
    %% Calterm and Logger Configuration Manager Update
    % Get the ETDVersion from the file name
    pathParts = toklin(fullFileName, '\');
    % Get the file parts of the file name
    fileParts = toklin(pathParts{end},'_');
    % Take the first one as this will be the ETDVersion
    ETDVersion = fileParts{1};
    % Capture the last abs_time to mark the newest data point processed
    LastFileDatenum = abs_time(end);
    % If MMM_Update_Rate is logged in the file
    if exist('MMM_Update_Rate','var')
        % Denan it
        MMMRate = nonan(MMM_Update_Rate);
        % If the values aren't all zero (i.e., MMM logger is turned on)
        if length(MMMRate) < 1
            MMMOverlay = 'Empty';
        elseif mean(MMMRate) > 0
            % Set the indicator to Yes
            MMMOverlay = 'Yes';
        else
            % Set the indicator to No
            MMMOverlay = 'No';
        end
    else
        % Note that the MMM_Update_Parameter isn't logged
        MMMOverlay = 'Not Logged';
    end
    % Get the size of the file being processed
    dirData = dir(fullFileName);
    fileSize = sprintf('%.0f KB',dirData(1).bytes/1024);
    
    % Assign the cal ver and rev to obj property
    obj.CalVer = cal;
    obj.CalRev = Calibration_Revision_Number;
    
    % Update the informational columns for this truck in the tbiTrucks table
    update(obj.conn, 'tblTrucks', ...
        {'SoftwareCache','RevisionCache',             'ECMCode',  'LastFileDatenum','LastFileDateTime',         'ETDVersion','CaltermVersion','InitialMonitorRate','ScreenMonitorType','LogMode', 'MMMTurnedOn', 'LastFileSize'}, ...
        {cal,             Calibration_Revision_Number, i_ECM_Code, LastFileDatenum, datestr(LastFileDatenum,31), ETDVersion,  CaltermVersion,  InitialMonitorRate,  ScreenMonitorType,  LogMode,   MMMOverlay,    fileSize},...
        sprintf('WHERE [TruckID] = %0.f',truckID));
    
    %% Check Variable Existance
    % Check for EventDriven and MinMax related paramters exist on the
    % screen
    if (~exist('EventDriven_xSEID','var')|| ~exist('EventDriven_Data','var')) && (~exist('MinMax_PublicDataID','var')||~exist('MinMax_Data','var'))
        
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No Event data in file ' fullFileName]);
        obj.event.write(['No Event data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
        update(obj.conn, '[dbo].[tblTrucks]', {'EventData'}, {'No'}, ...
        sprintf('WHERE [TruckID] = %0.f',truckID));
            
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No MinMax data in file ' fullFileName]);
        obj.event.write(['No MinMax data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
        update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
        sprintf('WHERE [TruckID] = %0.f',truckID));
            
        error('CapabilityUploader:AddCSVFile:ParameterMissing',...
            'File was missing eventdriven and minmax parameters.')
        
    % Check for EventDriven_Data
    elseif ~exist('EventDriven_Data','var')
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No Event data in file ' fullFileName]);
        obj.event.write(['No Event data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
        update(obj.conn, '[dbo].[tblTrucks]', {'EventData'}, {'No'}, ...
        sprintf('WHERE [TruckID] = %0.f',truckID));
    
        error('CapabilityUploader:AddCSVFile:ParameterMissing',...
            'File was missing parameter EventDriven_Data.')
        
    % Check for MinMax_PublicDataID
    elseif ~exist('MinMax_PublicDataID','var')
        
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No MinMax data in file ' fullFileName]);
        obj.event.write(['No MinMax data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
        update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
        sprintf('WHERE [TruckID] = %0.f',truckID));
    
        error('CapabilityUploader:AddCSVFile:ParameterMissing',...
            'File was missing parameter MinMax_PublicDataID.')
        
    % Check for MinMax_Data
    elseif ~exist('MinMax_Data','var')
        
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No MinMax data in file ' fullFileName]);
        obj.event.write(['No MinMax data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
        update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
        sprintf('WHERE [TruckID] = %0.f',truckID));
    
        error('CapabilityUploader:AddCSVFile:ParameterMissing',...
            'File was missing parameter MinMax_Data.')
        
    % Check for ECM_Run_Time
    elseif ~exist('ECM_Run_Time','var')
        error('CapabilityUploader:AddCSVFile:ParameterMissing',...
            'File was missing parameter ECM_Run_Time.')
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
    numRecord = sum(~strcmp('NaN', EventDriven_xSEID)&~strcmp('NaN', EventDriven_Data));
    % This is what will get loaded into the database
    % 9 columns of data and as many rows as have data
    eventDecoded = cell(numRecord, 10);
    % Initalize the logical array to hold whether each line is excess data or not
    excessDataFlag(1:numRecord,1) = false;
    % Start a counter for the number of blank lines in the file (all values are a NaN)
    blankLines = 0; % this should be 1 to 5 for normal files
    
    % Initalize the write index for the above vector
    writeIdxEvent = 1;
    
    
    % Get the latest processed FileID and increment by 1
    LastFileID = fetch(obj.conn, sprintf('SELECT max ([FileID]) FROM [dbo].[tblProcessedFiles]')); 
    FileID = LastFileID.x + 1;
    obj.FileID = FileID;
    
    %% Loop through data
    % Loop through the entire .csv file, make sense of the data
    for i = 1:length(EventDriven_xSEID)
        
        % Look for an updated ECM_Run_Time
        if ~isnan(ECM_Run_Time(i))
            % If there was also EventDriven data on this line
            if ~strcmp(EventDriven_Data{i}, 'NaN') || ~strcmp(MinMax_Data{i}, 'NaN')
                % Write a line to the error log
                obj.warning.write('CapabilityUploader:AddCSVFile:MultipleDataOnOneLine - Both ECM_Run_Time and Event Driven or MinMax data found on the same line. - This is advisory');
                obj.event.write('CapabilityUploader:AddCSVFile:MultipleDataOnOneLine - Both ECM_Run_Time and Event Driven or MinMax data found on the same line. - This is advisory');
            end
            
        elseif ~strcmp(EventDriven_Data{i}, 'NaN')
            % Event Driven Data
            % There is event driven data on this line without ECM_Run_Time
            
            %%% Little Endian Check Needed
            
            % If this is a little endian ECM
            if obj.littleendian
                % Calculate the SEID and ExtID for a little-endian ECM
                ExtID = hex2dec2(EventDriven_xSEID{i}([7 8 5 6]));
                SEID = hex2dec2(EventDriven_xSEID{i}([3 4 1 2]));
            else
                % Calculate the SEID and ExtID for a big-endian ECM
                ExtID = hex2dec2(EventDriven_xSEID{i}(1:4));
                SEID = hex2dec2(EventDriven_xSEID{i}(5:8));
            end
            
            % Flag whether or not this data point was excess event driven data or not
            % and skip it
            % If this was from dpf filt eff (se 4758) on old s/w for Pacific, skip it too
            if isExcessEvent(obj,SEID) || (SEID==4758&&cal<710007&&strcmp('HDPacific',obj.program))
                % Set the flag for this line to true
                excessDataFlag(writeIdxEvent) = true;
                % Don't decode this data
                % Incrememnt the writeIdxEvent
                writeIdxEvent = writeIdxEvent + 1;
                
                % Should somehow note that excess event data was present and ignored
                % Maybe a way to track the system errors that are active
                
                % Continue to the next loop itaration
                continue
            end
            
            % Try to find a match for this xSEID
            try
                % Send this data into the decoder
                decodedData = obj.decodeEvent(SEID + ExtID*65536, EventDriven_Data{i});
            catch ex
                % Failed to locate decoding information for this xSEID
                error('CapabilityUploader:AddCSVFile:EVDDInfoMissing', 'Failed to locate decoding information for SEID %0.f with ExtID %0.f = xSEID of %0.f with software %.0f',SEID,ExtID,SEID + ExtID*65536,cal);
            end
            
            % Add the info to a new line of the eventDecoded cell array
            % colNames = {datenum, ECMRunTime, SEID, ExtID, DataValue, CalibrationVersion, TruckID, EMBFlag, TripFlag}
            eventDecoded(writeIdxEvent,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, ExtID, decodedData, cal, truckID, 0, 0,FileID};
            
            % Execute extra processings for some special diagnostics
            if writeIdxEvent>1 && ~isempty(cell2mat(eventDecoded(writeIdxEvent-1,:))) && SEID==3036 && cell2mat(eventDecoded(writeIdxEvent-1,3))==3036 && abs(abs_time(i)-cell2mat(eventDecoded(writeIdxEvent-1,1)))<0.000005
                % Generate an extra parameter for DPF_INCOMPLETE_REGEN_ERR & add 1 more line to the eventDecoded cell array
                % Calculate the difference between the 2 capability parameters
                % Add the difference value to the eventDecoded cell array, with a fake extID
                % Increment the writeIdxEvent by 2
                if ExtID==1 && cell2mat(eventDecoded(writeIdxEvent-1,4))==0
                    diffData = decodedData - cell2mat(eventDecoded(writeIdxEvent-1,5));
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                elseif ExtID==0 && cell2mat(eventDecoded(writeIdxEvent-1,4))==1
                    diffData = cell2mat(eventDecoded(writeIdxEvent-1,5)) - decodedData;
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                else % Increment the writeIdxEvent
                    writeIdxEvent = writeIdxEvent + 1;
                end
            elseif writeIdxEvent>1 && ~isempty(cell2mat(eventDecoded(writeIdxEvent-1,:))) && SEID==3590 && cell2mat(eventDecoded(writeIdxEvent-1,3))==3590 && abs(abs_time(i)-cell2mat(eventDecoded(writeIdxEvent-1,1)))<0.000005
                % Similarly process for DPF_TOO_FREQUENT_REGEN_ERR
                if ExtID==2 && cell2mat(eventDecoded(writeIdxEvent-1,4))==1
                    diffData = decodedData - cell2mat(eventDecoded(writeIdxEvent-1,5));
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                elseif ExtID==1 && cell2mat(eventDecoded(writeIdxEvent-1,4))==2
                    diffData = cell2mat(eventDecoded(writeIdxEvent-1,5)) - decodedData;
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                else % Increment the writeIdxEvent
                    writeIdxEvent = writeIdxEvent + 1;
                end
            elseif writeIdxEvent>1 && ~isempty(cell2mat(eventDecoded(writeIdxEvent-1,:))) && SEID==4748 && cell2mat(eventDecoded(writeIdxEvent-1,3))==4748 && abs(abs_time(i)-cell2mat(eventDecoded(writeIdxEvent-1,1)))<0.000005
                % Similarly process for DOSER_USEDUP_DFM_ERR but calculate the product
                if (ExtID==0 && cell2mat(eventDecoded(writeIdxEvent-1,4))==1) || (ExtID==1 && cell2mat(eventDecoded(writeIdxEvent-1,4))==0)
                    prodData = decodedData * cell2mat(eventDecoded(writeIdxEvent-1,5));
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, prodData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                else % Increment the writeIdxEvent
                    writeIdxEvent = writeIdxEvent + 1;
                end
            elseif writeIdxEvent>1 && ~isempty(cell2mat(eventDecoded(writeIdxEvent-1,:))) && SEID==1752 && cell2mat(eventDecoded(writeIdxEvent-1,3))==1752 && abs(abs_time(i)-cell2mat(eventDecoded(writeIdxEvent-1,1)))<0.000005
                % Similarly process for DPF_NOT_PRESENT_ERR
                if ExtID==0 && cell2mat(eventDecoded(writeIdxEvent-1,4))==1
                    diffData = decodedData - cell2mat(eventDecoded(writeIdxEvent-1,5));
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                elseif ExtID==1 && cell2mat(eventDecoded(writeIdxEvent-1,4))==0
                    diffData = cell2mat(eventDecoded(writeIdxEvent-1,5)) - decodedData;
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 9, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                elseif ExtID==2 && cell2mat(eventDecoded(writeIdxEvent-1,4))==3
                    diffData = decodedData - cell2mat(eventDecoded(writeIdxEvent-1,5));
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 8, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                elseif ExtID==3 && cell2mat(eventDecoded(writeIdxEvent-1,4))==2
                    diffData = cell2mat(eventDecoded(writeIdxEvent-1,5)) - decodedData;
                    eventDecoded(writeIdxEvent+1,:) = {abs_time(i), ECM_Run_Time_interp(i), SEID, 8, diffData, cal, truckID, 0, 0};
                    writeIdxEvent = writeIdxEvent + 2;
                else % Increment the writeIdxEvent
                    writeIdxEvent = writeIdxEvent + 1;
                end
            else % for other normal diagnostics
                % Increment the writeIdxEvent
                writeIdxEvent = writeIdxEvent + 1;
            end
            
        elseif ~strcmp(MinMax_Data{i}, 'NaN')
            % MinMax line, ignore
        else
            %% No Data on Line, note Datalink Dropout
            % There was a datalink dropout in the middle of the file or
            % the end of the file
            %obj.warning.write(['CapabilityUploader:AddCSVFile - Datalink dropout on line ' num2str(i) ' for file ' fullFileName]);
            % Comment this out, some file have thousands of blank lines making the log
            % files huge
            %obj.event.write(['CapabilityUploader:AddCSVFile - Datalink dropout on line ' num2str(i) ' for file ' fullFileName]);
            % Instead sum the number of blank line, then write one event log with that
            % Add to the summation the number of blank lines
            blankLines = blankLines + 1;
        end
        
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
    
    % If there was any MinMax data that was not a NaN value
    if any(~strncmp('N',MinMax_PublicDataID,1))
        
        % If MMM_Update_Rate wasn't logged
        if ~exist('MMM_Update_Rate','var')
            % Set it to an empty set to that processMinMaxData will set it to null in the database
            MMM_Update_Rate = [];
            % Log a warning that this vehicle doesn't have MMM_Update_Rate logged
            obj.warning.write('MMM_Update_Rate was not logged in the file, setting to null.')
        end
        
        % Process it and add it to the database
        obj.processMinMaxData(abs_time, ECM_Run_Time, MMM_Update_Rate, MinMax_PublicDataID, MinMax_Data, cal, truckID);
        
        % Update tblTrucks saying that there was MinMax data
        update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'Yes'}, ...
            sprintf('WHERE [TruckID] = %0.f',truckID));
        
    else % All values of Min/Max data were NaN
        % Try to find if there was a Key_Switch transition from 1 to 0 yet still no Min/Max data
        if exist('Key_Switch','var') && any(diff(nonan(Key_Switch))==-1)
            % Warn that Min/Max data may be missing from this .csv file
            obj.warning.write('There was no Min/Max data in the file yet a Key_Switch transition from 1 to 0 was logged.');
            obj.event.write('There was no Min/Max data in the file yet a Key_Switch transition from 1 to 0 was logged.');
            
            % Update tblTrucks saying that there should have been MinMax data and wasn't
            update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
                sprintf('WHERE [TruckID] = %0.f',truckID));
            
        end
        % Note that there was no MinMax data in this file (not not that MinMax data was expected)
        disp(['No MinMax data in file ' fullFileName]);
        obj.event.write(['No MinMax data in file ' fullFileName]);
        % Update tblTrucks saying that there should have been MinMax data and wasn't
            update(obj.conn, '[dbo].[tblTrucks]', {'MinMaxData'}, {'No'}, ...
                sprintf('WHERE [TruckID] = %0.f',truckID));
    end
    
    %% Write the Formatted Output to the database
    
    % Separate the data into two cell arrays, one with good data, one with excess data
    goodEventDecoded = eventDecoded(~excessDataFlag, :);
    %excessEventDecoded = eventDecoded(excessDataFlag, :);
    
    % Define Event Driven column names
    colNamesED = {'datenum', 'ECMRunTime', 'SEID', 'ExtID', 'DataValue', 'CalibrationVersion', 'TruckID', 'EMBFlag', 'TripFlag','FileID'};
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
