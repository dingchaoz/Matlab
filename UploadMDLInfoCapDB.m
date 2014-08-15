function UploadMDLInfoCapDB(fileName)
%This will update 3-step owner names for the iupr data process
%   This will upload the 3-step owner names to the correct database for each program on
%   the capability data server.
%   
%   Usage: UploadMDLInfoCapDB(fileName)
%          UploadMDLInfoCapDB()
%   
%   Inputs ---
%   fileName: (optional) Full path of an mdl file
%   
%   Outputs --- None
%   
%   Original Version - Chris Remington - June 5, 2012
%   Modified - Chris Remington - May 22, 2013
%     - Converted from OBD Capability process to load the data and store it in mat files
%   Modified - Chris Remington - August 5, 2013
%     - Modified so this will upload to the IUPR data server
%   Modified - Yiyuan Chen - 2014/08/15
%     - Modified to upload Acadia's info to CapabilityDB
    
    %% Preliminary Error Checking
    
    % If no file name or an empty name was passed in, open a prompt to select a file
    if ~exist('fileName','var') || isempty(fileName)
        %         [fname,pathname] = uigetfile('N:\DL_Diag\OBD\Master Diagnostic List (MDL)\Apex MDL 3 step\*.xlsm','Select MDL');
        pathname = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\OBD\Master Diagnostic List (MDL)\Apex MDL 3 step';
        d = dir('\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\OBD\Master Diagnostic List (MDL)\Apex MDL 3 step\*.xlsm');
        dates = [d.datenum];
        [~, newfile] = max(dates);
        if strcmp('~$', d(newfile).name(1:2))
            Name = d(newfile).name(3:end);
        else
            Name = d(newfile).name;
        end
        fileName = fullfile(pathname, Name);
        disp(['File that is being processed : - ', fileName])
    end
    
    % If the file specified does not exist
    if ~exist(fileName, 'file')
        % Bad file name specified, throw an error
        error('SQLBasics:AddMDL:FileDoesNotExist', 'File name specified does not exist: %s', fileName);
    end
    
    %% Read in and format the raw data
    % Keep track of time for reading and processing
    tic
    disp('Starting file read and data formatting...')
    
    % Read in everything from the 3-step tab using xlsread (keep only the raw data)
    %[~, ~, raw] = xlsread(fileName, '3S Milestones');
    %[~, ~, raw] = xlsread(fileName, '3S_Milestones_Tab(1)');
    [~, ~, raw] = xlsread(fileName);
    
   % Check whether the bottom rows of MDL are all NaN from the last row
    lastrow=cellfun(@isnan,raw(end,:),'UniformOutput',false);
    j=0;
    
    % If the last row is NaN, drop it and check the one above it as the last one until a non-NaN row 
    while sum(cell2mat(lastrow))==length(lastrow)
        j=j+1;
        lastrow=cellfun(@isnan,raw(end-j,:),'UniformOutput',false);
    end
    
    % Sort the data on the system error name column
    raw = [raw(1,:);sortrows(raw(2:end-j,:),3)];
    
    % Convert any numbers to string and any empty values ([]) or NaNs to empty strings
    for i = 1:numel(raw)
        % If the cell contains a numeric value that isn't a NaN
        % This takes care of some MCID and AlgID columns
        if isnumeric(raw{i}) && ~sum(isnan(raw{i}))
            % Convert it to a string
            raw{i} = num2str(raw{i});
        % If the cell contains an empty double or a NaN
        elseif ~ischar(raw{i}) && (isempty(raw{i}) || isnan(raw{i}))
            % Change it to an empty string
            raw{i} = '';
        end
    end
    
    % Get rid of the _NoCD on the end of some of the system errors
    for i = 2:size(raw,1)
        % If the last 5 characters of the system error name are _NoCD
        if strcmp(raw{i,3}(end-4:end),'_NoCD')
            % Trim this from the end of the system error
            raw{i,3} = raw{i,3}(1:end-5);
        end
    end
    
    % Display time to read and process the data
    toc
    
    assignin('caller','raw',raw)
    % DEBUG - use this to put out the program header names and their starting columns
    %programColNumers = [num2cell(12:9:size(raw,2))',raw(1,12:9:end)']
    
    %% Define MDL mapping to use for each engine program of MDL data
    
Programs = {'Dragnet X1 2015','Dragnet B 2015','Dragnet PU 2015','Dragnet CC 2015','Dragnet L 2015','Vanguard'...
    ,'Ventura','Pele/Zico','Acadia X1'};
Database = {'Pacific','DragonMR','Seahawk','DragonCC','Yukon','Vanguard',...
    'Ventura','Pele','Acadia'};
[~,s] = size(Programs);
for count = 1:s
    a = cellfun(@(x) strcmp(Programs{count},x), raw(1,:));
    if sum(a) ==0
        col(count) = NaN;
        fprintf('\rSkipping MDL upload of %s\r',Programs{count})
    else
        col(count)= find(a==1);
    end % if sum(a) ==0
    
end % for count = 1:s
for i = 1:length(col)
    if ~isnan(col(i))
        uploadProgram(raw, col(i), Database{i})
    end % if ~isnan(col(i))
end % for i = 1:length(col)


end

function uploadProgram(raw, col, program)
%Export a certain engine program of MDL info from the full MDL loaded into Matlab
%   
%   
    
    % Display what is going to be exported
    fprintf('\rDefined Engine Program folder: %s\r',program)
    fprintf('Specified MDL Column:          %s\r',raw{1,col})
    % Ask if this is correct
    result = input('Is this correct? [y]/n: ','s');
    % Default is that it's ok (enpty string), otherwise if it's not that or a y
    if ~isempty(result) && ~strcmp('y',result)
        % Skip this truck
        disp('Skipping this program.')
        return
    end
    
    % Get the indexes for all the Non-N columns
    idx = ~strcmp('N',raw(:,col))&~strcmp('',raw(:,col));
    % Ignore the header column by setting it to false
    idx(1) = false;
    
    % Extract the mdl error table id
    mdl.Error_Table_ID = floor(str2double(raw(idx,2)));
    % Extract system error names
    mdl.Error_Name = raw(idx,3);
    % Extract the 8-step owner names
    mdl.Owner8Step = raw(idx,10);
    % Extract the 8-step team names
    mdl.Team8Step = raw(idx,9);
    % Extract the MDL Flag
    mdl.Purpose = raw(idx,col);
    % Extract the 3-step owner names
    mdl.Owner3Step = raw(idx,col+2);
    % Extract the 3-step team names
    mdl.Team3Step = raw(idx,col+1);
    
    % Check for duplicate system errors
    if length(mdl.Error_Name) ~= length(unique(mdl.Error_Name))
        % Give a warning
        warning('UploadMDLInfo:uploadProgram:duplicateErrors',...
            'The program %s contains duplicate system errors marked as ''Y'' in the MDL so the %s',...
            raw{1,col},...
            'MDL information cannot be updated in the database and this program is being skipped.')
    else
        % Open database connection
        programm = Capability(program);
        
        % Delete the existing MDL data
        curs = exec(programm.conn, 'DELETE FROM [dbo].[tblMDLInfo]');
        close(curs)
        clear curs
        
        % Insert the new data into the database
        fastinsert(programm.conn,'[dbo].[tblMDLInfo]',fields(mdl),mdl);
    end
end
