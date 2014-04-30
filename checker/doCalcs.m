% Read in a MinMax .csv file, then do some data quality calcuations on it
% and return the finalized results

function stats = doCalcs(fileName)
    
    % Read in the file
    tic;
    readCaltermIII_EcmDataOnly(fileName);
    fileReadTime = toc;
    
    %% Bit Shift the SEID fields for LDD data (comment out for big-endian ECMs)
    idxFix = cellfun(@length,EventDriven_xSEID)>3;
    
    EventDriven_xSEID(idxFix) = cellfun(@(x) x([7 8 5 6 3 4 1 2]),EventDriven_xSEID(idxFix),'UniformOutput',false);
    
    % If the name of calibration version was mis-spelled
    if exist('i_calibration_version','var')
        i_Calibration_Version = i_calibration_version;
    end
    
    %% Evalueate Event Driven Data
    
    % Find the ECM_Run_Time over which the file was taken
    minECM_Run_Time = min(ECM_Run_Time(~isnan(ECM_Run_Time)));
    maxECM_Run_Time = max(ECM_Run_Time(~isnan(ECM_Run_Time)));
    x = diff(ECM_Run_Time(~isnan(ECM_Run_Time)));
    oddDiffECM_Run_Time = x(x<0|x>50)';
    
    % Find the number of event driven paramerers
    % TODO - add abiility to create a new list of event driven data without
    % NaNs to a master listing of event driven system errors can be created
    % for the purpose of counting how oftan each is broadcast
    numEventParams = 0;
    for i = 1:length(EventDriven_xSEID)
        if ~strcmp(EventDriven_xSEID{i}, 'NaN')
            % This line isn't a NaN, conut it
            numEventParams = numEventParams + 1;
        end
    end
    
    % Calculate the average number of parameters broadcast per second
    numEventParamsPerSecond = numEventParams / (maxECM_Run_Time - minECM_Run_Time);
    
    % Find the number of unique event driven system errors broadcast
    % Do for both Event sets b/c of the .cbf file mix-up
    % uniqueA is the long-term correct method, SEID stored in ID tag
    % Try that first. Upon failure, rollover to UniqueB
    uniqueA = unique(EventDriven_xSEID);
    %uniqueB = unique(EventDriven_xSEID);
    % Define starting point
    numUniqueSEID = 0;
    
    % Find unique SEIDs present in uniqueA
    for i=1:(length(uniqueA)-1)
%         % If the first three are '000', this is the system error data.
%         if strcmp(uniqueA{i}(1:3),'000')
%             % If extId is zero, this is a base SEID
            if uniqueA{i}(4)=='0'
                % count it
                numUniqueSEID = numUniqueSEID +1;
            end
%         else % uniqueA was actually real data, rollover to the uniqueB list
%             % Reset the numUniqueSEID counter
%             numUniqueSEID = 0;
%             % Restart another fox loop for uniqueB
%             for j = 1:(length(uniqueB)-1)
%                 % If extId is zero, this is a base SEID
%                 if uniqueB{j}(4)=='0'
%                     % count it
%                     numUniqueSEID = numUniqueSEID +1;
%                 end
%             end
%             % Instead set the unique list to list B 
%             stats.uniqueList = uniqueB;
%             % Break out of the original loop
%             break
%         end
    end
    
    % If stats.uniqueList isn't set, set it to uniqueA
    if ~exist('stats', 'var')
        stats.uniqueList = uniqueA;
    end
    
    %% Evaluate the MinMax data
    currentIdx = 1;
    % Define the output
    minMaxSets = [];
    
    while currentIdx <= length(MinMax_PublicDataID)
        
        % Look for the start of a MinMax dump
        if ~strcmp(MinMax_PublicDataID{currentIdx}, 'NaN')
            % If the value isn't a NaN, set this as the starting index
            startTime = tod(currentIdx);
            countMinMaxParams = 1;
            
            % Increment the current idx, move on to the next value
            currentIdx = currentIdx + 1;
            
            % Now keep looking father for more data
            % While we aren't at the end of the file
            % Nor did we advance more than 2 seconds in time
            while currentIdx <= length(MinMax_PublicDataID) && ...
                    tod(currentIdx) < (startTime + 2)
                % If the line isn't a NaN, count it as MinMax data
                if ~strcmp(MinMax_PublicDataID{currentIdx}, 'NaN')
                    countMinMaxParams = countMinMaxParams + 1;
                end
                % Increment the current index to move to the next line
                currentIdx = currentIdx + 1;
            end
            
            % Now that we looked 2 seconds after the initial MinMax,
            % We should have counted an entire set
            % Append the number of parameters found for this set
            minMaxSets = [minMaxSets countMinMaxParams];
        end
        
        % Increment the current index
        currentIdx = currentIdx + 1;
    end
    
    %% Uniuqe software versions present
    if exist('i_Calibration_Version','var')
        stats.cal = i_Calibration_Version;
    else
        stats.cal = {'Not Logged'};
    end
    
    %% Put the variables into the return structure
    stats.ECMTime = maxECM_Run_Time - minECM_Run_Time;
    stats.oddDiff = oddDiffECM_Run_Time;
    stats.todTime = tod(end) - tod(1);
    stats.numEventParams = numEventParams;
    stats.numEventParamsPerSecond = numEventParamsPerSecond;
    stats.minMaxSets = minMaxSets;
    stats.numMinMaxSets = length(minMaxSets);
    stats.fileReadTime = fileReadTime;
    stats.lines = length(ECM_Run_Time);
    stats.numUniqueSEID = numUniqueSEID;
    
end
