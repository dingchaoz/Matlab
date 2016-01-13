function success = AddMiniMatFile(obj, fullFileName, truckID, cals)
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
%   cals:         Structure that contains the definitions of what date and
%                   what truck had what software revisions
%   
%   Outputs--- UNDECIDED YET
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
%   Adapted - Chris Remington - August 31, 2012
%       - Adapted the AddCSVCode to instead take in a mini .mat file from CANape
%         This is the data that the loggers on the HD test trips spits out.
%       - Major modifications:
%           > Error Handling + Error Identifiers were all changed / revamped
%           > Software Version is found using a manual look-up instead of the 
%             header parameter that is avaiable in the .csv files
%           > Main "loop" to look through the data is simpler
%           > Min/Max logic is included here for that reason, it's much simpler
%           > ECM_Run_Time is absolutely not avaiable and will be set to a NaN
%           > abs_time will get uploaded in UTC (same as systime but calculated 
%             by using 'Date' and 'Time' + the respective t0, t1, t2, etc. timestamp
%           > For files not during actual trip days, they will have a skipped error thrown
%           > Doesn't upload the excess event driven data to an alternate database
%           > Doesn't attempt to decode excess event driven data for the above reason
%   Revised - Chris Remington - September 4, 2012
%       - Revamped timestamp calculation after seeing values in year 2020
%           > Added more "sanity" checks with systime
%           > Added overall maximum date as a catch-all for simple errors
%           > Corrects for a few .mat files where the Event Driven and Min/Max data
%             timestamps are offset from the norm (correct them using the systime)
%   Revised - Chris Remington - August 22, 2013
%       - Added the tripFlag definition to the top of the file and changed the default to
%         be 0 because not I have processed a ton of the CANape data that wasn't from a
%         test trip, so this flag will need to be updated manually
%       - Added more system error to the execess event list that should be ignored
    
    %% Define whether to flag this as trip data
    tripFlag = 0;
    % Also don't forget about the min and max date defined in here
    
    %% Prerequisite Code
    % Get the name of the truckID to ensure that its a valid truck
    % This will throw an error if an invalid truckID is specified
    truckName = obj.getTruckName(truckID);
    obj.event.write(''); % Create a blank line
    obj.event.write(['Truck - ' truckName]);
    obj.event.write(['File  - ' fullFileName]);
    obj.warning.write(['File  - ' fullFileName]);
    
    % If the input was properly specified as a single string (one row)
    if ischar(fullFileName) && size(fullFileName,1) == 1
        % If the file name provided exists
        if exist(fullFileName, 'file')
            % Try to read in the mini .mat file
            try
                % Use the native Matlab method to load in the mini .mat file
                load(fullFileName);
            catch ex
                % There was a read error
                obj.event.write(['CANape file read failure, skipping ' fullFileName]);
                obj.error.write(['CANape file read failure, skipping ' fullFileName]);
                % Throw a hard error
                error('CapabilityUploader:AddMiniMatFile:ReadError', 'Error reading file %s', fullFileName);
            end
        else
            % The file specified doesn't exist
            obj.event.write(['File does not exist - ' fullFuleName]);
            obj.error.write(['File does not exist - ' fullFuleName]);
            % Exit the function
            return
        end
    else
        % Throw an error about in improper file name input
        error('CapabilityUploader:AddMiniMatFile:FileName', 'Filename input is not a 1D character array.');
    end
    
    % You can only make it here if:
    % - Valid truckID was specified
    % - .mat file was read in properly
    
    %% Calibration Look-up - Manually defined for CANape files
    % Because the winter trip CANape data doesn't have header parameters, the software
    % version needs to be looked-up manually using look-up table by day and truck
    
    % Define the data here becuase this is the easiest interm solution
    % Later, it'd be nice to have this loaded into the object from a spreadsheet
    
    % Calcualte the short truck name (T142, T143, T145, T146)
    shortTruckName = truckName([5 7 8 9]);
    % Calculate the matlab datenum of the file
    fileDateStamp = datenum(Date(1),Date(2),Date(3));
    % Try to find a match
    idxMatch = fileDateStamp == cals.datenum;
    % Default the match to a NaN
    cal = NaN;
    % If there was a match in the data, set the correct value
    if sum(idxMatch) == 1
        % Look up the software version for the matching truck and date
        cal = cals.(shortTruckName)(idxMatch);
    end
    % If there was no match or the match was a NaN (meaning it wasn't part of the trip)
    if isnan(cal)
        % Skip this file as it wasn't a part of the official summer trip
        error('CapabilityUploader:AddMiniMatFile:FileNotDuringTrip', ...
          'Skipping file %s\nIt wasn''t on a date that was during the winter trip',fullFileName)
    end
    
    %% Figure out the timestamps for Min/Max and Event Driven data
    % Pull the names into known names that won't change
    
    % Event Driven data if it exists
    e1 = whos('SystemErrorID_t*');
    if length(e1) == 1
        te = e1(1).name(end-1:end);
        eval(['SystemErrorID = SystemErrorID_' te ';']);
        eval(['ExtID = ExtID_' te ';']);
        eval(['EventDrivenDataValue = EventDrivenDataValue_' te ';']);
        eval(['EventT = ' te ';']);
    else
        % There is no Event Driven data in the file, make them empty matricies
        SystemErrorID = [];
        ExtID = [];
        EventDrivenDataValue = [];
        EventT = [];
        obj.event.write(sprintf('No Event Driven Data in file %s',fullFileName))
        disp(['No Event Driven Data in file ' fullFileName]);
    end
    
    % MinMax data if it exists
    m1 = whos('PublicDataID_t*');
    if length(m1) == 1
        tm = m1(1).name(end-1:end);
        eval(['PublicDataID = PublicDataID_' tm ';']);
        eval(['MinMax_DataValue = MinMax_DataValue_' tm ';']);
        eval(['MinMaxT = ' tm ';']);
    else
        % There is no Min/Max data in the file, make them empty matricies
        PublicDataID = [];
        MinMax_DataValue = [];
        MinMaxT = [];
        obj.event.write(sprintf('No MinMax Data in file %s',fullFileName))
        disp(['No MinMax Data in file ' fullFileName]);
    end
    
    % systime_t* vector to assist in checking the timestamp values
    s1 = whos('systime_t*');
    if length(s1) == 1
        eval(['systime = ' s1(1).name ';'])
        eval(['SysT = ' s1(1).name(end-1:end) ';'])
    else
        % Since they don't exist, set them to empty vectors
        systime = [];
        SysT = [];
        % Warn that systime is missing, then not use it for checking the timestamp
        obj.warning.write('systime is missing, not using it to validate time stamps.');
        obj.event.write('systime is missing, not using it to validate time stamps.');
        disp(['Systime missing from file ' fullFileName]);
    end
    
    %% Calculate abs_time substitute from CANape inputs
    % This starts by calculating a datenum of the reference time in the .mat file
    % Then, it converts the values of the time-stamp (t0, t1, t2, etc.) from seconds to
    % fractional days and adds that to the reference datenum to get the finalized datenum
    abs_time_e = datenum(Date(1),Date(2),Date(3),Time(1),Time(2),Time(3)) + EventT/86400;
    abs_time_m = datenum(Date(1),Date(2),Date(3),Time(1),Time(2),Time(3)) + MinMaxT/86400;
    
    % Do sanity checks on the timestamps to make sure they are good
    
    % MAKE SURE TO SET THE ENDING DATE TO A DATE and TIME AFTER THE LAST FILE (ie,
    % midnight the next day)
    
    % Define a global minimum and maximum date for the data being processed
    % This will be the final rationality check
    % Winter Trip 2012 (Polar and Arctic)
	% minDate = datenum(2012,1,9); % January 9, 2012
	% maxDate = datenum(2012,5,1);  % May 1, 2012
    % Summer Pre-Trip 2012 (Verification)
    % minDate = datenum(2012,6,22); % June 22, 2012
    % maxDate = datenum(2012,7,6);  % July 6, 2012
    % Summer Trip 2012 (Aurora)
    % minDate = datenum(2012,7,20); % July 20, 2012
    % maxDate = datenum(2012,8,23);  % August 23, 2012
    % Winter Trip 2013
    % minDate = datenum(2013,1,21); % January 21, 2013
    % maxDate = datenum(2013,2,4,12,0,0);  % February 4, 2013 (last day was Feb 3)
    % Random Data From March 2013 to today
    minDate = datenum(2013,3,1); % March 1, 2013
    maxDate = datenum(2013,9,31);  % February 4, 2013 (last day was Feb 3)
    
    
    % If there is event driven data present in the file
    if ~isempty(abs_time_e)
        % If the scaling is totally off on the event driven time (covers > 910 seconds)
        if (EventT(end)-EventT(1)) > 910
            % If it's just the first timestamp messing everything up
            if (EventT(end)-EventT(2)) <= 910
                % We're fine, just trim the first value from the data
                abs_time_e = abs_time_e(2:end);
                EventT = EventT(2:end);
                SystemErrorID = SystemErrorID(2:end);
                ExtID = ExtID(2:end);
                EventDrivenDataValue = EventDrivenDataValue(2:end);
                % Write a line to the warning log that this happened
                obj.warning.write('Goofy timestamp of the first line of Event Driven data, dropping this point.');
            else
                % Throw an error, timestamp for event driven data is unrecoverable
                error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                    'Event Driven timestamp is unrecoverable as it spans %g seconds.',EventT(end)-EventT(1))
            end
        end
        % If systime is present to help validate the timestamp
        if ~isempty(systime)
            % If the starting timestamps of event driven data is more than 10 seconds before
            % systime or 10 seconds after systime (but the overall time covered is less than 910
            % seconds)
            if (SysT(1)-EventT(1) > 10) || (EventT(end)-SysT(end) > 10)
                % Attempt to offset the timestamps for event driven data
                offset = EventT(1) - SysT(1);
                % Recalculate a new abs_time vector with this offset. This new calculation will
                % then be checked below
                abs_time_e = datenum(Date(1),Date(2),Date(3),Time(1),Time(2),Time(3)) + (EventT-offset)/86400;
            end
            % Check starting event driven timestamp is not more than 16 seconds before systime
            if systime(1)-mod(abs_time_e(1),1)*86400 > 16
                % Throw a timestamp error for this file
                error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                    'The original or offest re-calculated Event Driven first timestamp is more than 16 seconds before the first systime value.')
            end
            % Check ending event driven timestamp is not more than 16 seconds after systime
            if mod(abs_time_e(end),1)*86400-systime(end) > 16
                % Throw an error
                error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                    'The original or offest re-calculated Event Driven last timestamp is more than 16 seconds after the last systime value.')
            end
        end
        % Finally, check if either of the abs_time vectors has any value outside the
        % specified global min and max range
        if any((abs_time_e < minDate) | (abs_time_e > maxDate))
            % Throw an error
            error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                'Found an instance of an Event Driven timestamp outside of the specified global range of %s to %s.',datestr(minDate),datestr(maxDate));
        end
    end
    
    % If there is Min/Max data present in the file
    if ~isempty(MinMaxT)
        % If the scaling is totally off on the min/max data timestamp
        
        % If it looks like there is just one key-off event in one file
        if length(MinMaxT) <= 1000
            % Check that the Min/Max timestamp covers less than 2 seconds
            if (MinMaxT(end)-MinMaxT(1)) > 2
                % If it's just the first entry throwing everything off when there is only one
                % data-set present
                if (MinMaxT(end)-MinMaxT(2)) <= 2
                    % Then we're ok, just trim the offending first data point
                    % Also trim the last one as practicle experiance tells me this is one of
                    % the odd data point written to the log file
                    abs_time_m = abs_time_m(2:end-1);
                    MinMaxT = MinMaxT(2:end-1);
                    PublicDataID = PublicDataID(2:end-1);
                    MinMax_DataValue = MinMax_DataValue(2:end-1);
                    % Write an entry into the warning log that two data points have been
                    % trimmed, one from the front and one from the back
                    obj.warning.write('Found instance of bad timestamp on first MinMax data point for one key-off event present, trimming first and last value.');
                else
                    % Throw an error, timestamp for min/max data is unrecoverable
                    error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                        'Min/Max timestamp is unrecoverable as it spans %g seconds.',MinMaxT(end)-MinMaxT(1))
                end
            end % else the delta < 2 and we're good to go, don't do anything
        else % length(MinMaxT) > 1000  % So there could be multiple key-off events captured
            % Check that the Min/Max timestep doesn't cover mare than 910 seconds (the
            % maximum in one file)
            if (MinMaxT(end)-MinMaxT(1)) > 910
                % If it's just the first entry throwing everything off when there is only one
                % data-set present
                if (MinMaxT(end)-MinMaxT(2)) <= 910
                    % Then we're ok, just trim the offending first data point
                    % Also trim the last one as practicle experiance tells me this is one of
                    % the odd data point written to the log file
                    abs_time_m = abs_time_m(2:end-1);
                    MinMaxT = MinMaxT(2:end-1);
                    PublicDataID = PublicDataID(2:end-1);
                    MinMax_DataValue = MinMax_DataValue(2:end-1);
                    % Write an entry into the warning log that two data points have been
                    % trimmed, one from the front and one from the back
                    obj.warning.write('Found instance of bad timestamp on first MinMax data point for more than one key-off event present, trimming first and last value.');
                else
                    % Throw an error, timestamp for min/max data is unrecoverable
                    error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                        'Min/Max timestamp is unrecoverable as it spans %g seconds.',MinMaxT(end)-MinMaxT(1))
                end
            end % else delta < 910 and we're good to go, don't do anything
        end
            
        % If systime is present to help validate the time stamp
        if ~isempty(systime)
            % Check that the Min/Max data timestamp is contained within starting and ending values
            % of system time
            if systime(1)-mod(abs_time_m(1),1)*86400 > 5 || mod(abs_time_m(end),1)*86400-systime(end) > 5
                % Check using the abs_time method additionally in case there was a date break in
                % the file
                if (abs_time_e(1)-abs_time_m(1))*86400 > 0.5 || (abs_time_m(end)-abs_time_e(end))*86400 > 0.5
                    % Then there is a bad time-stamp, attempt to re-calculate the abs_time vector 
                    % if there is an offset from the event driven data
                    if exist('offset','var')
                        % Recalculate the abs_time_m vector
                        abs_time_m = datenum(Date(1),Date(2),Date(3),Time(1),Time(2),Time(3)) + (MinMaxT-offset)/86400;
                    else
                        % No offset to use, skip the file
                        error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                            'Attempted to offset the MinMax timestamp but there was no offset present from the Event Driven data.')
                    end
                end
                % If the first condition fails but the second condition passes, then the original
                % time stamp is ok to use
            end
        end
        % Finally, check if either of the abs_time vectors has any values outside the
        % specified global min and max range
        if any((abs_time_m<minDate)|(abs_time_m>maxDate))
            % Throw an error
            error('CapabilityUploader:AddMiniMatFile:timestamp', ...
                'Found an instance of a Min/Max timestamp outside of the specified global range of %s to %s.',datestr(minDate),datestr(maxDate));
        end
    end
    
    %% Process Event Driven data
    % Initialize an output variable to dump values into
    numRecord = length(SystemErrorID);
    % This is what will get loaded into the database
    % 9 columns of data and as many rows as have data
    eventDecoded = cell(numRecord, 9);
    % Initalize the logical array to hold whether each line is excess data or not
    excessDataFlag(1:numRecord,1) = false;
    
    % Initalize the write index for the above vector
    writeIdxEvent = 1;
    
    %% Loop through data
    % If there is no EventDriven data, SystemErrorID will be empty and the loop won't run
    % The loop is kept for CANape data because the decodeEvent function can't take in
    % vectors
    for i = 1:length(SystemErrorID)
        % Calculate the SEID and ExtID
        Ext = ExtID(i);
        SEID = SystemErrorID(i);
        
        % If this was excess event driven data
        if isExcessEvent(SEID)
            % Flag whether or not this data point was excess event driven data or not
            excessDataFlag(writeIdxEvent) = true;
            % Don't decode it, just continue to the next loop itaration
            decodedData = NaN;
        else
            % Try to find a match for this xSEID
            try
                % Send this data into the decoder
                decodedData = obj.decodeEvent(SEID + Ext*65536, EventDrivenDataValue(i));
            catch ex
                % Failed to locate decoding information for this xSEID
                error('CapabilityUploader:AddMiniMatFile:EVDDInfoMissing', 'Failed to locate decoding information for SEID %0.f with ExtID %0.f = xSEID of %0.f with software %.0f',SEID,Ext,SEID + Ext*65536,cal);
            end
        end
        
        % Add the info to a new line of the eventDecoded cell array
        % colNames = {datenum, ECMRunTime, SEID, ExtID, DataValue, CalibrationVersion, TruckID, EMBFlag, TripFlag}
        eventDecoded(writeIdxEvent,:) = {abs_time_e(i), NaN, SEID, Ext, decodedData, cal, truckID, 0, tripFlag};
        
        % Increment the writeIdxEvent
        writeIdxEvent = writeIdxEvent + 1;
    end
    
    %% Write Event Driven data
    
    % Do this immeadiatly after writing the Min/Max data so that there is less chance of
    % an error in Min/Max processing causing a problem and only making this file half
    % uploaded
    
    %% Process MinMax data
    % Initalize the desired output of formatted MinMax data
    numelMinMaxData = length(PublicDataID);
    minMaxData = cell(numelMinMaxData, 10);
    % Set the starting write index
    minMaxWriteIdx = 1;
    
    %% Loop Through Data
    % Start at an index of 1
    idx = 1;
    % While not at the end of the MinMax data, keep searching for MinMax data sets
    while idx < numelMinMaxData
        % This will keep looping throught MinMax data looking for
        % MinMax data sets. To get here, you are at the start of
        % another key-off data broadcast event
        
        % Initalize values of MinMax set starting point
        setStartTime = MinMaxT(idx);       % Starting time of this MinMax set (used to identify next Min/Max set)
        setStartAbsTime = abs_time_m(idx); % Matlab datenumber of the timestamp that this data was broadcast
        setStartWriteIdx = minMaxWriteIdx; % Starting write index of this data set (used to set ConditionID aftward)
        
        % Make the ECM_Run_Time NaN for this set as it isn't avaiable in CANape data
        setECM_Run_Time = NaN;
        
        % While we haven't advanced more than 2 seconds in time looking for
        % data (best way to define a "MinMax set") (or have not passed the ending index)
        while (idx < numelMinMaxData) && (MinMaxT(idx)-setStartTime < 2);
            
            % Preform pair-matching to find the min and max values of each
            % If the current Public Data ID and next Public Data ID match
            if PublicDataID(idx) == PublicDataID(idx+1)
                % Get the public data id
                pdid = PublicDataID(idx);
                % Decode the matching values
                a = obj.decodeMinMax(pdid, MinMax_DataValue(idx), cal);
                b = obj.decodeMinMax(pdid, MinMax_DataValue(idx+1), cal);
                % Compare the values to ensure the Min and Max are identified correctly
                if b >= a
                    % a is the minimum and b is the maximum
                    % Create the entry in MinMax data here
                    minMaxData(minMaxWriteIdx,:) = {abs_time_m(idx), setECM_Run_Time, pdid, a, b, cal, truckID, [], 0, tripFlag};
                    % Increment the write idx
                    minMaxWriteIdx = minMaxWriteIdx + 1;
                else % b is the minimum and a is the maximum
                    % Create the entry in MinMax data here
                    minMaxData(minMaxWriteIdx,:) = {abs_time_m(idx), setECM_Run_Time, pdid, b, a, cal, truckID, [], 0, tripFlag};
                    % Increment the write idx
                    minMaxWriteIdx = minMaxWriteIdx + 1;
                    % Write an entry in the warning log that there was a case of backword
                    % parameters in the Min/Max data
                    obj.warning.write(sprintf('Case of Min/Max data being broadcast in reverse for parameter %.0f.',pdid));
                end
                % Increment the scan index by two because we matched a pair
                idx = idx + 2;
                
            else % Matching failed
                % Decode the single value
                pdid = PublicDataID(idx);
                a = obj.decodeMinMax(pdid, MinMax_DataValue(idx), cal);
                % Display a warning for this parameter
                % Try/catch statement in cast of error on getDataInfo when
                % Public Data ID is not in dib for a given cal
                try
                    obj.event.write(['Failed to find match for parameter ' obj.getDataInfo(pdid, cal, 'Data') ' - ' dec2hex(pdid)]);
                catch ex
                    obj.event.write(['Failed to find match for parameter UNKNOWN - ' dec2hex(pdid)]);
                end
                % Write the single value to both Min and Max and turn on the EMB flag
                minMaxData(minMaxWriteIdx,:) = {abs_time_m(idx), setECM_Run_Time, pdid, a, a, cal, truckID, [], 1, tripFlag};
                % Increment the write idx
                minMaxWriteIdx = minMaxWriteIdx + 1;
                
                % Only increment the scan index by one as only one value was used
                idx = idx + 1;
            end
            
        end % while looking for MinMax data in this set
        
        % mean MMM_Update_Rate cannot be calcualted from CANape data, set it to NaN
        meanMMM = NaN;
        % Create a new MinMax data condition for the key-off set
        conditionID = createMinMaxSet(obj, setStartAbsTime, setECM_Run_Time, cal, truckID, meanMMM, tripFlag);
        % Set this as the conditionId for the set just processed
        % From the starting write idx to one minus the current write idx
        minMaxData(setStartWriteIdx:(minMaxWriteIdx - 1), 8) = {conditionID};
        
        % We reached the end of the first set of MinMax data, loop
        % through again looking for more until you reach the end
        obj.event.write(['Create new MinMax set with an ID number of ' sprintf('%.0f', conditionID)]);
        
    end %while looking for MinMax sets
    
    %% Closing Checks
    % Known issues with above
    % If the last value of the MinMax data broadcast doesn't have a match after it, it 
    % will be lost.
    
    %% Write MinMax Data
    % Trim any excessive initalized rows
    minMaxData = minMaxData(1:minMaxWriteIdx-1,:);
    % Define upload column names
    colNames = {'datenum', 'ECMRunTime', 'PublicDataID', 'DataMin', 'DataMax', 'CalibrationVersion', 'TruckID', 'ConditionID', 'EMBFlag', 'TripFlag'};
    % If there was any Min/Max data present
    if size(minMaxData,1) > 0
        % Upload the data into the database
        fastinsert(obj.conn, '[dbo].[tblMinMaxData]', colNames, minMaxData);
        % Write a note of this to the event log
        obj.event.write(sprintf('Found %.0f minmax pairs', minMaxWriteIdx-1));
    end
    
    %% Write Event Driven data
    % Separate the data into two cell arrays, one with good data, one with excess data
    goodEventDecoded = eventDecoded(~excessDataFlag, :);
    %excessEventDecoded = eventDecoded(excessDataFlag, :);
    
    % Define Event Driven column names
    colNamesED = {'datenum', 'ECMRunTime', 'SEID', 'ExtID', 'DataValue', 'CalibrationVersion', 'TruckID', 'EMBFlag', 'TripFlag'};
    % If there was any good data in the file
    if size(goodEventDecoded,1) > 0
        startUpload = tic;disp('Tic - Uploading good event driven data to database.')
        % Upload the good Event Driven data to the database normally
        fastinsert(obj.conn, '[dbo].[tblEventDrivenData]', colNamesED, goodEventDecoded);
        toc(startUpload)
    end
    % Don't bother to upload the excessive event driven data
    
