% Move LDD Pele Capabilty data from the Pele file share into the HD ETD_Data file share

% Define programs
programs = {'Pele'}; % 'Arayton'

% Cumulative total of files moved starts at zero
totalMoved = 0;

% For each program
for i = 1:length(programs)
    
    % Generate the root directories for the two different file types from the program name
    destDir = ['\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\' programs{i} '\'];
    rawDataDir = ['\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_css\LDB_Euro6\ETD_Data\MinMaxData\' programs{i}];
    
    %% Get truck folder listing
    % Get the directory information
    truckFolderData = dir(rawDataDir);
    truckList = {truckFolderData(3:end).name}';
    truckList = truckList(cell2mat({truckFolderData(3:end).isdir}'));
    
    % Pull out the folder names and create full paths
    for j = 1:length(truckList)
        % Set the truck name
        truckName = truckList{j};
        
        % Generate the name of the current and moveTo folder
        currentFolder = fullfile(rawDataDir,truckName);
        copyToFolder = fullfile(rawDataDir,truckName,'processed');
        moveToFolder = fullfile(destDir,truckName);
        % Look for MinMax files
        files = dir([currentFolder '\*MinMax*.csv*']);
        x = length(files);
        % If any MinMax files were present
        if x > 0
            % Make a copyToFolder if it doesn't exist already
            if ~exist(copyToFolder,'dir'), mkdir(copyToFolder), end
            % Make a copyToFolder if it doesn't exist already
            if ~exist(moveToFolder,'dir'), mkdir(moveToFolder), end
            % Add this to the summation
            totalMoved = totalMoved + x;
            % Copy to processed folder first
            copyfile([currentFolder '\*MinMax*.csv*'],copyToFolder);
            % Move the MinMax files to ETD_Data
            movefile([currentFolder '\*MinMax*.csv*'],moveToFolder);
            % Display a message
            fprintf('Moved % 3.0f files from %s to %s\r',x,currentFolder,moveToFolder);
            % Display a message, print the names of each file
            for k = 1:length(files)
                %fprintf('%s\r',files(k).name);
            end
        else
            % There were no Min/Max files present, display a message
            fprintf('No MinMax files in     %s\r',currentFolder);
        end
    end
end
% Display finished message
fprintf('Finished! Moved a total of %.0f files from the RawData directory.\r',totalMoved);
