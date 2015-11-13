classdef Capability < handle
%This class should be inherited by both SQLConnection and EventProcessor
%   This class will contain the basic features of interfacing with the database and
%   the parameters, including holding the database connection object, methods to
%   look-up data-types and parameters names, and methods to look-up event driven data
%   decoding information.
%   
%   Original Version - Chris Remington - March 23, 2012
%   Revised - Chris Remington - January 9, 2014
%     - Trying to merge with Atlantic and IUPR_DB code
%   Revised - Chris Remington - February 21, 2014
%     - Add error handling for connection to a new database with nothing in the tables
%   Revised - Chris Remington - March 20, 2014
%     - Merged Sri's Dot Plot functions into the main code to allow that functionality
%       within the GUI
    
    properties % Public
        % Structure to hold the filtering values for a current plot configuration
        filt
        % Strcuture to hold possible vehicle types / families, selected vehicle type /
        % families, and the listing of avaiable trucks that meets that criteria
        % This is used in the GUI to help if figure what to display
        filtDisp
    end
    
    properties (SetAccess = protected)
        % Databse connection object
        conn
        % Local cache of the TruckName, TruckID, and Engine listing
        tblTrucks
        % Local cahce of only the recently worked-with parameters to speed
        % up access to datatype, b-number, etc. information
        paramInfoCache
        % Event Driven data decoding information
        evdd
        % Event Driven ignore system errors for when doing data upload
        evddIgnore
        % System Error listing (temporary until error_table file can be uploaded into db)
        seInfo
        % Plot Processing Information
        ppi % Check compatibility with the GUI because I change 'null' to NaN %%%%%%%%%%%%
        % Structure to hold the list of 3-step owners and their diagnostics
        plotOwners
        % Box Plot generator
        box
        % Histogram generator
        hist
        % Dot Plot generator
        dot
        % Ppk Plot generator
        caphist
        % One property to hold a structure for each engine family's threshold values
        cals
    end
    
    properties (SetAccess = private)
        % Property that notes if this is an HD-style 6 digit s/w version
        is6Dig
        % Property to hold the obd certification level
        obd
        % Property to hold the 
        littleendian
        % Name of the server that is currently being used
        server
        % Name of the instance name currently being used
        instanceName
        % Name of program to display on the plots
        plotProgramName
        % Program map to hold mapping of server, instance, program, and database names
        progMap
    end
    
    properties (Access=private)
        % Internal variable to hold the program name of the current database
        privateProgram
    end
    
    properties (Dependent, SetObservable)
        % The program name currently connect to
        program
    end
    
    events
        % Event that will be raised when the program name and database connection changes
        programChanged
    end
    
    methods % Constructor + Destructor
        
        % Destructor
        function delete(obj)
            %disp('Capability desctructor called.')
            % Close the database connection
            close(obj.conn);
        end
        
        % Constructor
        function obj = Capability(program)
            
            % Make sure conn is initialized to an empty set
            obj.conn = [];
            
            % Set some preferences in the database toolbox
            % - Set the log-in timeout to 5 seconds so Matlab doesn't hang while waiting
            logintimeout('com.microsoft.sqlserver.jdbc.SQLServerDriver',5);
            % - Set the return data format to be a structure, turn on error reporting
            setdbprefs('DataReturnFormat','structure');setdbprefs('ErrorHandling','report');
            
            % Define the mapping of database name, plot display program, server, and instance
            obj.progMap = {
            % 'Display Name', 'Database Name', 'Server',    'Instance'
              'ISB',          'DragonMR',      'W4-S129433', 'CAPABILITYDB';
              'Chrysler CC',  'DragonCC',      'W4-S129433', 'CAPABILITYDB';
              'ISL',          'Yukon',         'W4-S129433', 'CAPABILITYDB';
              'Chrysler PU',  'Seahawk',       'W4-S129433', 'CAPABILITYDB';
              'ISX',          'HDPacific',     'W4-S129433', 'CAPABILITYDB';
              'Acadia',       'Acadia',        'W4-S129433', 'CAPABILITYDB';
              'Ayrton',       'Ayrton',        'W4-S129433', 'CAPABILITYDB'; 
              'Nighthawk',    'Nighthawk',     'W4-S129433', 'CAPABILITYDB';
              'Vanguard',     'Vanguard',      'W4-S129433', 'CAPABILITYDB';
              'Ventura',      'Ventura',       'W4-S129433', 'CAPABILITYDB';
              'Pele',         'Pele',          'W4-S129433', 'CAPABILITYDB';
              'Atlantic',     'Atlantic',      'W4-S129433', 'CAPABILITYDB';
              'Blazer',       'Blazer',        'W4-S129433', 'CAPABILITYDB';
              'Bronco',       'Bronco',        'W4-S129433', 'CAPABILITYDB';
              'Clydesdale',   'Clydesdale',    'W4-S129433', 'CAPABILITYDB';
              'Mamba',        'Mamba',         'W4-S129433', 'CAPABILITYDB';
              'Shadowfax',    'Shadowfax',     'W4-S129433', 'CAPABILITYDB';
              'Sierra',       'Sierra',        'W4-S129433', 'CAPABILITYDB';
              'Thunderbolt',  'Thunderbolt',   'W4-S129433', 'CAPABILITYDB';
              'Vulture',      'Vulture',       'W4-S129433', 'CAPABILITYDB';
              };
            
            % If program wasn't passed in
            if ~exist('program','var')
                % Default to Pacific
                program = 'HDPacific';
            elseif strcmp('Pacific',program)
                % Rename to HDPacific
                program = 'HDPacific';
            end
            
            obj.program = program;
            % The set method of the program property will automatically open the
            % connection to the correct database
            
            % Get the list of 3-step owner names from the MDL
            % (this must be called AFTER the ppi information is loaded)
            % Bogus for now, need to re-work how this gets data
            obj.plotOwners = obj.generatePlotOwners();
            
            % Initalize the box plot generator object
            obj.box = BoxPlotGenerator;
            
            % Initalize the histogram generator object
            obj.hist = HistogramGenerator;
            
            % Initalize the dot plot generator object
            obj.dot = DotPlotGenerator;
			
            % Initalize the ppk plot generator object
            obj.caphist = CapHistGenerator;
            
            % Set method of program takes care of populating the properties because this
            % needs to be done every time the program is changed
            
        end
    end
    
    methods % program property set and get methods
        
        function obj = set.program(obj, in)
            
            %% Connection Stuff
            % Find the server name, instance, and plot display name based on specified
            % program name using the progMap variable defined above
            idx = find(strcmp(in,obj.progMap(:,2)));
            
            % If no matches were found for the specified database name
            if isempty(idx)
                % Use some default values
                obj.plotProgramName = '???';
                obj.server = 'W4-S129433';
                obj.instanceName = 'CAPABILITYDB';
            else
                % Set these properties
                obj.plotProgramName = obj.progMap{idx,1};
                obj.server = obj.progMap{idx,3};
                obj.instanceName = obj.progMap{idx,4};
            end
            
            % Attempt to connect to the database
            obj.openConnection(in);
            
            %% Update local data for this program
            
            % Grab the latest truck information from the database
            obj.assignTruckData;
            
            % Initalize a template of the paramInfoCache
            % As the process runs, this will learn what data is accessed
            % most and add it into this structure
            obj.paramInfoCache = struct('Data', [], 'DataType', [], ...
                'Unit', [], 'Min', [], 'Max', [], 'BNumber', [], ...
                'PublicDataID', [], 'Calibration', [], ...
                'ScalarToolUnitConv', [], 'ScalarOverrideToolUnit', []);
            
            % Load in event driven decoding information from the database
            obj.evdd = fetch(obj.conn, 'SELECT [xSEID],[Parameter],[PublicDataID],[BNumber],[DataType],[Units] FROM [dbo].[tblEvdd]');
            % Load in the event driven system errors to ignore
            obj.evddIgnore = fetch(obj.conn, 'SELECT [SEID],[Error_Name],[Description] FROM [dbo].[tblEvddIgnore]');
            % If there was no data in the table for this
            if isempty(obj.evddIgnore)
                % Make it an empty strcture with no value
                obj.evddIgnore.SEID = [];
                obj.evddIgnore.Error_Name = {};
                obj.evddIgnore.Description = {};
            end
            
            % Load in the system error information from the newest error_table loaded in
            % the database
            obj.seInfo = fetch(obj.conn, 'SELECT [Error_Table_ID] As SEID, [Error_Name] As SEName, [Fault_Code] As FaultCode, [J2010_P_Code] As PCode, [J1939_SPN] As J1939SPN, [J1939_FMI] As J1939FMI  FROM [dbo].[qryNewestErrTable] ORDER BY [SEID]');
            
            % Fill in the plot processing info property
            obj.ppi = fetch(obj.conn, 'SELECT [SEID],[ExtID],[Name],[CriticalParam],[Units],[LSL],[USL],[fromSW],[toSW],CONVERT(float,[famSpecific]) As famSpecific FROM [dbo].[tblProcessingInfo]');
            % If the table was not empty
            if ~isempty(obj.ppi)
                % Set null strings to NaN for the LSL and USL for compatibility with other stuff
                obj.ppi.LSL(strcmp(obj.ppi.LSL,'null')) = {NaN};
                obj.ppi.USL(strcmp(obj.ppi.USL,'null')) = {NaN};
            end
            % Otherwise it doens't matter becuase there was no processing informaiton in
            % the database, so obj.ppi can stay as an empty set
            
            % Generate the filtDisp parameters
            if ~isempty(obj.tblTrucks)
                % Get the unique engine families
                obj.filtDisp.engfams = [{'All'}; unique(obj.tblTrucks.Family)];
                % Get the unique truck types
                obj.filtDisp.vehtypes = [{'All'}; unique(obj.tblTrucks.TruckType)];
            else
                % Default these to be just 'All'
                obj.filtDisp.engfams = {'All'};
                obj.filtDisp.vehtypes = {'All'};
            end
            
            % Update the threshold values for this programs families
            obj.assignCalParams
            
            % Calculate whether or not this program uses 6 digit software versions
            % Currently only Pacific does this
            switch obj.program
                case {'HDPacific','Pacific','Dragnet_X'}
                    obj.is6Dig = 1;
                otherwise
                    obj.is6Dig = 0;
            end
            
            % Calculate whether or not this program uses a little-endian ECM (Bosch ECM)
            switch obj.program
                case {'Vanguard','Ventura','Vindicator','Voyager','Viking'}
                    obj.littleendian = 1;
                otherwise
                    obj.littleendian = 0;
            end
            
            % Calculate the OBD certification based on the program name (as defined in the datbase)
            % 'obdii'  = OBD-II (ARB Light-duty OBD-II certified)
            % 'hdobd'  = HD-OBD (ARB Heavy-duty OBD certified)
            % 'euro5'  = Euro 5 OBD (for light vehicles)
            % 'euro6'  = Euro 6 OBD (for light vehicles)
            % 'eurovi' = Euro VI OBD (for heavy vehicles)
            switch obj.program
                case {'Vanguard','Seahawk'}
                    obj.obd = 'obdii';
                case {'Elrond','Eclipse','Pele','Eukon'}    
                    obj.obd = 'eurovi';
                case {'Panther','Ayrton'}
                    obj.obd = 'euro5';
                case {'????????'}
                    obj.obd = 'euro6';
                otherwise
                    % Assume the rest are US HD-OBD (which might not always be right but
                    % will be right more often than it's wrong)
                    obj.obd = 'hdobd';
            end
            
            % Initalize the filt property to an empty strucutre with default values
            obj.filt = struct('byVehicle',0,...
                              'vehicle',{{''}},...    Have to do double cell otherwise Matlab gets rid of the cell
                              'vehtype',{{'All'}},... Have to do double cell otherwise Matlab gets rid of the cell
                              'engfam',{{'All'}},...  Have to do double cell otherwise Matlab gets rid of the cell
                              'VehicleString','All',...
                              'FamilyString','All',...
                              'TruckString','All',...
                              'date',[NaN,NaN],...
                              'DateString','None',...
                              'software',[NaN,NaN],...
                              'trip',NaN,...
                              'emb',0,...
                              'RawLowerVal',NaN,...
                              'RawUpperVal',NaN,...
                              'RawCondition','or',...
                              'MinOrMax','valuemax',...
                              'Name','',...
                              'SEID',0,...
                              'ExtID',NaN,...
                              'FC',0,...
                              'CriticalParam','',...
                              'Units','',...
                              'LSLName','',...
                              'USLName','',...
                              'LSL',NaN,...
                              'USL',NaN);
            
            % Notify the event listener that the program name has changed
            obj.notify('programChanged')
            % I used this in IUPR object, but now I use the PreSet and PostSet pre-defined
            % events for the program property and this works very well
            
        end
        
        % Get method for the program name
        function program = get.program(obj)
            % Return the internal private copy
            program = obj.privateProgram;
        end
        
    end
    
    methods (Access = protected)
        
        % Function to open the data base connection
        function openConnection(obj,in)
        
            % Check if the existing connection is still alive
            if ~isempty(obj.conn) && isconnection(obj.conn)
                % Close the current connection
                close(obj.conn)
            end
            
            try
                % Open the database connection
                obj.conn = database(in,'','', ...
                    'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
                    sprintf('%s%s%s%s%s%s', ...
                    'jdbc:sqlserver://',obj.server,';instanceName=',obj.instanceName, ...
                    ';database=',in, ...
                    ';integratedSecurity=true;'));
                % Assign the name to the property field
                obj.privateProgram = in;
                % Display a message on the workspace
                %fprintf('Successfully connected to the %s database.\n',in)
            catch ex
                
                % If a connection couldn't be made
                if strcmp('database:database:connectionFailure',ex.identifier) || ...
                        (strcmp('database:database:cursorError',ex.identifier) &&...
                         any(strfind(ex.message,'The SELECT permission was denied')))
                    
                    % If it was becase of a bad database name specified
                    if strncmp('Cannot open database',ex.message,20) || any(strfind(ex.message,'The SELECT permission was denied')) || strncmp('Login failed for user',ex.message,21)
                        % Throw an error that an invalid program name was specified
                        error('Capability:InvalidProgram','Couldn''t connect to the %s program database. The database wasn''t found or you don''t have permission to access the data.',in)
                    elseif strncmp('The TCP/IP connection to the host',ex.message,33)
                        % Throw an error that the TCP/IP connection cound't be made
                        error('Capability:UnableToConnect','Couldn''t connect to the specified program of %s',in)
                    else
                        % Rethrow the original error
                        rethrow(ex)
                    end
                    
                elseif strcmp('database:database:cursorError',ex.identifier)
                    
                else % unknown error
                    % Rethrow the original error
                    rethrow(ex)
                end
            end
        end
        
        % Update the threshold values for all engine families on this program
        function assignCalParams(obj)
            % Clear out any old ones if they exist
            obj.cals = [];
            
            % Read in binary data from the database for each engine family
            calData = fetch(obj.conn, 'SELECT [Family],[MatFile] FROM [dbo].[tblCals]');
            
            % If there was no data present
            if isempty(calData)
                % Don't bother doing anything, leave the field as an empty set
                return
            end
            
            % Use the user's temporary directory to write the mat files to
            loc = [fullfile(tempdir,'capdata') '\'];
            % If the location doesn't already exist
            if ~exist(loc,'dir')
                % Make the folder
                mkdir(loc);
            end
            
            prog = obj.privateProgram;
            % For each engine family present
            for i = 1:length(calData.Family)
                % Engine Family
                fam = calData.Family{i};
                % Write the downloaded data to a local .mat file
                fid = fopen([loc prog '_' fam '.mat'],'w');
                fwrite(fid,calData.MatFile{i},'ubit1');
                fclose(fid);
                % Read in and assign the data from the .mat file for this engine family
                obj.cals.(calData.Family{i}) = load([loc prog '_' fam '.mat']);
            end
        end
        
        % One function to suck the truck specific information from the database
        % This is also used by getTruckID, getTruckName, etc. so having it here makes sure
        % that all functions are doing this the same way
        function assignTruckData(obj)
            % Assign the data to the tblTrucks property
            obj.tblTrucks = fetch(obj.conn, 'SELECT * FROM [dbo].[tblTrucks]');
        end
        
    end
    
    % Small methods
    methods %(Access = private)
        
        % Small method to attempt to re-connect to the database
        function resetConn(obj)
            % Re-use the original open function to attempt to re-open the database to the
            % current database
            obj.openConnection(obj.program);
            % Utilize the existing set method to re-open the connection
            %obj.program = obj.program;
        end
        
        % Will take a sql string and fetch the data. If the connection was closed, this 
        % will attampt to reconnect to the database to get the data, otherwise throws the 
        % original error. Added here so this can be done uniformly across methods
        function d = tryfetch(obj,sql,rowinc)
            % If the optional input doesn't exist
            if ~exist('rowinc','var')
                % Set it do a default of 10000
                rowinc = 10000;
            end
            % Try
            try
                % Fetch the data
                d = fetch(obj.conn,sql,rowinc);
            catch ex
                % If the connection to the database was closed or no connection could be made
                if strcmp('Invalid or closed connection',ex.message) ||  ...
                       strncmp('Connection reset by peer',ex.message,24) || ...
                       strcmp('database:database:connectionFailure',ex.identifier)
                    % Reset the connection (if this fails, it will throw a
                    % database:database:connectionFailure exception)
                    obj.resetConn
                    % Wait for a quater second
                    pause(0.25)
                    % Try to fetch the data again with the new connection
                    d = fetch(obj.conn,sql,rowinc);
                else
                    % Rethrow the original exception
                    rethrow(ex)
                end
            end
        end
        
    end
    
    methods % implemeted externally
        %--------------------Methods for working with the trucks table--------------------
        % Get the truckID given a truck name string
        truckID = getTruckID(obj,truckName)
        % Get the truckName given a truckID
        truckName = getTruckName(obj,truckID)
        % Get the truckEngine given a truckID
        truckEngine = getTruckFamily(obj,truckID)
        % Get the truckRating given a truckID
        truckRating = getTruckRating(obj,truckID)
        % Get if data should be processed given a truckID
        processData = getTruckProcessData(obj,truckID)
        
        %----------------Methods for dealing with cal strings and numbers-----------------
        % Convert a calibration dot string to a calibration number
        calNumber = dot2num(obj, calDotStr)
        % Convert a calibration number to a calibration dot string
        calDotStr = num2dot(obj, calNumber)
        
        %-------------Methods for adding a datainbuild.csv file to the database-----------
        % Function to read in a datainbuild and add it to the database
        recordsAdded = addDataInBuild(obj, fileName, calibration)
        % Reads in a datainbuild file and returns a cell array with the
        % resulting contents read for upload to the database
        data = readDataInBuild(obj, fileName, cal)
        % Function to count the number of rows present in the
        % tblDataInBuild table for a given calibration version
        numRecords = getNumDIBParameters(obj, calibration)
        % Get the entire DataInBuild data table
        %data = GetDataInBuild(obj) %%% Not sure what this should even do???
        
        %------TO DO, methods to work add the error table into the a database table-------
        % Method to read in a new error_table and add it to the database
        recordsAdded = addErrorTable(obj, fileName, cal)
        % Copy of above but taking the C2ST errtable.xml as an input
        recordsAdded = addErrTable(obj, fileName, cal)
        % Metod to read in a new MDL and add the 3-step tab information to the database
        recordsAdded = addMDL(obj, fileName, ver) %%% Broken because of MDL format changes
        
        % --------------------System Error ID, Name, and FC Assosiations------------------
        % Get the system error name given the system error id
        name = getSEName(obj, SEID)
        % Get the ststem error id given the system errro name
        id = getSEID(obj, SEName)
        % Get the fault code number of a system error id
        fc = getFC(obj, SEID)
        % Get the P-code used on OBD-II products of a system error id
        pcode = getPcode(obj, SEID)
        % Function to get SPN needed
        spn = getSPN(obj, SEID)
        % Function to get FMI needed
        fmi = getFMI(obj, SEID)
        
        %--------------------Methods for getting parameter information--------------------
        % Use to access information in tblDataInBuild when decoding
        % parameters (see fucntion file for more information)
        returnData = getDataInfo(obj, publicDataID, cal, fieldName)
        % This is called by getDataInfo when it can't find a parameter
        % in the local cache. This function will call the database and add
        % that particular value to the cache and return the originally
        % desired piece of information spedified by returnFieldName
        dbData = updateParamInfoCache(obj, publicDataID, cal, returnFieldName)
        % This method will return the correct public data if for the specified parameter
        % and cal version pair
        pdid = getPublicDataID(obj, paramName, cal)
        % This method will return a structure of the information about the event driven
        % data that is broadcast with the specified SEID / ExtID conbination or xSEID
        data = getEvddInfo(obj, SEID, ExtID, field)
        
        %--------Methods for working with threshold values
        % This will take in a sting and return the spec limit for the given family
        val = getSpecValue(obj, specStr, family)
        
        %----------------Methods to grab capability data from the database----------------
        % Pull Event Driven data from the database - returns a structure straight from
        % database toolbox
        data = getEventData(obj, SEID, varargin)
        % Pull MinMax data from the database - returns a structure straight from the
        % database toolbox
        data = getMinMaxData(obj, pdid, varargin)
        % Pull the pre-calculated Ppk values from the database for a specified plot name
        % (plot name is used as this is the unique for each system error and parameter)
        HistCapData = getCapHistData(obj, Name, varargin)
        
        %-----------Methods to time-grig MinMax and Event Driven data together------------
        % Match miltiple MinMax parametes from one key-switch event to each other
        [matched, header] = matchMinMaxData(obj, publicDataID)
        % Match multiple event driven parameters from one diagnsotic with each other in
        % time
        [matched, header] = matchEventData(obj, SEID, varargin)
        
        %-----Miscelaneous useful things
        % Count the number of files waiting to be processed for the program
        filesWaiting(obj)
        
        %-----Processing Info
        % Update the processing information in the database
        uploadProcessingInfo(obj,fileName)
        % Update the evdd information in the database
        uploadEvdd(obj,fileName)
        
        %------------------Output Functions-----------------------------
        % Master plot maker control function
        makePlots(obj, rootDir, masterDateFilt, masterSwFilt)
        
        %------------------Random stuff for the GUI-----------------
        % Method to pull out 3-step owner information to allow GUI selection
        % This is dormant for now and needs a rework
        plotOwners = generatePlotOwners(obj) %%% Needs work
        % Get a datenum and date string fot a date formatted in yymmdd format
        [datenumber, datestring] = getDateInfo(obj, s) %%% Done and tested
        % Function to generate a pretty string for the date filtering used
        s = makeDateFiltString(obj, d) %%% Done and tested
        % Transfers ppi info of a specified index to the filt structure
        fillFiltPlotInfo(obj, idx)
        % Fills in the box information from the filt structure
        fillBoxInfo(obj)
        % Pulls data from the database and places it in the box plot object
        fillBoxData(obj, groupCode, group2Code)
		% Fills in the dot plot information from the filt structure
        fillDotInfo(obj)
        % Fills data from the database and places it in the dot plot object
        fillDotData(obj, groupCode, group2Code)
        % Fills in the hist information from the filt structure
        fillHistInfo(obj)
        % Pulls data from the database and places it in the histogram object
        fillHistData(obj)
        % Fills in the caphist plot
        fillCapHistInfo(obj)
        % Pulls data from the database and places it in the caphist object
        fillCapHistData(obj)
        % Update the filtering string used on the plots for truck, family, truck type, and date
        updateFilterStrings(obj)
        
        %----------------Precalculated Ppk Results Functions-----------
        % Calculate the Ppk results for each engine family on a given 
        result = getSEReport(obj,index,type)
        % Execuate the correct SQL command to calculate Ppk values on the server
        data = getSQLResult(obj, varargin)
        % Update the precalcalated results for all system error in the processing info table
        updatePrecalcResults(obj)
        
    end
    
end
