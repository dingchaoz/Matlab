function filesWaiting(obj)
%Count number of files that are currently unprocessed for the current enging program
%   This will display on the screen the number of files that are unprocessed for each
%   truck in the current engine program in addition to a program total.
%   
%   Usage: filesWaiting(obj)
%   
%   Inputs -  None
%   
%   Outputs - None
%   
%   Original Version - January 13, 2014
%   Revised - N/A - N/A
    
    % Calculate the start directory of the data
    if strcmp(obj.program,'HDPacific')
        % Override HDPacific to be the Pacific folder
        startDir = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\Pacific';
    else
        % Use the program name for all the rest
        startDir = ['\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\' obj.program];
    end
    
    % Look for all truck folders that exist
    truckDirData = dir(startDir);
    % Create of list of trucks with folders of data
    truckList = {truckDirData(3:end).name}';
    
    % Initalize the file counts
    filesWaiting = 0;  % Files waiting that have never been before been processed
    
    % For each truck that has data
    for i = 1:length(truckList)
        % Get the number of file waiting for this truck
        %x = length(dir(fullfile(startDir, truckList{i}, '*.csv*')));
        x = length(dir(fullfile(startDir, truckList{i}, '*Max*.csv*')));
        %x = length(dir(fullfile(startDir, truckList{i}, '*MinMax*.csv*')));
        %x = length(dir(fullfile(startDir, truckList{i}, '*.exp.xml')));
        % Only display the vehicles if files were present
        if x > 0
            % Display the number of files waiting for this truck
            fprintf('Files waiting for truck %- 33s - %.0f\n',truckList{i},x)
        end
        % Add it to the total amount
        filesWaiting = filesWaiting + x;
    end
    
    % Display the results
    fprintf('----------------------------------------------------------------\n')
    fprintf('Files Waiting:    %0.f\n',filesWaiting)
    
end
