%% Day File Calculator
% Takes the input of a mat file, reads it in, calculates some quality
% statistics, then returns the results

function stats = dayFileCalculator(fileName)
    %% Read in the file
    
    % Try to read in the file
    try
        load(fileName)
    catch
        % Upon failure, print a message to the council
        fprintf('Failed to load in file: %s\r\n', fileName);
        % Exit the rountine, don't return any data
        return
    end
    
    %% Calcualtions
    % With a file loaded, do some calculations for each screen file
    
    %% Screen 0
    % Find the unique instances of diff(ECM_Run_Time)
    stats.Screen0.uniqueDiffECM = str2double(unique(cellstr(num2str(unique(diff(ECM_Run_Time)),'%.1f'))))';
    % Show only overt offenders > 2.0 or < 0.0
    stats.Screen0.diffECM = stats.Screen0.uniqueDiffECM(stats.Screen0.uniqueDiffECM > 2.0 | stats.Screen0.uniqueDiffECM < 0);
    % Find the mean of diff(ECM_Run_Time) for non NaN values less than 300
    %x = diff(ECM_Rum_Time);
    %stats.Screen0.meanDiffECM = mean(x(~isnan(x)));
    
    %% 200ms
    if exist('ECM_Run_Time_200ms', 'var')
        % Find the unique instances of diff(ECM_Run_Time_200ms)
        stats.ms200.uniqueDiffECM = str2double(unique(cellstr(num2str(unique(diff(ECM_Run_Time_200ms)),'%.1f'))))';
        % Show only overt offenders > 1.0 or < 0.0
        stats.ms200.diffECM = stats.ms200.uniqueDiffECM(stats.ms200.uniqueDiffECM > 1.0 | stats.ms200.uniqueDiffECM < 0);
    else
        stats.ms200.uniqueDiffECM = NaN;
        stats.ms200.diffECM = NaN;
    end
    
    %% 1000ms
    % Find the unique instances of diff(ECM_Run_Time_1000ms)
    stats.ms1000.uniqueDiffECM = str2double(unique(cellstr(num2str(unique(diff(ECM_Run_Time_1000ms)),'%.1f'))))';
    % Show only overt offenders > 2.0 or < 0.0
    stats.ms1000.diffECM = stats.ms1000.uniqueDiffECM(stats.ms1000.uniqueDiffECM > 2.0 | stats.ms1000.uniqueDiffECM < 0);
    
    %% 1000msOBD
    % Find the unique instances of diff(ECM_Run_Time_1000msOBD)
    stats.ms1000OBD.uniqueDiffECM = str2double(unique(cellstr(num2str(unique(diff(ECM_Run_Time_1000msOBD)),'%.1f'))))';
    % Show only overt offenders > 2.0 or < 0.0
    stats.ms1000OBD.diffECM = stats.ms1000OBD.uniqueDiffECM(stats.ms1000OBD.uniqueDiffECM > 2.0 | stats.ms1000OBD.uniqueDiffECM < 0);
    
    %% 5000ms
    try % In the case that the 5000ms screen isn't present
        % Find the unique instances of diff(tod_5000ms)
        stats.ms5000.uniqueDiffECM = str2double(unique(cellstr(num2str(unique(diff(tod_5000ms)),'%.1f'))))';
        % Show only overt offenders > 10.0 or < 0.0
        stats.ms5000.diffECM = stats.ms5000.uniqueDiffECM(stats.ms5000.uniqueDiffECM > 10.2 | stats.ms5000.uniqueDiffECM < 0);
    catch
        stats.ms5000.uniqueDiffECM = NaN;
        stats.ms5000.diffECM = NaN;
    end
    
    %% Do screen-independent calculations
    % Total Key Switch count
    stats.keySwitchDiff = max(Key_Off_Count) - min(Key_Off_Count);
    
    % Find length deviations
    if exist('tod_5000ms','var') && exist('ECM_Run_Time','var') % In case 5000ms is missing
        screenLengths = [length(ECM_Run_Time) length(ECM_Run_Time_200ms)/5 length(ECM_Run_Time_1000ms) length(ECM_Run_Time_1000msOBD) length(tod_5000ms)*5];
        stats.deviation = std(screenLengths) / mean(screenLengths) * 100;
        % Calculate how much data is lost compared to the best screen of data (in %)
        bestScreen = max(screenLengths);
        stats.Screen0.lost = (bestScreen - screenLengths(1)) / bestScreen * 100;
        stats.ms200.lost = (bestScreen - screenLengths(2)) / bestScreen * 100;
        stats.ms1000.lost = (bestScreen - screenLengths(3)) / bestScreen * 100;
        stats.ms1000OBD.lost = (bestScreen - screenLengths(4)) / bestScreen * 100;
        stats.ms5000.lost = (bestScreen - screenLengths(5)) / bestScreen * 100;
    elseif exist('ECM_Run_Time_200ms','var') && ~exist('tod_5000ms','var')
        % 5000ms is missing, drop those calculations
        screenLengths = [length(ECM_Run_Time) length(ECM_Run_Time_200ms)/5 length(ECM_Run_Time_1000ms) length(ECM_Run_Time_1000msOBD)];
        stats.deviation = std(screenLengths) / mean(screenLengths) * 100;
        % Calculate how much data is lost compared to the best screen of data (in %)
        bestScreen = max(screenLengths);
        stats.Screen0.lost = (bestScreen - screenLengths(1)) / bestScreen * 100;
        stats.ms200.lost = (bestScreen - screenLengths(2)) / bestScreen * 100;
        stats.ms1000.lost = (bestScreen - screenLengths(3)) / bestScreen * 100;
        stats.ms1000OBD.lost = (bestScreen - screenLengths(4)) / bestScreen * 100;
        stats.ms5000.lost = NaN;
    elseif ~exist('ECM_Run_Time_200ms','var') && exist('tod_5000ms','var')
        % 200 ms is missing, drop those calculations
        screenLengths = [length(ECM_Run_Time) NaN length(ECM_Run_Time_1000ms) length(ECM_Run_Time_1000msOBD) length(tod_5000ms)*5];
        stats.deviation = std(screenLengths(~isnan(screenLengths))) / mean(screenLengths(~isnan(screenLengths))) * 100;
        % Calculate how much data is lost compared to the best screen of data (in %)
        bestScreen = max(screenLengths);
        stats.Screen0.lost = (bestScreen - screenLengths(1)) / bestScreen * 100;
        stats.ms200.lost = NaN;
        stats.ms1000.lost = (bestScreen - screenLengths(3)) / bestScreen * 100;
        stats.ms1000OBD.lost = (bestScreen - screenLengths(4)) / bestScreen * 100;
        stats.ms5000.lost = (bestScreen - screenLengths(5)) / bestScreen * 100;
    elseif ~exist('ECM_Run_Time_200ms','var') && ~exist('tod_5000ms','var')
        % Both 5000ms and 200ms are missing
        screenLengths = [length(ECM_Run_Time) NaN length(ECM_Run_Time_1000ms) length(ECM_Run_Time_1000msOBD)];
        stats.deviation = std(screenLengths(~isnan(screenLengths))) / mean(screenLengths(~isnan(screenLengths))) * 100;
        % Calculate how much data is lost compared to the best screen of data (in %)
        bestScreen = max(screenLengths);
        stats.Screen0.lost = (bestScreen - screenLengths(1)) / bestScreen * 100;
        stats.ms200.lost = NaN;
        stats.ms1000.lost = (bestScreen - screenLengths(3)) / bestScreen * 100;
        stats.ms1000OBD.lost = (bestScreen - screenLengths(4)) / bestScreen * 100;
        stats.ms5000.lost = NaN;
    else
        error('Either Screen 0, 1000ms, or 1000msOBD is missing.')
    end
    
    % Module Off Times
    stats.ModuleOffTime = unique(Module_Off_Time');
    
    
end