end

%% Create New MinMax Set ID number
% This will create a new MinMax set in tblMinMaxConditions and then return
% the id number of the newly created set
function setID = createMinMaxSet(obj, datenum, ECM_Run_Time, cal, truckID, meanMMM, tripFlag)
    
    % Create a new entry in the tblMinMaxDataConditions
    
    % Full column name definition
    %columns = {'datenum', 'ECMRunTime', 'CalibrationVersion', 'TruckID', 'dECMRunTime', 'dEngineRunTime', 'dOBDEngineRunTime', 'dTIVechileECMDistance', 'dTIVehicleEngineDistance', 'MMMUpdateRate', 'EMBFlag', 'TripFlag'};
    % Shortened list of columns of only data that will get uploaded
    colNames = {'datenum', 'ECMRunTime', 'CalibrationVersion', 'TruckID', 'MMMUpdateRate', 'EMBFlag', 'TripFlag'};
    % Make the line of data
    data = {datenum, ECM_Run_Time, cal, truckID, meanMMM, 0, tripFlag};
    % Create a new MinMax condition line
    fastinsert(obj.conn, '[dbo].[tblMinMaxDataConditions]', colNames, data);
    
    % Select the Id number matching the recently uploaded set
    % Since the ConditionID column is an auto-incrememtned 
    fetchData = fetch(obj.conn, 'SELECT Max([ConditionID]) AS ConditionID FROM [dbo].[tblMinMaxDataConditions]');
    
    % Old method that mathced various columns to locate the ConditionID
    % This method had the benefit of returning multiple conditionIDs when duplicate
    % Min/Max data was added into the database, but if an error happens after a
    % conditionID was created but before the MinMax data was uploaded, there could
    % potentially be two conditionIDs, but one is unused in reality
    % Also, this method has a failure chance as the SQL server Round function rounds 5
    % down and Matlab's sprintf rounds up. If the 7th digit is a 5, this code fails to
    % work properly, otherwise it is fairly solid.
