%% Define program + folder here
programs = {
    % Vanguard
    'Vanguard','\\CIDCSDFS01\EBU_Data01$\NACEPx\LDD Test Data\LDD Vehicle Integration\Vehicle Test Data\Viking Data\Vanguard';
    % Ventura
    'Ventura','\\CIDCSDFS01\EBU_Data01$\NACEPx\LDD Test Data\LDD Vehicle Integration\Vehicle Test Data\Viking Data\Ventura';
};

%% MR Way that did 2 levels automatically
% % Recurse one level through the program directory folders on MR because the data is everywhere
% base = '\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata';
% % Program names as in the database
% prog =     {'DragonCC',   'DragonMR', 'Seahawk', 'Yukon'};
% % Program names as in the mrdata folder
% progFold = {'DragonFront','Dragon',   'Seahawk', 'Yukon'};
% % Empty variable to hold all the driectories
% programs = {};
% for i = 2:length(prog)
%     % Add the base directory
%     programs = [programs;prog(i),{fullfile(base,progFold{i})}];
%     % Find one level deeper of folder names
%     nextLevel = dir(fullfile(base,progFold{i}));
%     % Keep only the directories
%     nextLevel = nextLevel(cell2mat({nextLevel(:).isdir}));
%     % Loop through each folder (excluding . and ..)
%     for j = 3:length(nextLevel)
%         % Add each to the program folders to look through
%         programs = [programs;prog(i),{fullfile(base,progFold{i},nextLevel(j).name)}];
%     end
% end

% Cumulative total of files moved starts at zero
totalMoved = 0;

% For each program
for i = 1:size(programs,1)
    
    % Generate the root directories for the two different file types from the program name
    destDir = ['\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\' programs{i,1} '\'];
    rawDataDir = programs{i,2};
    
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
        moveToFolder = fullfile(destDir,truckName);
        currentFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data');
        copyToFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\archived');
        
        % Look for MinMax files the cheater way for now do all .csv files
        files = dir([currentFolder '\*Max*.csv*']);
        %files = dir([currentFolder '\*.csv*']);
        x = length(files);
        % If any Cuty files were present
        if x > 0
            % Make a copyToFolder if it doesn't exist already
            if ~exist(copyToFolder,'dir'), mkdir(copyToFolder), end
            % Make a copyToFolder if it doesn't exist already
            if ~exist(moveToFolder,'dir'), mkdir(moveToFolder), end
            % Add this to the summation
            totalMoved = totalMoved + x;
            % Copy to processed folder first
            copyfile([currentFolder '\*.csv*'],copyToFolder);
            % Move the MinMax files to ETD_Data
            movefile([currentFolder '\*.csv*'],moveToFolder);
            % Display a message
            fprintf('Moved % 3.0f files from %s to %s\r',x,currentFolder,moveToFolder);
        else
            % There were no Min/Max files present, display a message
            fprintf('No MinMax files in     %s\r',currentFolder);
        end
        
        % Get the listing of all the processed folders
        %midFolderData = dir(fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles'));
        %midFolders = {midFolderData(3:end).name}';
        %midFolders = midFolders(cell2mat({midFolderData(3:end).isdir}'));
        
        % Skip mid folders
        
        % For each mid folder found
        for k = []%1:length(midFolders)
            
            % Caclulate the current folder and copy folder
            currentFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles',midFolders{k});
            %copyToFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles',midFolders{k},'archived');
            % Use shorter name because I am getting file system error for directroy paths that are too long
            copyToFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles',midFolders{k},'a');
            
            % Look for MinMax files the cheater way for now do all .csv files
            %files = dir([currentFolder '\*Min*.csv*']);
            files = dir([currentFolder '\*.csv*']);
            x = length(files);
            % If any Cuty files were present
            if x > 0
                % Make a copyToFolder if it doesn't exist already
                if ~exist(copyToFolder,'dir'), mkdir(copyToFolder), end
                % Make a copyToFolder if it doesn't exist already
                if ~exist(moveToFolder,'dir'), mkdir(moveToFolder), end
                % Add this to the summation
                totalMoved = totalMoved + x;
                try
                    % Copy to processed folder first
                    copyfile([currentFolder '\*.csv*'],copyToFolder);
                catch ex
                    % Look if any files were LCDvXXXX_ twice thus longer than 67 characters
                    if any(cellfun(@length,{files(:).name}') > 67)
                        % Shorten the names
                        for z = find(cellfun(@length,{files(:).name}') > 67)'
                            % If the name has 'LCDv' twice
                            if length(strfind(files(z).name,'LCDv')) > 1
                                % Rename the file eliminating the first 21 characters
                                movefile(fullfile(currentFolder,files(z).name),fullfile(currentFolder,files(z).name(21:end)))
                            else
                                % Unknown problem
                                error('asdf:asdf','Unknown problem with file name length')
                            end
                        end
                        % Try to move again
                        copyfile([currentFolder '\*.csv*'],copyToFolder);
                    else
                        % Rethrow the original exception as the error is unknown
                        rethrow(ex)
                    end
                end
                % Move the MinMax files to ETD_Data
                movefile([currentFolder '\*.csv*'],moveToFolder);
                % Display a message
                fprintf('Moved % 3.0f files from %s to %s\r',x,currentFolder,moveToFolder);
            else
                % There were no Min/Max files present, display a message
                fprintf('No MinMax files in     %s\r',currentFolder);
            end
        end
    end
end
% Display finished message
fprintf('Finished! Moved a total of %.0f files from the RawData directory.\r',totalMoved);
