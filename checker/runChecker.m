%% Capability Data Checking Script
% Take in a root directory, read in each .csv file.
% Evaluate the quality of the data and write to a log file
% fileName influences the name of the file to be written

function runChecker(rootDir, fileName)
    %% Definitions - antiquated
    
    startTime = now;
    
    % Root file directory
    %fileName = 'Accepts_Test_3';
    %rootDir = 'D:\Matlab\Capability\QualityCheck\Accepts\csv\';
    
    %% Get the File Listing
    % Get the directory listing
    dirData = dir(fullfile(rootDir,'*.csv*'));
    
    % Initialize
    fileList = cell([length(dirData)-2, 1]);
    
    % Create a cell array of strings with full file path names
    for i = 1:length(dirData)
        fileList{i} = fullfile(rootDir, dirData(i).name);
    end
    
    % Open the log file for writing
    fid = fopen([fileName '.csv'],'w');
    
    % Write header line
    fprintf(fid, '%s\r\n', 'MinMax Data Qualty Checking Results');
    fprintf(fid, '%s\r\n\r\n', 'Chris Remington - je113');
    % Column headers
    fprintf(fid, 'File Name,Read Time,Lines,tod Seconds,ECM_Run_Time Seconds,Evt Dat Pts,Evt Dat/s,Unique SEID,MinMax Sets,MinMax Num Params,Odd diff(ECM_Run_Time)\r\n');
    
    % Initalize a blank list to contain a master list of unique system
    % errors the broadcast data over all files analized.
    masterUniqueList = {};
    masterCalList = {};
    
    % Counter for the number of bad files
    numBadFiles = 0;
    
    % Read in each file, do the calculations, white results to the log file
    for i = 1:length(fileList)
        % Separate into function b/c the .csv reader is going to violate my
        % memory space
        
        % Try to do the calculations (file read may fail for this particular
        % file)
        try
            stats = doCalcs(fileList{i});
        catch ex
            % increase the number of bad files
            numBadFiles = numBadFiles + 1;
            fprintf(fid,'%s,Error\r\n', fileList{i});
            disp(['Error on file ' fileList{i} '.']);
            disp(getReport(ex));
            continue
        end
        
        % Append a line to the log file with the stats of this file
        fprintf(fid, '%s,%.3f,%f,%.0f,%.0f,%.0f,%f,%f,%f,%s,%s\r\n', fileList{i}, stats.fileReadTime, stats.lines, stats.todTime, stats.ECMTime, stats.numEventParams, stats.numEventParamsPerSecond, stats.numUniqueSEID, stats.numMinMaxSets, num2str(stats.minMaxSets), ['''' num2str(stats.oddDiff)]);
        
        % Append to the master list of unique system errors over all files
        masterUniqueList = [masterUniqueList; stats.uniqueList];
        
        % Append to the master list of cals
        masterCalList = [masterCalList; stats.cal];
        
    end
    
    %% Print xSEIDs present
    % Recalculate the final unique list
    masterUniqueList = unique(masterUniqueList);
    % Convert to base10 system errors
    masterUniqueList = hex2dec(char(masterUniqueList(1:end-1)));
    %masterUniqueList = masterUniqueList(masterUniqueList < 65535);
    
    % Print the total number of unique system errors over all files
    fprintf(fid, 'Total number of unique xSEIDs present: %.0f\r\n', length(masterUniqueList));
    %fprintf(fid, 'SEID,Count of Data')
    % For each unique system error
    for i = 1:length(masterUniqueList)
        % Print the SEID %%%%and it's frequency
        fprintf(fid, '%.0f\r\n', masterUniqueList(i));
    end
    % Blank line
    fprintf(fid,'\r\n');
    
    %% Print the software versions present
    % Get unique listing
    masterCalList = unique(masterCalList);
    
    % Print the total number of unique system errors over all files
    fprintf(fid, 'Software versions present: %.0f\r\n', length(masterCalList));
    % For each unique cal
    for i = 1:length(masterCalList)
        % Print the SEID %%%%and it's frequency
        fprintf(fid, '%s\r\n', masterCalList{i});
    end
    % Blank line
    fprintf(fid,'\r\n');
    
    %% Finishing
    % Finish by closing the log file
    fprintf(fid, '%s\r\n', 'End.');
    fclose(fid);
    
    % Print the entire job time to the council window
    fprintf('Time to run the entire job: %.3f seconds.\r\n', (now - startTime)*24*60*60);
    
end
