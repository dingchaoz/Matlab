function recordsAdded = addMDL(obj, fileName, ver)
%This will append a newly released MDL into the tblMDL table in the database
%   This allows a record to be kept over all versions of the MDL that exist to more easily
%   allow one to look at changes to particular system errors over many different releases
%   of the MDL.
%   
%   Usage: recordsAdded = addMDL(obj, fileName, ver)
%          recordsAdded = addMDL(obj, [], ver)
%          recordsAdded = addMDL(obj, fileName)
%          recordsAdded = addMDL(obj)
%   
%   Inputs ---
%   fileName: (optional) Full path of an error_table file
%   cal:      (optional) The cal version of that file (in numeric format)
%   
%   Outputs --- returns the number of records uploaded to the database
%   
%   Original Version - Chris Remington - June 5, 2012
%   Revised - N/A - N/A
    
    %% Preliminary Error Checking
    
    % If no file name or an empty name was passed in, open a prompt to select a file
    if ~exist('fileName','var') || isempty(fileName)
        [fname,pathname] = uigetfile('*.xlsm','Select MDL');
        fileName = fullfile(pathname, fname);
    end
    
    % If no calibration version or an empty was passed in, prompt for a release version
    if ~exist('ver','var') || isempty(ver)
        %cal = inputdlg('Enter the software version for the specified file:','Datainnbuild.csv Information',1);
        ver = input('Please enter the MDL release version (in X.X.X.X format): ', 's');
    end
    
    % If the file specified does not exist
    if ~exist(fileName, 'file')
        % Bad file name specified, throw an error
        error('Capability:addMDL:FileDoesNotExist', 'File name specified does not exist: %s', fileName);
    end
    
    % Check if there is already data from this MDL release version
    d = fetch(obj.conn, sprintf('SELECT [SEName] FROM [tblMDL] WHERE [version] = ''%s''', ver));
    % If the return dataset is not empty, there was already data present for this cal
    if ~isempty(d)
        % Write a line to the command window
        fprintf('There are already %.0f records present in the database for MDL release version %s\r',length(d.SEName),ver)
        % Set an error noting this condition
        error('Capability:addMDL:RecordsAlreadyExist', ...
            'There are already %.0f records present in the database for MDL release version %s', ...
            length(d.SEName),ver)
    end
    
    %% Read in the raw data file
    % Keep track of time for reading and processing
    tic
    disp('Starting file read')
    
    % Read in everything from the 3-step tab using xlsread (keep only the raw data)
    [~, ~, raw] = xlsread(fileName, '3S Milestones');
    
    %% Format the data into a single matrix
    
    % Get the column listing of columns to keep from the 3-step tab and their name
    cols = setCols;
    
    % Initalize the output matrix (one less row than the raw data to get rid of the header
    % and two more columns than the number of columns to add space for the version string
    % and version number)
    formatted = cell(size(raw,1)-1, size(cols,1)+2);
    
    % Fill in each column in the empty formatted matrix with information from the raw data
    % For each column specified
    for i = 1:size(cols,1)
        % Put the data in the formatted matrix
        formatted(:,i) = raw(2:end, cols{i,1});
    end
    
    % Convert any numbers to string and any empty values ([]) to NaNs
    % Loop through each element in formatted (use single number indexing to traverse this
    % as it is stored in memory)
    for i = 1:numel(formatted)
        % If the cell contains a numeric value that isn't a NaN
        % This takes care of some MCID and AlgID columns
        if isnumeric(formatted{i}) && ~sum(isnan(formatted{i}))
            % Convert it to a string
            formatted{i} = num2str(formatted{i});
        % If the cell contains an empty value
        elseif isempty(formatted{i})
            % Change it to a NaN for compatibility with the database toolbox
            formatted{i} = NaN;
        end
    end
    
    % Set the version string to be the second to last columnn in the matrix
    formatted(:,end-1) = {ver};
    % Set the versionnum integer to be the last column in the matrix
    formatted(:,end) = {getVerNum(ver)};
    
    % Print the time it took to read and process the data
    toc
    
    %% Step 3 Fix for the case where the MS P/I/F date is noted as 'Planned Deficincy'
    % Change the string to a NaN so that the data will be uploaded as a null instead
    % Added a catch for the case of 'Done' and 'DOne'
    % Loop through each element and do a strcmp to see if the element mathces the string
    for i = 1:size(formatted,1)
        for j = 1:size(formatted,2)
            % If any field matches one of these strings
            if strcmpi('Planned Deficiency', formatted{i,j}) || strcmpi('Done', formatted{i,j}) || strcmpi('Done?', formatted{i,j})
                % Set the value to a NaN so it gets set as Null in the database
                formatted{i,j} = NaN;
            end
        end
    end
    
    %% Upload the data
    
    % Keep track of time
    tic
    disp('Starting upload')
    
    % Insert the data into the database (addeding the names of the version and versionnum
    % columns to the listing
    fastinsert(obj.conn, 'tblMDL', [cols(:,2);{'version';'versionnum'}], formatted);
    
    % Display the time required to upload the data
    toc
    
    recordsAdded = size(formatted,1);
    
end

function cols = setCols
%Keeps the bulky column definitions separate
    
    % Define the column numers to keep from the 3-step tab and their assosiated name 
    % in the database table
    cols={ 1,'CreatedDate';     ... % Column A  - Created Date
           2,'SEIDI';           ... % Column B  - SEIDI (calculated)
           3,'SEName';          ... % Column C  - SE (calculated)
                                ... % 8-Step Algoritm Information
           4,'AlgID';           ... % Column D  - Algorithm ID (calculated)
           5,'MCID';            ... % Column E  - Malfunction Criteria ID
           6,'ComponentSystem'; ... % Column F  - Component / System Name (calculated)
           7,'DiagType';        ... % Column G  - Diagnostic Type (calculated)
           8,'FailureMode';     ... % Column H  - Failure Mode (calculated)
           9,'Team8Step';       ... % Column I  - 8-Step Team (calculated)
          10,'Owner8Step';      ... % Column J  - 8-Step Owner (calculated)
          11,'Status8Step';     ... % Column K  - 8-Step Status (calculated)
                                ... % Pacific Red X1 3-Step Information
         132,'RedX1';           ... % Column EB - Pacific Red X1
         134,'Team3StepX1';     ... % Column ED - 3-Step Team
         135,'Owner3StepX1';    ... % Column EE - 3-Step Owner
         136,'MSPPlanX1';       ... % Column EF - MS P Review Plan
         137,'MSIPlanX1';       ... % Column EG - MS I Review Plan
         138,'MSFPlanX1';       ... % Column EH - MS F Review Plan
         139,'MSPActualX1';     ... % Column EI - MS P Review Actual
         140,'MSIActualX1';     ... % Column EJ - MS I Review Actual
         141,'MSFActualX1';     ... % Column EK - MS F Review Actual
                                ... % Pacific Red X2/3 3-Step Information
         142,'RedX3';           ... % Column EL - Pacific Red X2/3
         144,'Team3StepX3';     ... % Column EN - 3-Step Team
         145,'Owner3StepX3';    ... % Column EO - 3-Step Owner
         146,'MSPPlanX3';       ... % Column EP - MS P Review Plan
         147,'MSIPlanX3';       ... % Column EQ - MS I Review Plan
         148,'MSFPlanX3';       ... % Column ER - MS F Review Plan
         149,'MSPActualX3';     ... % Column ES - MS P Review Actual
         150,'MSIActualX3';     ... % Column ET - MS I Review Actual
         151,'MSFActualX3';     ... % Column EU - MS F Review Actual
                                ... % Pacific Black 3-Step Information
         152,'Black';           ... % Column EV - Pacific Black
         154,'Team3StepX12';    ... % Column EX - 3-Step Team
         155,'Owner3StepX12';   ... % Column EO - 3-Step Owner
         156,'MSPPlanX12';      ... % Column EP - MS P Review Plan
         157,'MSIPlanX12';      ... % Column EQ - MS I Review Plan
         158,'MSFPlanX12';      ... % Column ER - MS F Review Plan
         159,'MSPActualX12';    ... % Column ES - MS P Review Actual
         160,'MSIActualX12';    ... % Column ET - MS I Review Actual
         161,'MSFActualX12'};       % Column EU - MS F Review Actual
end

function vernum = getVerNum(ver)
%Formats a release version string into an integer number
    % Use this to create an additinoal column that can be used to sort MDL releases by
    % when they were released
    % ver should be a string like this: X.X.X.XX, i.e., 2.2.0.9 or 2.1.0.36
    % It will get converted into 22009 or 21036
    
    % Pull out each section from the version string
    a = sscanf(ver(1),'%u8');
    b = sscanf(ver(3),'%u8');
    c = sscanf(ver(5),'%u8');
    d = sscanf(ver(7:end),'%u8');
    
    % Combind these into an integer release version
    vernum = a*10^4 + b*10^3 + c*10^2 + d;
    
end
