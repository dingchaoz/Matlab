%%% Programs to upload matfiles
%% Dingchao Zhang -- 01/06/2016

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
prog =     {'DragonCC',   'DragonMR', 'Seahawk', 'Yukon' ,'Nighthawk'};
% Program names as in the mrdata folder
progFold = {'DragonFront','Dragon',   'Seahawk', 'Yukon' ,'Nighthawk'};
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
    

    rawDataDir = programs{i,2};
    
    %% Get truck folder listing
    % Get the directory information
    FolderData = dir(rawDataDir);
    List = {FolderData(3:end).name}';
    List = List(cell2mat({FolderData(3:end).isdir}'));
    
    % Pull out the folder names and create full paths
    for j = 1:length(List)
        % Set the truck name
        folderName = List{j};
        
        parentFolder = fullfile(rawDataDir,folderName);
        truckFolderData = dir(parentFolder);
        truckList = {truckFolderData(3:end).name}';
        truckList = truckList(cell2mat({truckFolderData(3:end).isdir}'));
        
        % Look for MinMax files the cheater way for now do all .csv files
        
        currentFolder = fullfile(parentFolder,truckList,'MatData_Files');
        
        for i = 1:length(currentFolder)
            
            subFolders = dir(char(currentFolder(i)));
            subList = {subFolders(3:end).name}';
            subList = subList(cell2mat({subFolders(3:end).isdir}'));
            % a check if the folder is already processed, remove the
            % previous folders and only process the latest folders
            matFolder = fullfile(char(currentFolder(i)),subList);
            
            for j = 1: length(matFolder)
                
                files = dir([char(matFolder(j)) '\*.mat*']);
                
                % a check needs to be done to only process the unprocessed
                % files by retriveing information from database
                
                % Then call a function to read, upload each individual
                % file, probably need another for loop
                   x = length(files);
                    % If any Cuty files were present
                    if x > 0
            %            
                       fprintf('there are mat files    %s\r',char(matFolder(j)));
                    else
                        % There were no Min/Max files present, display a message
                        fprintf('No mat files in     %s\r',char(matFolder(j)));
                    end    
            end    
            
        end    
     
        
       
    end
end
% Display finished message
fprintf('Finished! Moved a total of %.0f files from the RawData directory.\r',totalMoved);
