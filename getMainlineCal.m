function [calFile, ecfgFile, calVer, calRev] = getMainlineCal(mainlineRoot,copyCalToDir)
%Goes out to the mainline cal folder and copies .xcal and .ecfg to local machine
%   This should be used when you want to automatically pull in the latest version of a
%   mainilne calibration.
%   
%   Inputs -
%   mainlineRoot: This is the directory of where the mainline calibration is stored
%   copyCalToDir: This is the directory weher the cal will be copied to
%   
%   Outputs -
%   calFile:      Fill file path and name of the copied mainline calibration
%   ecfgFile:     Fill file path and name of the copied mainline ecfg
%   
%   Original Version - Chris Remington - March 21, 2012
%   Revised - Chris Remington - September 10, 2012
%     - Changed the wild card characters to help account for when there is more than
%       once .xcal or .ecfg file. The new wildcards will make sure there are exactly 6
%       characters after the last underscore (implying a 6 digit software version.
%       Normally, odd .ecfg or .xcal file will have some other phrase appended onto the
%       end that I hope isn't 6 characters long.
%   Revised - Chris Remington - January 13, 2014
%     - Went to the old wildcard code and instead just will keep the newest .ecfg or .xcal
%       if there are multiples in the mainline directory
%   Revised - Dingchao Zhang - Sep 30th, 2015    
%   - Get multiple cals in the mainline cal directory and extract ver and
%   rev info  of the cal
%   Revised - Dingchao Zhang - Dec 14th, 2015    
%   - Modified script to recognize cal version by finding 8 consective
%   digits in cal name instead of using specific location


    % Grab the file names of the latest mainline calibration
    %dirCal = dir(fullfile(mainlineRoot,'*_r*.xcal'));
    % Don't specifically look for '_r' in the name like only Calbert puts in the file name
    dirCal = dir(fullfile(mainlineRoot,'*.xcal'));
    dirConfig = dir(fullfile(mainlineRoot,'*.ecfg'));
    calFile = {}; %Create a cell to hold multiple cat files
    ecfgFile = {}; %Create a cell to hold multiple ecfg files
    calRev = {}; %Create a cell to hold multiple cal versions
    calVer = {}; %Create a cell to hold multiple cal revisions
    % Old Pacific wildcase characters
%     dirCal = dir(fullfile(mainlineRoot,'*_??????_r*.xcal'));
%     dirConfig = dir(fullfile(mainlineRoot,'*_??????.ecfg'));
    
    % Check the number of .xcal files found
    if isempty(dirCal)
        % Throw an error that no .xcal could be found
        error('ThresholdExporter:getMainlineCal:NoCalFile','Couldn''t find any .xcal files in %s.',mainlineRoot)
    else
        % If there are main line cals
        for i = 1: length(dirCal) 
        
            % Add all the main line cals
            calFile{i} = dirCal(i).name;
        
        end
   
    end
    
    % Check the number of .ecfg files found
    if isempty(dirConfig)
        % Throw an error that no .ecfg could be found
        error('ThresholdExporter:getMainlineCal:NoEcfgFile','Couldn''t find any .ecfg files in %s.',mainlineRoot)
    else
        % If there are main line ecfgs
        
        for i = 1: length(dirConfig) 
            
            % Add all the main line ecfgs
            ecfgFile{i} = dirConfig(i).name;
            
        end
   
    end
    
    % Create the destination directory if it doesn't exist already
    % The destination directroy is just a folder named for the family in the working dir
    if ~exist(copyCalToDir, 'dir')
        mkdir(copyCalToDir);
    end
    
    % Move the .xcal and .ecfg onto the local machine from the network
    
    for i = 1: length(calFile)
        
        copyfile(fullfile(mainlineRoot,calFile{i}), fullfile(copyCalToDir,calFile{i}));
    
    end
    
    for i = 1: length(ecfgFile)
        copyfile(fullfile(mainlineRoot,ecfgFile{i}), fullfile(copyCalToDir,ecfgFile{i}));
    end
    
    % Pass the location to the ecfg and xcal
    calFile = fullfile(copyCalToDir,calFile);
    ecfgFile = fullfile(copyCalToDir,ecfgFile);
    
    % Check if there are more cal files than ecfg files
    if length(calFile) > length(ecfgFile)
        
        % If yes, replicate the lastest ecfg file till the number of ecfg
        % files is equal to the number of cal files
        for i = 1: length(calFile) - length(ecfgFile)
            ecfgFile(length(ecfgFile) + i) = ecfgFile(length(ecfgFile));
        end
    end
    
    
    for i = 1: length(calFile)
        %% Extract the version and revision info about the cal
        
        calSplit = strsplit(calFile{i},'\');  % Split the cal string into substrings using deliminator _
        s = char(calSplit(length(calSplit))); % Convert cell of calFile into char array
        calVer{i} = ''; % Array to hold Cal version digit
        
        if s(1) == 'P' && s(4) == '.' && s(7) == '.'   % If the cal name starting with P and has dots in every 2 digits between
            % Then the cal version is just the 8 digits after the P letter with . stripped off 
            calVer{i} = horzcat(calVer{i},s(2),s(3),s(5),s(6),s(8),s(9))
             
        else
            
            tf = isstrprop(s, 'digit'); % Return a logic array where elements of s is a number
            start_i = 0; % Initiate a variable to record the starting digit position of cal version


            for j = 1: length(tf)-8 % Loop through every 8 char's corresponding digit determinant value
                if sum(tf(j:j+7)) == 8 % If the 8 determinate values summing up to 8, meaning it is a cal version
                    start_i = j;      % Record the starting position       
                end
            end

            for z = start_i : start_i + 7 % Loop through the starting position and the following 7 digits
                 calVer{i} = horzcat(calVer{i},s(z)); % Concatenate them to form the Cal version string
            end    
        end
        
            
     
        %calSplit = strsplit(calFile{i},'\');  % Split the cal string into substrings using deliminator _
        calInfo = calSplit{length(calSplit)}; %Get the alst substring which has ver and rev info
        calInfoSplit = strsplit(calInfo,'_'); %Split the calInfo substring into smaller chunks
        %calVer{i} = calInfoSplit{length(calInfoSplit)-2};% Version is the 3rd substring counting from the alst
        calRev{i} = calInfoSplit{length(calInfoSplit)};%Revesion is the last substring
        index = regexp(calRev{i},'\.');% Get the position the . is
        calRev{i} = calRev{i}(2:index-1); % Extract only the revision numeric value
    end
end
