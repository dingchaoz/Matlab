classdef CapabilityUploader < Capability
%Provides a connection to the HD Capability SQL Server Database
%   Provides a convient interface between a user and a SQL Server back end
%   that will store OBD Capability data.
%   
%   This is a subclass of the Capability object. Basic functions like looking up data-types
%   and truck information are contined in that class.
%   
%   Chris Remington
%   11/08/2011 - Started
%   Modified - Chris Remington - December 4, 2012
%       - Changed the order of some things in the constructor so that I can log errors
%           that occur when loading the software cache
%   Modified - Chris Remington - April 4, 2014
%       - Added te knownSw propert that gets filled in with the known software versions
%         present for the selected engine program
%   Modified - Yiyuan Chen - 2014/11/25
%       - Modified method decodeMinMax, because one more input and as one more output are needed 
%         to identify what problem caused datavalue to be set to NaN
    
    %% Protected Properties
    properties (SetAccess = protected)
        
        % Error log object
        error
        % Event log object
        event
        % Warning log object
        warning
        % Timer log object
        timer
        % Root where network log files are copied
        networkLogRoot
        
        % Known software versions on this program (used the check reversed LDD S/W versions)
        knownSw
        
    end
    
    %% Protected Set Access Properties
    properties %(SetAccess = protected)
        
    end
    
    %% Constructor and Destructor
    methods % Constructor + Destructor
        % The constructor
        function obj = CapabilityUploader(program)
            
            % If no program was passed in
            if ~exist('program','var')
                % Default to Pacific
                program = 'HDPacific';
            end
            
            % Display message
            fprintf('CapabilityUploader constructor called for the %s program.\n',program)
            
            % Call constructor for Capability and pass in the program name
            obj = obj@Capability(program);
            
            % Set the networkLogRoot property for where to dump log files
            obj.networkLogRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\Log_Files';
            
            % Manually initalize the log files the first time
            obj.openLogFiles;
            
            % Manually initialize the software versions the first time
            obj.setPossibleSw;
            
            % Add pre-set listener (clear out log files before changing program)
            obj.addlistener('program','PreSet',@obj.clearLogFiles);
            
            % Add post-set listener (initalize new log files after changing program)
            obj.addlistener('program','PostSet',@obj.openLogFiles);
            
            % Add post-set listener (initalize the list of possible softwares based on tblErrTable)
            obj.addlistener('program','PostSet',@obj.setPossibleSw);
            
        end
        
        % The destructor
        function delete(obj)
            % Trigger a log file clear and copy
            obj.clearLogFiles
            % Print to the console that the destructor has been called
            disp('Destructor called.')
        end
    end
    
    methods (Access = protected) % To create and copy log files to the network
        % Method to close existing log files and copy them to the network
        % This should be called on the PreSet event of the 'program' property
        function clearLogFiles(obj,~,~)
            % If any of the log objects are empty
            if isempty(obj.error) || isempty(obj.event) || isempty(obj.warning) || isempty(obj.timer)
                % Display a message
                disp('Log file writer objectes were not initalized but a log file flush was requested.')
                % Exit the function
                return
            end
            
            % Get the log file names
            errorName = obj.error.fileName;
            eventName = obj.event.fileName;
            warningName = obj.warning.fileName;
            timerName = obj.timer.fileName;
            % Clear out the log file objects so the files are closed
            obj.error = [];
            obj.event = [];
            obj.warning = [];
            obj.timer = [];
            % Check if program name folder exist on the network
            if ~exist(fullfile(obj.networkLogRoot,obj.program),'dir')
                % Make the required directories
                mkdir(fullfile(obj.networkLogRoot,obj.program,'error'))
                mkdir(fullfile(obj.networkLogRoot,obj.program,'event'))
                mkdir(fullfile(obj.networkLogRoot,obj.program,'warning'))
                mkdir(fullfile(obj.networkLogRoot,obj.program,'timer'))
            end
            % Copy logs to a central location on the N: drive so we can all process data
            try
                copyfile(errorName,fullfile(obj.networkLogRoot,obj.program,'error\'))
                copyfile(eventName,fullfile(obj.networkLogRoot,obj.program,'event\'))
                copyfile(warningName,fullfile(obj.networkLogRoot,obj.program,'warning\'))
                copyfile(timerName,fullfile(obj.networkLogRoot,obj.program,'timer\'))
            catch ex
                % What to do if log file copying fails?
                disp('Failed to copy log files to network.')
            end
        end
        
        % Method to initalize new log files (i.e., when connecting to the database)
        % This should be called on the PostSet event of the 'program' property
        function openLogFiles(obj,path,~)
            % If old log writers still exist
            if ~isempty(obj.error) || ~isempty(obj.event) || ~isempty(obj.warning) || ~isempty(obj.timer)
                % Something is broken if it's possible to get here
                error('CapabilityUploader:UnknownError','Something is broken with log files if it is possible to get to this point in the code.')
                % Close them out and copy the data to the network location
                %obj.clearLogFiles
            end
            
            % Declare the logging objects
            obj.error = logWriter('Error_Log', fullfile(path,obj.program,'error'));
            obj.event = logWriter('Event_Log', fullfile(path,obj.program,'event'));
            obj.warning = logWriter('Warning_Log', fullfile(path',obj.program,'warning'));
            obj.timer = logWriter('Timer_Log', fullfile(path,obj.program,'timer'));
            
            % Initalize the headers of the log files
            obj.error.writef('CapabilityUploader Error Log File - %s Program\r\n',obj.program);
            obj.error.write('');
            obj.event.writef('CapabilityUploader Event Log File - %s Program\r\n',obj.program);
            obj.event.write('');
            obj.warning.writef('CapabilityUploader Warning Log File - %s Program\r\n',obj.program);
            obj.warning.write('');
            obj.timer.writef('CapabilityUploader Timer Log File - %s Program\r\n',obj.program);
            obj.timer.write('Truck Name,Successful Files,Time,Time/File,Failed Files,Time,Time/File,Total Files,Total Time,Time/File');
        end
        
        % This method selects the distinct software versions in tblErrTable and assigns this
        % into a field in the object. This information is used when processing LDD data to
        % account for cases where Calterm logged the data as if it were big-endian so the
        % software version was reversed and the ECM_Run_Time was not byte-swapped
        function setPossibleSw(obj,~,~)
            % Select unique software versions
            data = fetch(obj.conn,'SELECT DISTINCT [SoftwareVersion] FROM [dbo].[tblErrTable] ORDER BY [SoftwareVersion]');
            % Assign this into the object
            obj.knownSw = data.SoftwareVersion;
        end
        
    end
    
    %% Methods Inplamented Externally
    methods
        %--------Main method, adds a single Calterm III .csv file to the database---------
        % Add a .csv data file to the database
        % This has been revised and splits data into two parts and uploades each to the
        % correct database table
        AddCSVFile(obj, fullFileName, truckID)
        % A variation on AddCSVFile that will instead read in the .mat files that CANape
        % creates after nativly converting a .mdf file to a .mat file (this needs to take
        % in cal version as this is not present in the 
        success = AddMiniMatFile(obj, fullFileName, truckID, cals)
        
        %---------------Methods that decode raw data into engineering units---------------
        % Convert raw hex into scaled numberic values
        scaledData = hex2scaled(obj, hexString, dataType, varargin)
        % Take in the Event Driven hex string and xSEID, use hex2scaled to
        % return the properly scaled and decoded value
        decodedData = decodeEvent(obj, xSEID, hexString, cal)
        % Take in a Public Data ID and hex string, use hex2scaled to return
        % a properly scaled and decoded value
        [decodedData, EMBFlag] = decodeMinMax(obj, PublicDataID, hexString, cal, PublicIDmatch)
        
        %----------------Methods to keep track of truck software versions-----------------
        % Method to update the last know sw version of a truck (edits lastSoftwareCache)
        %UpdateLastSoftware(obj, truckID, calibration)
        % Method to get the last know sw version of a specified truck (this will be used
        % if Calterm didn't catch the software version in the header of the .csv file)
        software = getLastSoftware(obj, truck)
        % Method to get the last known calibration revision of the specificed truck
        calRev = getLastCalRev(obj, truck)
        % Method to get the last known ECM code of the specified truck
        ECMCode = getLastECMCode(obj, truck)
        
        %-----Data processing methods
        % Master mathod to run data process for one program
        dataUploader(obj)
        % Small method to process one truck of data
        [filesP,timeP,filesE,timeE] = csvUploader(obj, rootDir, truckID)
        
    end
    
    %% Protected methods implemented externally
    methods (Access = protected)
        % Does the dirty work of reading in the .csv file
        readCaltermIII_EcmDataOnly(obj, filename)
        
        % Process the MinMax data to make them into pairs
        processMinMaxData(obj, abs_time, ECM_Run_Time, MMM_Update_Rate, MinMax_PublicDataID, MinMax_Data, cal, truckID)
    end
    
    %% Private methods implemented externally
    methods (Access = private)
        % Add a new truck to the database
        truckID = addTruck(obj, truckName)
    end
    
end
