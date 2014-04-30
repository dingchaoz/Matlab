classdef logWriter < handle
%Allows easy event journaling of events in a log file
%   This is designed to allow flexability in how to journal different
%   events of varying sevarity in different and/or many log files
%   
%   Usage:
%   newInstance = logWriter(prefix, directory)
%   
%   prefix:    Prefix of text to name the log file, then end will contain a
%              timestamp of the the file was created.
%   directory: Location where the log file will be created
%   
%   Created - Chris Remington - Feb 1, 2012
%   Modified - Chris Remington - June 25, 2013
%     - Added the writef function to the object
    
    % Protected Properties
    properties (SetAccess = protected)
        % The fid for this log
        logFid
        % The file path, for later reference
        fileName
    end
    
    % All methods
    methods
        % Constructor
        function obj = logWriter(prefix, directory)
            if exist(directory, 'dir')
                % Create the file name
                % NOTE - there is an R2008a Matlab bug in datestr where is
                % doens't format the string 'yymmddHHMMSS' properly and switches
                % the day and hour, but concatinating separate 'yymmdd' and
                % 'HHMMSS' calls works as expected
                newFileName = fullfile(directory, [prefix '-' datestr(now,'yymmdd-') datestr(now,'HHMMSS') '.log']);
                % Set the internal property
                obj.fileName = newFileName;
                % Open the file for writing
                obj.logFid = fopen(newFileName, 'w');
            else
                % Make the directory
                mkdir(directory)
                % Generate the file name
                newFileName = fullfile(directory, [prefix '-' datestr(now,'yymmdd-') datestr(now,'HHMMSS') '.log']);
                % Set the internal property
                obj.fileName = newFileName;
                % Open the file for writing
                obj.logFid = fopen(newFileName, 'w');
            end
        end
        
        % Destructor
        function delete(obj)
            % Close the file
            fclose(obj.logFid);
        end
        
        % Define the write function that does the work
        function write(obj, string)
            % Call fprintf
            fprintf(obj.logFid, '%s\r\n', string);
        end
        
        % Another function that will just call fprintf as is and pass arguments into it
        function writef(obj, varargin)
            % Call fprintf
            fprintf(obj.logFid, varargin{:});
        end
    end
end
