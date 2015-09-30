function exportThresholds(r,l,mainline,program,famName,code)
%Generate a .mat export file for the latest mainline cal using a filter file
%   Generate a .mat export file for the latest mainline calibration of a specified engine
%   family. You will need to specify a filter file for Calterm to use.
%   
%   Usage: exportThresholds(r,l,mainline,program,famName,code)
%   
%   Inputs -
%   r:            Directory where the file the filter file
%   l:            Directory where to locally copy the .xcal and .ecfg
%   mainlinePath: Directory where the mainline calibrations are stored for the desired
%                 engine family
%   program:      Name of the engine program
%   famName:      Name of the engine family (used to separate the data into it's own folder)
%   code:         Product code to use for Calterm
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 21, 2012
%   Revised - Chris Remington - January 13, 2014
%     - Better implemented code to handle multiple engine programs
    
    % If the family name has a space in it, convert that to an underscore for the files
    % so that the run command can find the .m file properly
    %famNameDir = famName;
    % Remove spaces
    %famNameDir(famNameDir==' ') = '_';
%   Revised - Dingchao Zhang - Sep 30th, 2015
%   - Enable script to isert multiple mainline cals and their rev and
%   verion info
    
    % Calculate the filter file location based on the engine program name
    filterFile = fullfile(r,program,[program '_Thresholds.flt.txt']);
    % Generate the location to put the Mainline cal
    copyCalToDir = fullfile(l,program,famName);
    % Generate the name for the export .m file from Calterm
    exportFile = fullfile(copyCalToDir,[famName '_export.m']);
    % Generate the name of the export .mat file
    matFile = fullfile(copyCalToDir,[famName '_export.mat']);
    
    % Get the mainline calibration names (this makes a directory in suppdata if need be)
    [cal, ecfg, calVer,calRev] = getMainlineCal(mainline,copyCalToDir);
    

% Loop through all mainline cals, and insert them and the calver, rev info into the database    
   for i = 1: length(cal)
       
        % Run the Calterm CLI to generate the .m export file
        runCaltermCLI(cal{i},ecfg{i},filterFile,exportFile,code);

        % Read in the .m file, parse the values, then save the variables as a .mat file
        m2mat(exportFile,matFile,filterFile,program)

        % Upload the .mat file for this program
        uploadCalibratables(matFile,program,famName,calVer{i},calRev{i})
   end
   
end
