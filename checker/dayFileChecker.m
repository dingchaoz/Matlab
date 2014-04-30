%% Day File Quality Checker
% Read in matlab day files and evaluate the quality of the data



%% Definintions

% Root directory where the .mat files are stored
rootDir = 'D:\Matlab\Capability\QualityCheck\DanTraditionalData';
% File Name (sans .csv extension)
fileName = 'Run_4';

%% Initalize Log File

% Open file for writing, clear its contents
fid = fopen([fileName '.csv'], 'w');

% Print a header line to the file with the date and time
fprintf(fid, 'Day File Quality Checker Output Log File\r\nGenerated: %s\r\n\r\n', datestr(now));
% Print the column headers
fprintf(fid, 'File Name,Len Dev %%,KS Cycles,Module Off Times,%% 200ms Lost,%% Screen0 Lost,%% 1000ms Lost,%% 1000msOBD Lost,%% 5000ms Lost,200ms ECM Diff,Screen0 ECM Diff,1000ms ECM Diff,1000msOBD ECM Diff,5000ms tod Diff\r\n');

%% Get File Listing

% Get the directory listing
dirData = dir(rootDir);

% Initialize
fileList = cell([length(dirData)-2, 1]);

% Create a cell array of strings with full file path names
for i = 3:length(dirData)
    fileList{i-2} = fullfile(rootDir, dirData(i).name);
end



%% Do the calculations for each file

% For each mat day file found
for i = 1:length(fileList)
    
    % Try to call the calculator function and get the stats
    try
        tic;stats = dayFileCalculator(fileList{i});toc
    catch % On failue, log this and move to the next file
        fprintf(fid, '%s,Error\r\n', fileList{i}(length(rootDir)+2:end));
        disp(['Failure on: ' fileList{i}(length(rootDir)+2:end)]);
        % Skip to the next loop itaration
        continue
    end
    
    % File Name
    % Length Deviation %%
    % Key Switch Cycles
    % Module Off Times
    % %% 200ms Lost
    % %% Screen0 Lost
    % %% 1000ms Lost
    % %% 1000msOBD Lost
    % %% 5000ms Lost
    % 200ms ECM Diff
    % Screen0 ECM Diff
    % 1000ms ECM Diff
    % 1000msOBD ECM Diff
    % 5000ms tod Diff
    
    % Write the stats to the file - start with global parameters
    fprintf(fid, '%s,%.2f,%.0f,%s,', fileList{i}(length(rootDir)+2:end), stats.deviation, stats.keySwitchDiff, num2str(stats.ModuleOffTime));
    % Then do the percent lost rates
    fprintf(fid, '%.2f,%.2f,%.2f,%.2f,%.2f,', stats.ms200.lost, stats.Screen0.lost, stats.ms1000.lost, stats.ms1000OBD.lost, stats.ms5000.lost);
    % Finish with the diff(ECM_Run_Time) values
    fprintf(fid, '%s,%s,%s,%s,%s\r\n', num2str(stats.ms200.diffECM), num2str(stats.Screen0.diffECM), num2str(stats.ms1000.diffECM), num2str(stats.ms1000OBD.diffECM), num2str(stats.ms5000.diffECM));
    
end


%% Close Log File


fprintf(fid, 'End.');
fclose(fid);