%     if isnan(ECM_Run_Time)
%         fetchData = fetch(obj.conn, ['SELECT ConditionID FROM tblMinMaxDataConditions WHERE ROUND(datenum,6) = ' sprintf('%.6f',datenum) ' And FLOOR(ECMRunTime) Is Null And TruckID = ' sprintf('%.0f',truckID) ' And CalibrationVersion = ' sprintf('%.0f',cal)]);
%     else
%         fetchData = fetch(obj.conn, ['SELECT ConditionID FROM tblMinMaxDataConditions WHERE ROUND(datenum,6) = ' sprintf('%.6f',datenum) ' And FLOOR(ECMRunTime) = ' sprintf('%.0f',floor(ECM_Run_Time)) ' And TruckID = ' sprintf('%.0f',truckID) ' And CalibrationVersion = ' sprintf('%.0f',cal)]);
%     end
    
    % Check for valid output
    if ~isempty(fetchData)
        % Data exists, check for more than one
        if length(fetchData.ConditionID) > 1
            %%% NOT POSSIBLE TO GET HERE WITH THE ABOVE REVISED FETCH CALL
            % Throw an error because there is duplicate data being added
            setID = max(fetchData.ConditionID); % for development purposes, return the largest value
%             error('CapabilityUploader:processMinMaxSet:createMinMaxSet:duplicateSetFound', ...
%                 ['Duplicate MinMax sets found for truck ' sprintf('%.0f',truckID) ...
%                 ' with datenum ' sprintf('%.11f', datenum) ' and cal ' sprintf('%.0f',cal) ...
%                 ', likely this file was already uploaded into the database.']);
        else
            % Set the return output
            setID = max(fetchData.ConditionID); % Doing max as a carryover from when this would deal with duplicate MinMax sets in a quite way
        end
    else % Failed to fetch the correct line for the condition ID, return data was empty
        % Print a warning
        disp(['Failed to get setID for Truck ' num2str(truckID) ' and cal ' num2str(cal) ' and ECM_Run_Time' sprintf('%.1f',ECM_Run_Time) ' and date ' datestr(datenum, 'mm-dd-yy_HH-MM-SS.FFF') '.']);
        % Log this event
        obj.event.write(['CapabilityUploader:AddMiniMatFile:createMinMaxSet:failedToGetSetID - ', ...
            'Failed to get the setID for the newly created MinMax data condition on truckID ' sprintf('%.0f', truckID) ...
            ' at timestamp ' datestr(datenum, 'mm-dd-yy_HH-MM-SS.FFF') ' with datenum ' sprintf('%.11f',datenum) ...
            ' for calibration ' sprintf('%.0f', cal)]);
        obj.error.write(['CapabilityUploader:AddMiniMatFile:createMinMaxSet:failedToGetSetID - ', ...
            'Failed to get the setID for the newly created MinMax data condition on truckID ' sprintf('%.0f', truckID) ...
            ' at timestamp ' datestr(datenum, 'mm-dd-yy_HH-MM-SS.FFF') ' with datenum ' sprintf('%.11f',datenum) ...
            ' for calibration ' sprintf('%.0f', cal)]);
        % Return a NaN so this is set to null in the database
        setID = NaN;
    end
end

%% Excess Event Driven Data Checker
function b = isExcessEvent(SEID)
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
    b = any(SEID==[2085 3284 5990 5051 5988 5987 7450 7451 6098 6099 7289 7290 6095 ...
                   6094 6097 6096 7813 7815 7814 7816 7818 7820 7819 7821 7822 7824 ...
                   7823 7825 6100 6101 6102 6103 ...
                   2896 2897 2898 2899 6981 6982 6996 7286 8291 8293 8680 8681 8682 ...
                   8683 8687 8688 8689 8690 8691 8692 8693 8694 8695]);
end
