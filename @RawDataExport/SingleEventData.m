function SingleEventData(obj, seid, dir)
%Exports all Event Driven data from the database to .mat files
%   This rountine will look for a listing of all system errors with data in
%   tblEventDrivenData. It will then pull each parameters's worth of data from the database and save the raw
%   data into both an excel spreadsheet and a .mat file
%   
%   Usage: SingleEventData(obj, seid, dir)
%   
%   Inputs -
%   seid:     System error id of the diagnsotic that you want to export
%   dir:      Location of the base directory where the files should be stored
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 27, 2012
%   Revisied - Chris Remington - August 22, 2012
%     - Added a try/catch block to the main for loop so that any error on one system error
%       doesn't stop the rest of the system errors in the export list
%   Modified - Chris Remington - September 17, 2012
%     - Cleaned up from the one script that exported all event driven data and converted
%       to have this only handle one system error at a time
    
    % Get the System Error Name
    try
        SEName = obj.getSEName(seid);
    catch ex
        SEName = 'Unknown';
    end
    % Display the System Error being worked on
    fprintf('Working on SEID %.0f - %s\n',seid,SEName);
    % Grab the data form the database
    [data, header] = obj.matchEventData(seid);
    % Generate the file name (ex, SE7613 - NOX_OUT_SENS_IR_STUCK_ERR.mat)
    fname = sprintf('%s - SE%05.0f.mat',SEName,seid);
    % Generate a mat file from the raw data
    createMatFile(data, header, dir, fname)
end

function createMatFile(data, header, dir, fname)
%Takes in output from matchEventData, then generates and saves a .mat file with the data
%   The main purpose of this is to expost the Event Driven data to individual .mat files
%   in a consistant manner to make it easier for other to use the data
    
    % These five are the same for all diagnsotics
    abs_time = cell2mat(data(:,1));         % Matlab datenum of the date and time
    ECM_Run_Time = cell2mat(data(:,2));     % Closest ECM_Run_Time value
    TruckName = data(:,3);                  % Name of the truck the datapoint came from
    EngineFamily = data(:,4);               % Engine family of the truck
    Software = cell2mat(data(:,5));         % Software version on the truck
    % Save the preliminary data in a mat file
    save(fullfile(dir,fname),'abs_time', 'ECM_Run_Time', 'TruckName', 'EngineFamily', 'Software');
    
    % For each parameter with data (anywhere from 1 to 5, varying by diagnsotic)
    for i = 6:size(data,2)
        % Generate a name that won't upset matlab
        name = generateMatVarName(header{i});
        % Run eval to dynamically assign the data to a properly named variable
        eval(sprintf('%s = cell2mat(data(:,%.0f));',name, i));
        % Append the variable onto the .mat file generated above
        save(fullfile(dir,fname),name,'-append');
    end
end

function in = generateMatVarName(in)
%Used to trim illegal Matlab characters from variable names and shorten them to length
%   Some data broadcast is a calculation of two different parameters and the name notes
%   this distinction. However, this will cause a problem with eval if you try to create a
%   variable and have the name contain the following characters (-, (, ), *, /, +, etc.)
    
    % Look for illegal characters
    idx = (in=='-' | in=='(' | in==')' | in=='/' | in=='*' | in=='+' | in==' ');
    % If there were any illegal characters
    if sum(idx)>0
        % Replace them with an underscore
        in(idx) = '_';
    end
    % If the first character got replaced with an underscore
    if in(1)=='_'
        % Drop it from the name
        in = in(2:end);
    end
    % If the name is too long, truncate it to 63 characters (the Matlab max)
    if length(in)>63
        in = in(1:63);
    end
end
