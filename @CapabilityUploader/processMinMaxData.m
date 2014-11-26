function processMinMaxData(obj, abs_time, ECM_Run_Time, MMM_Update_Rate, MinMax_PublicDataID, MinMax_Data, cal, truckID)
%Takes inpus from a parsed .csv file and returns processed MinMax sets
%   This is designed to encapsulate the MinMax logic and remove it from the
%   AddCSVFile to enable it to be better maintainded
%   
%   Usage: processMinMaxData(obj, abs_time, ECM_Run_Time, MMM_Update_Rate, ...
%                             MinMax_PublicDataID, MinMax_Data, cal, truckID)
%   
%   Input  ---
%   abs_time:            The abs_time vector resulting from reading in a .csv file
%   ECM_Run_Time:        The vector of ECM_Run_Time from the .csv file
%   MMM_Update_Rate:     Vector of MMM_Update_Rate data from the .csv file or empty set
%   MinMax_PublicDataID: Vector of MinMax Public Data Ids
%   MinMax_DataID:       Vector of MinMax data values
%   cal:                 Numeric version of the cal version that the data was taken with
%   truckID:             ID number of the truck that data was taken from
%   
%   Outputs ---
%   minMaxData:          Cell array of data ready to be upladed to the database
%   minMaxConditions:    MinMax data conditions
%   
%   Original Version - Chris Remington - ~January 26, 2012
%   Revised - Chris Remington - August 1, 2012
%       - Modified the last column name in the tblMinMaxData and tblMinMaxDataConditions
%         table from 'DevFlag' to 'TripFlag' to give it better meaning. This code will now
%         default that value to zero as the .csv files are from Calterm loggers that are
%         generally not used on test trips
%   Revised - Chris Remington - October 2, 2013
%       - Added ability for MMM_Update_Rate to be an empty set to the Mean of
%         MMM_Update_Rate will be added to the database as a null, this is to support
%         screen files that don't contain this non-essential parameter
%       - In the future maybe add a method to update the MMM_Update_Rate of each file
%         processed or the latest file processed in the database
%   Revised - Chris Remington - April 3, 2014
%       - Disabled the flag that assumes ECM_Run_Time is always at the start of a set of 
%         Min/Max data
%   Revised - Chris Remington - April 30, 2014
%       - Revised to calculate the next set id value by selecting the largest and adding 
%         one instead of relying on the identity column to compute that value. Since the 
%         ConditionID column is a primary key, any attempt to upload a previously used 
%         value will throw an error before any MinMax data can be loaded into the database
%   Revised - Yiyuan Chen - 2014/11/25
%       - Modified the usage of decodeMinMax.m and thus added one more input (publicIDmatch) 
%         and one more output (embflag) to identify what problem caused datavalue to be set to NaN
%       (if PublicIDs match and are valid, decodedData is valid and EMBFlag is 0;
%        if PublicIDs match but data is AAAA (invalid publicID), decodedData is NaN and EMBFlag is 0;
%        if PublicIDs match but data is non-AAAA (invalid publicID), decodedData is NaN and EMBFlag is set to 1;
%        if PublicIDs don't match but are valid, decodedData is valid and EMBFlag is set to 1;
%        if PublicIDs don't match and are invalid, decodedData is NaN and EMBFlag is set to 1, 
%           which however won't get uploaded;)
    
    %% Initalize
    % Get the indicies of the valid MinMax data
    idxMinMaxOnly = find(~strncmp('N',MinMax_PublicDataID,1));
    % Strip out the MinMax data and assosiated abs_time values
    %onlyMinMax_PublicDataID = MinMax_PublicDataID(idxOnlyMinMax);
    %onlyMinMax_Data = MinMax_Data(idxOnlyMinMax);
    %onlyMinMax_abs_time = abs_time(idxOnlyMinMax);
    numelMinMaxData = length(idxMinMaxOnly);
    
    % Initalize the desired output or MinMax data
    minMaxData = cell(length(idxMinMaxOnly), 10);
    minMaxWriteIdx = 1;
    
    %% Loop Through Data
    % Start looking at the data with an index of 1
    idx = 1;
    
    % While not at the end of the MinMax data, keep searching for
    % MinMax data sets
    while idx < numelMinMaxData
        % This will keep looping throught MinMax data looking for
        % MinMax data sets. To get here, you are at the start of
        % another key-off data broadcast event
        
        % Initalize values of MinMax set starting point
        setStartIdx = idxMinMaxOnly(idx);      % i.e., 1, then 58 after encountering 57 data points, etc.
        setStartTime = abs_time(setStartIdx);  % Starting datenum of this MinMax set
        setStartWriteIdx = minMaxWriteIdx;     % Starting write index of this data set
        setStartPosition = idx;                % Used to tell if after more then 6 lines into a set we encounter a new set before 4 seconds
        
        % Get the last known ECM_Run_Time before this MinMax data was broadcast
        try
            setECM_Run_Time = getSetECM_Run_Time(ECM_Run_Time, idxMinMaxOnly(idx));
        catch ex
            % If there were datalink problems that caused the ECM_Run_Time to not be found
            % in the 50 lines before the first Min/Max line in this set
            if strcmp(ex.identifier, 'CapabilityUploader:processMinMaxData:getSetECM_Run_Time:CannotLocateECMRunTime')
                % Force the setECM_Run_Time to be a NaN so that is will be uploaded into
                % the database as a null value
                setECM_Run_Time = NaN;
                % Log an entry in the warning log
                obj.warning.write('Failed to find an ECM_Run_Time for a Min/Max dataset, setting to NaN instead.');
            else
                % Rethrow the original exception, as some other unknown error happened.
                rethrow(ex)
            end
        end
        
        % While we haven't advanced more than 5 seconds in time looking for
        % data (best way to define a "MinMax set") (or have not passed the ending index)
        while (idx < numelMinMaxData) && (abs(abs_time(idxMinMaxOnly(idx))-setStartTime) < 5/86400);
            
            % Preform pair-matching to find the min and max values of each
            % Translate the indicies and set the current global idx
            globalIdx = idxMinMaxOnly(idx);
            globalIdx1 = idxMinMaxOnly(idx+1);
            
            % First, if we're more then six lines into this set
            if idx - setStartPosition > 5
                % Double check to see if we encountered a new Min/Max set
                % before 5 seconds is up by looking for another line
                % containing ECM_Run_Time (which is broadcast first)
                
                % Disabling this now that more programs are being processed and they don't
                % all have ECM_Run_Time as the first parameter in the overlay
                if 0%strcmp(MinMax_PublicDataID{globalIdx}, '00005A30')
                    % This is a new set of MinMax data before 5 seconds is up
                    % Don't increment idx, don't decode, break out of this
                    % loop to initiate new new MinMax set
                    break
                end
            end
            
            % If the current Public Data ID and next Public Data ID match
            if strcmp(MinMax_PublicDataID{globalIdx}, MinMax_PublicDataID{globalIdx1})
                % Get the public data id and decode both values
                publicDataID = hex2dec2(MinMax_PublicDataID{globalIdx});
                publicIDmatch = 1;
                % Don't need a little-endian check here because the public data id will get broadcast in big-endian format on a little-engine ECM
                [a, emb_a] = obj.decodeMinMax(publicDataID, MinMax_Data{globalIdx}, cal, publicIDmatch);
                [b, emb_b] = obj.decodeMinMax(publicDataID, MinMax_Data{globalIdx1}, cal, publicIDmatch);               
                % Define the EMBFlag value for this pair
                if emb_a == emb_b
                else % this should not happen but in case
                   obj.event.write(sprintf('One value is AAAA while the other one is not, for parameter %.0f.',publicDataID)); 
                end
                embflag = max(emb_a,emb_b);
                
                % Compare the values to ensure the Min and Max are identified correctly
                if b >= a || (isnan(a) && isnan(b))
                    % a is the minimum and b is the maximum
                    % Create the entry in MinMax data here
                    minMaxData(minMaxWriteIdx,:) = {abs_time(globalIdx), setECM_Run_Time, publicDataID, a, b, cal, truckID, [], embflag, 0};
                    % Increment the write idx
                    minMaxWriteIdx = minMaxWriteIdx + 1;
                else % b is the minimum and a is the maximum
                    % Create the entry in MinMax data here
                    minMaxData(minMaxWriteIdx,:) = {abs_time(globalIdx), setECM_Run_Time, publicDataID, b, a, cal, truckID, [], embflag, 0};
                    % Increment the write idx
                    minMaxWriteIdx = minMaxWriteIdx + 1;
                    % Write an entry in the warning log that there was a case of backword
                    % parameters in the Min/Max data
                    obj.warning.write(sprintf('Case of Min/Max data being broadcast in reverse for parameter %.0f.',publicDataID));
                    % This can be erroneously written to the warning log in the rare case
                    % that there are only two entries of Min/Max data, one each from a
                    % different key-off event. If each entry of Min/Max data happens to be
                    % the same parameter, the Min/Max logic will blindly compare the
                    % current parameter id to the next one without checking the advance in
                    % time. Out of 135,00 files so far, this has been seen 3 times.
                end
                % Increment the index by two because we matched a pair
                idx = idx + 2;
                
            else % Matching failed
                % Decode the single value
                publicDataID = hex2dec2(MinMax_PublicDataID{globalIdx});
                publicIDmatch = 0;
                [a, embflag] = obj.decodeMinMax(publicDataID, MinMax_Data{globalIdx}, cal, publicIDmatch);
                % Display a warning for this parameter
                % Try/catch statement in cast of error on getDataInfo when
                % Public Data ID is not in dib for a given cal
                try
                    obj.event.write(['Failed to find match for parameter ' obj.getDataInfo(publicDataID, cal, 'Data') ' - ' dec2hex(publicDataID)]);
                catch ex
                    obj.event.write(['Failed to find match for parameter UNKNOWN - ' dec2hex(publicDataID)]);
                end
                
                if ~isnan(a)
                    % Write the single value to both Min and Max and turn on the EMB flag if value is not NaN
                    minMaxData(minMaxWriteIdx,:) = {abs_time(globalIdx), setECM_Run_Time, publicDataID, a, a, cal, truckID, [], embflag, 0}; 
                    % Increment the write idx
                    minMaxWriteIdx = minMaxWriteIdx + 1;
                else % Skip if data value is even NaN while match fails
                    obj.event.write(['Skipped the data, whose value is also NaN while PublicDataID ' dec2hex(publicDataID) ' fails to match']);
                end
                
                % Only increment the index by one
                idx = idx + 1;
            end
            
        end % while looking for MinMax data in this set
        
        % If MMM_Update rate was present in the log file
        if ~isempty(MMM_Update_Rate)
            % Calculate the mean MMM_Update_Rate
            meanMMM = mean(MMM_Update_Rate(~isnan(MMM_Update_Rate)));
        else
            % Set this to a NaN so it will be null in the database
            meanMMM = NaN;
        end
        
        % Create a new MinMax data condition for the key-off set
        conditionID = createMinMaxSet(obj, setStartTime, setECM_Run_Time, cal, truckID, meanMMM);
        
        % Set this as the conditionId for the set just processed
        % From the starting write idx to one minus the current write idx
        minMaxData(setStartWriteIdx:(minMaxWriteIdx - 1), 8) = {conditionID};
        
        % We reached the end of the first set of MinMax data, loop
        % through again looking for more until you reach the end
        obj.event.write(['Create new MinMax set with an ID number of ' sprintf('%.0f', conditionID)]);
        
    end %while looking for MinMax sets
    
    %% Closing Checks
    % Check that we didn't end and forget about the last orphan
    % parameter at the end or check if there is only one value present
    if idx == 1
        %--  If there was one and only one piece of MinMax data, do some things over again in here
        % Set starting time
        setStartTime = abs_time(idxMinMaxOnly(idx));
        
        % Find the setECM_Run_Time because the while loop never ran
        try
            setECM_Run_Time = getSetECM_Run_Time(ECM_Run_Time, idxMinMaxOnly(idx));
        catch ex
            % If there were datalink problems that caused the ECM_Run_Time to not be found
            % in the 50 lines before the first Min/Max line in this set
            if strcmp(ex.identifier, 'CapabilityUploader:processMinMaxData:getSetECM_Run_Time:CannotLocateECMRunTime')
                % Force the setECM_Run_Time to be a NaN so that is will be uploaded into
                % the database as a null value
                setECM_Run_Time = NaN;
                % Log an entry in the warning log
                obj.warning.write('Failed to find an ECM_Run_Time for a Min/Max dataset, setting to NaN instead.');
            else
                % Rethrow the original exception, as some other unknown error happened.
                rethrow(ex)
            end
        end
        
        % If MMM_Update rate was present in the log file
        if ~isempty(MMM_Update_Rate)
            % Calculate the mean MMM_Update_Rate
            meanMMM = mean(MMM_Update_Rate(~isnan(MMM_Update_Rate)));
        else
            % Set this to a NaN so it will be null in the database
            meanMMM = NaN;
        end
        % Create a new MinMax data condition for the key-off set
        conditionID = createMinMaxSet(obj, setStartTime, setECM_Run_Time, cal, truckID, meanMMM);
        
        %--- Do this code which is identical to the elseif code
        % Decode the single value
        publicDataID = hex2dec2(MinMax_PublicDataID{idxMinMaxOnly(idx)});
        publicIDmatch = 0;
        [a, embflag] = obj.decodeMinMax(publicDataID, MinMax_Data{idxMinMaxOnly(idx)}, cal, publicIDmatch);
        % Display a warning for this parameter
        % Try/catch statement in cast of error on getDataInfo when
        % Public Data ID is not in dib for a given cal
        try
            obj.event.write(['Failed to find match for parameter ' obj.getDataInfo(publicDataID, cal, 'Data') ' - ' dec2hex(publicDataID) ' - This is an orphan at the end of the file.']);
        catch ex
            obj.event.write(['Failed to find match for parameter UNKNOWN - ' dec2hex(publicDataID) ' - This is an orphan at the end of the file.']);
        end
        
        if ~isnan(a)
            % Write the single value to both Min and Max and turn on the EMB flag
            minMaxData(minMaxWriteIdx,:) = {abs_time(idxMinMaxOnly(idx)), setECM_Run_Time, publicDataID, a, a, cal, truckID, [], embflag, 0};
            % Special addition here becuase we already assigned ConditionID's to
            % the other parameters in this set, do it here special for this
            % last one (assosiate with lask known MinMax set)
            minMaxData{minMaxWriteIdx, 8} = conditionID;
            % Increment the write idx
            minMaxWriteIdx = minMaxWriteIdx + 1;
        else % Skip if data value is even NaN while match fails
            obj.event.write(['Skipped the only data, whose value is also NaN while PublicDataID ' dec2hex(publicDataID) 'fails to match']);
        end
        
    elseif idx == numelMinMaxData
        % If we're exactly on the last element, that means it cannot
        % have a match at the end, take this into account
        
        % Decode the single value
        publicDataID = hex2dec2(MinMax_PublicDataID{idxMinMaxOnly(idx)});
        publicIDmatch = 0;
        [a, embflag] = obj.decodeMinMax(publicDataID, MinMax_Data{idxMinMaxOnly(idx)}, cal, publicIDmatch);
        % Display a warning for this parameter
        % Try/catch statement in cast of error on getDataInfo when
        % Public Data ID is not in dib for a given cal
        try
            obj.event.write(['Failed to find match for parameter ' obj.getDataInfo(publicDataID, cal, 'Data') ' - ' dec2hex(publicDataID) ' - This is an orpan at the end of the file.']);
        catch ex
            obj.event.write(['Failed to find match for parameter UNKNOWN - ' dec2hex(publicDataID) ' - This is an orpan at the end of the file.']);
        end
        
        if ~isnan(a)
            % Write the single value to both Min and Max and turn on the EMB flag
            minMaxData(minMaxWriteIdx,:) = {abs_time(idxMinMaxOnly(idx)), setECM_Run_Time, publicDataID, a, a, cal, truckID, [], embflag, 0};
            % Special addition here becuase we already assigned ConditionID's to
            % the other parameters in this set, do it here special for this
            % last one (assosiate with lask known MinMax set)
            minMaxData{minMaxWriteIdx, 8} = conditionID;
            % Increment the write idx
            minMaxWriteIdx = minMaxWriteIdx + 1;
        else % Skip if data value is even NaN while match fails
            obj.event.write(['Skipped the last data, whose value is also NaN while PublicDataID ' dec2hex(publicDataID) 'fails to match']);
        end
    end
    
    %% Write Data
    % Trim any excessive initalized rows
    minMaxData = minMaxData(1:minMaxWriteIdx-1,:);
    % Define upload column names
    colNames = {'datenum', 'ECMRunTime', 'PublicDataID', 'DataMin', 'DataMax', 'CalibrationVersion', 'TruckID', 'ConditionID', 'EMBFlag', 'TripFlag'};
    % Upload the data into the database
    fastinsert(obj.conn, '[dbo].[tblMinMaxData]', colNames, minMaxData);
    obj.event.write(['Found ' num2str(minMaxWriteIdx-1,'%.0f') ' minmax pairs']);
    
end

%% Create New MinMax Set ID number
% This will create a new MinMax set in tblMinMaxConditions and then return
% the id number of the newly created set
function setID = createMinMaxSet(obj, datenum, ECM_Run_Time, cal, truckID, meanMMM)
    
    % Create a new entry in the tblMinMaxDataConditions table
    % Revised to calculate the next set id value instead of relying on the identity column
    
    % Select the current largest condition id
    fetchData = fetch(obj.conn, 'SELECT Max([ConditionID]) AS ConditionID FROM [dbo].[tblMinMaxDataConditions]');
    
    % If no data was returned and this is the first data-set upload to the database
    if isempty(fetchData) || isnan(fetchData.ConditionID)
        % Start the id number at 1
        setID = 1;
    else
        % Add 1 to the existing largest number
        setID = fetchData.ConditionID + 1;
    end
    
    % Full column name definition
    %columns = {'datenum', 'ECMRunTime', 'CalibrationVersion', 'TruckID', 'dECMRunTime', 'dEngineRunTime', 'dOBDEngineRunTime', 'dTIVechileECMDistance', 'dTIVehicleEngineDistance', 'MMMUpdateRate', 'EMBFlag', 'TripFlag'};
    % Shortened list of columns of only data that will get uploaded
    colNames = {'ConditionID','datenum', 'ECMRunTime', 'CalibrationVersion', 'TruckID', 'MMMUpdateRate', 'EMBFlag', 'TripFlag'};
    % Assemble the line of data to add to the database
    data = {setID, datenum, ECM_Run_Time, cal, truckID, meanMMM, 0, 0};
    % Upload the data with the new, largest condition id value
    fastinsert(obj.conn, '[dbo].[tblMinMaxDataConditions]', colNames, data);
    
end

%% Search backward throguh ECM_Run_Time for the newest update
% This is needed to assosiate the last known ECM_Run_Time with an entire
% set of MinMax data
% Takes in entire ECM_Run_Time array and an idex in it to start looking
% backward in ECM_Run_Time at
function setECM_Run_Time = getSetECM_Run_Time(ECM_Run_Time, startLookingIdx)
        if startLookingIdx - 50 > 0
            % Look up to 50 lines in the past
            for i = startLookingIdx:-1:(startLookingIdx-50)
                % If this line isn't a NaN
                if ~isnan(ECM_Run_Time(i))
                    % Set it as the ECM_Run_Time of the set and break
                    setECM_Run_Time = ECM_Run_Time(i);
                    break
                end
            end
        else % We're less than 50 lines in, look up until the begining
            for i = startLookingIdx:-1:1
                % If this line isn't a NaN
                if ~isnan(ECM_Run_Time(i))
                    % Set it as the ECM_Run_Time of the set and break
                    setECM_Run_Time = ECM_Run_Time(i);
                    break
                end
            end
        end
        % If setECM_Run_Time wasn't found in the file, throw an error
        if ~exist('setECM_Run_Time', 'var')
            % This means that the datalink dropped completely on this data
            error('CapabilityUploader:processMinMaxData:getSetECM_Run_Time:CannotLocateECMRunTime', 'processMinMax - Could not locate ECM_Run_Time within the first 50 lines of the .csv file.');
        end
end
