% % For MR, there are a million folders so define program + folder here
% programs = {
%     % Seahawk
%     'Seahawk','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Seahawk\FieldTest_Alpha';
%     'Seahawk','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Seahawk\FieldTest_Dragnet';
%     'Seahawk','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Seahawk\FieldTest_Production';
%     % DragonCC
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_VP';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_PS-A';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_JOB1';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_FDV2';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_FDV3';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_FDV4';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_FDV5';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_Prod';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_Proto';
%     'DragonCC','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_Dragnet';
%     % DragonMR
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\FieldTest_Alpha';
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\FieldTest_Beta';
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\CurrentProduct';
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\Control_Trucks';
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\FieldTest_Production';
%     'DragonMR','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Dragon\FieldTest_Dragnet';
%     % Yukon
%     'Yukon','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Yukon\FieldTest_Alpha';
%     'Yukon','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Yukon\FieldTest_Beta';
%     'Yukon','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Yukon\Control_Trucks';
%     'Yukon','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Yukon\FieldTest_Dragnet';
%     % This is needed to catch two vehicles in the main Yukon folder
%     'Yukon','\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Yukon';
% };

% Recurse one level through the program directory folders on MR because the data is everywhere
base = '\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata';
% Program names as in the database
prog =     {'DragonCC',   'DragonMR', 'Seahawk', 'Yukon' ,'Nighthawk', 'Sierra'};
% Program names as in the mrdata folder
progFold = {'DragonFront','Dragon',   'Seahawk', 'Yukon' ,'Nighthawk', 'Sierra'};
% Empty variable to hold all the driectories
programs = {};
for i = 1:length(prog)
    % Add the base directory
    programs = [programs;prog(i),{fullfile(base,progFold{i})}];
    % Find one level deeper of folder names
    nextLevel = dir(fullfile(base,progFold{i}));
    % Keep only the directories
    nextLevel = nextLevel(cell2mat({nextLevel(:).isdir}));
    % Loop through each folder (excluding . and ..)
    for j = 3:length(nextLevel)
        % Add each to the program folders to look through
        programs = [programs;prog(i),{fullfile(base,progFold{i},nextLevel(j).name)}];
    end
end

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
            % Make a moveToFolder if it doesn't exist already
            if ~exist(moveToFolder,'dir'), mkdir(moveToFolder), end
            % Add this to the summation
            totalMoved = totalMoved + x;
            % Copy to processed folder first
            copyfile([currentFolder '\*.csv*'],copyToFolder);
            % Move the MinMax files to ETD_Data
            try
                movefile([currentFolder '\*.csv*'],moveToFolder);
            catch
                continue
            end
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
        
        % For each mid folder found
        % Skip Mid folders for now
        for k = []%1:length(midFolders)
            
            % Caclulate the current folder and copy folder
            currentFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles',midFolders{k});
            copyToFolder = fullfile(rawDataDir,truckName,'RawCSVFiles\Min-Max data\ProcessedFiles',midFolders{k},'archived');
            
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
        end
    end
end
% Display finished message
fprintf('Finished! Moved a total of %.0f files from the RawData directory.\r',totalMoved);
