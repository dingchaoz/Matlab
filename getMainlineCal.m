function [calFile, ecfgFile] = getMainlineCal(mainlineRoot,copyCalToDir)
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
    
    % Grab the file names of the latest mainline calibration
    %dirCal = dir(fullfile(mainlineRoot,'*_r*.xcal'));
    % Don't specifically look for '_r' in the name like only Calbert puts in the file name
    dirCal = dir(fullfile(mainlineRoot,'*.xcal'));
    dirConfig = dir(fullfile(mainlineRoot,'*.ecfg'));
    % Old Pacific wildcase characters
%     dirCal = dir(fullfile(mainlineRoot,'*_??????_r*.xcal'));
%     dirConfig = dir(fullfile(mainlineRoot,'*_??????.ecfg'));
    
    % Check the number of .xcal files found
    if isempty(dirCal)
        % Throw an error that no .xcal could be found
        error('ThresholdExporter:getMainlineCal:NoCalFile','Couldn''t find any .xcal files in %s.',mainlineRoot)
    elseif length(dirCal) > 1
        % Warn that more than one cal file was used, take the last one
        warning('ThresholdExporter:getMainlineCal:MoreThanOneFile','There was more than one .xcal file found in %s, using the newest file.',mainlineRoot)
        % Keep the last one
        calFile = dirCal(end).name;
    else
        % Keep the only cal file present
        calFile = dirCal(end).name;
    end
    
    % Check the number of .ecfg files found
    if isempty(dirConfig)
        % Throw an error that no .ecfg could be found
        error('ThresholdExporter:getMainlineCal:NoEcfgFile','Couldn''t find any .ecfg files in %s.',mainlineRoot)
    elseif length(dirConfig) > 1
        % Warn that more than one cal file was used, take the last one
        warning('ThresholdExporter:getMainlineCal:MoreThanOneFile','There was more than one .ecfg file found in %s, using the newest file.',mainlineRoot)
        % Keep the last one
        ecfgFile = dirConfig(end).name;
    else
        % Keep the only ecfg file present
        ecfgFile = dirConfig(end).name;
    end
    
    % Create the destination directory if it doesn't exist already
    % The destination directroy is just a folder named for the family in the working dir
    if ~exist(copyCalToDir, 'dir')
        mkdir(copyCalToDir);
    end
    
    % Move the .xcal and .ecfg onto the local machine from the network
    copyfile(fullfile(mainlineRoot,calFile), fullfile(copyCalToDir,calFile));
    copyfile(fullfile(mainlineRoot,ecfgFile), fullfile(copyCalToDir,ecfgFile));
    
    % Pass the location to the ecfg and xcal
    calFile = fullfile(copyCalToDir,calFile);
    ecfgFile = fullfile(copyCalToDir,ecfgFile);
    
end
