function [matched, header] = matchEventData(obj, SEID, varargin)
%Matches multiple ExtID parameters from one diagnostic with each other
%   Since Event Driven data is recorded with only one parameter per line and stored as
%   such, this script will attempt to read in the event driven data (sorted a special way)
%   and "time-grids" the data where multiple different parameters were broadcast at the
%   same time.
%   
%   Usage: [matched, header] = matchEventData(obj, SEID, 'property', value, ...)
%   
%   Inputs ---
%   SEID:      System Error ID of the system error that you want to match ExtID values of
%   varargin:  Listing of properties and their values. (see below)
%   
%              'engfam'    Specifies the filtering based on an engine family
%                          {''}            - Returns data from all families (Default)
%                          {'All'}         - Returns data from all families
%                          {'Type1', ...}  - Cell array of families will return only
%                                            data from the specified families
%   
%              'vehtype'   Specifies a vehicle type
%                          {''}            - Returns data from all vehicle types (Default)
%                          {'All'}         - Returns data from all vehicle types
%                          {'Type1', ...}  - Cell array of vehicle types will return only
%                                            data from the specified vehicle types
%   
%              'vehicle'   Specified individual vehicles to filter for
%                          {''}            - Returns data from all vehicles (Default)
%                          {'All'}         - Returns data from all vehicles
%                          {'Veh1', ...}   - Cell array of vehicle names will return only
%                                            data from the specified vehicles
%   
%              'rating'    Specifies filtering on vehicle rating values
%                          {''}            - Returns data from all ratings (Default)
%                          {'All'}         - Returns data from all ratings
%                          {'Rat1', ...}   - Cell array of vehicle names will return only
%                                            data from the specified vehicles
%   
%              'software'  Specifies a software filter. Value can take five forms:
%                          []              - An empty set specifies no software filter (Default)
%                          [NaN NaN]       - No filtering, analagous to an empty set []
%                          [500009]        - Get data only from the specified software
%                          [500008 510001] - Get data only from between (and including)
%                                            the two specified software versions
%                          [NaN 500009]    - If the first value in an NaN, get all data up
%                                            to (and including) the second value
%                          [510000 NaN]    - If the second value is an NaN, get all data
%                                            from (and including) the first software or newer
%   
%              'date'      Specifies a date filter. Values can take four forms:
%                          []              - An empty set specifies no date filter (Default)
%                          [NaN NaN]       - No filtering, analogous to an empty set []
%                          [734883 734983] - Get data only from date and timestamps
%                                            between the two specified Matlab date numbers
%                          [NaN 734983]    - If the first value in an NaN, get all data up
%                                            to the second matlab date number
%                          [734883 NaN]    - If the second value is an NaN, get all data
%                                            from the first matlab date number and newer
%   
%              'emb'       Specifies how to filter using the EMBFlag for each data point:
%                          0               - Return data points without EBM only (Default)
%                          1               - Return only data points with EMB indicated
%                          NaN             - Return both EBM and non-EMB data points
%   
%              'trip'      Specifies how to filter using the TripFlag for each data point:
%                          0               - Don't return values from test trips (Default)
%                          1               - Only reutrn values from test trips
%                          NaN             - Return both test trip and non-test trip data
%   
%              'values'    Specifies the filtering based on the value of the data point
%                          []              - No filtering by the DataValue (Default)
%                          [NaN NaN]       - Analogous to an empty set above, no filtering
%                          [NaN ValB]      - Keep values <= ValB
%                          [ValA NaN]      - Keep values >= ValA
%                          [ValA ValB]     - Keep values between ValA and ValB
%                          [ValA NaN ValB] - Keep values <= ValA or >= ValB
%   
%              %%%%%%%%%%%%%%%%%%%%%%%%%%%% Antiquated Field %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              'family'    Specifies an engine family filter. Valid values are:
%                          'all'   - Get data from all engine families (Default)
%                          'x1'    - Get data only from the X1 engine family
%                          'x3'    - Get data only from the X2 and X3 engine families
%                          'black' - Get data only from the Black engine family
%   
%              %%%%%%%%%%%%%%%%%%%%%%%%%%%% Antiquated Field %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              'truck'     Specifies a truck type filter. Valid values are:
%                          'all'   - Get data from all trucks (Default)
%                          'field' - Get data only from field test trucks
%                          'eng'   - Get data only from engineering trucks
%   
%   Outputs---
%   matched:   Cell array of data matched to each other, columns 6 and later contain the
%              actual data values
%   
%   Original Version - Chris Remington - March 15, 2012
%   Revised - Chris Remington - March 28, 2012
%     - Added the header output so that the parameter names are also returned with the
%       cell array so they don't have to be looked-up separate
%   Revised - Chris Remington - July 26, 2012
%     - Fixed a bug wherein data wouldn't get exported properly if there was no data
%       present for an ExtID of 0
%   Modified - Chris Remington - September 18, 2012
%     - Changed so that when here is only an ExtID of 0 present, the looping code is
%       skipped and the raw data is just dumped into a cell array to speed it up,
%       expecially when using this function to export raw Event Driven data
%   Modified - Chris Remington - October 9, 2012
%     - Added the ability to filter the matched dataset just like the
%       @Capability\getEventData function allows with the input parameters
%   Revised - Chris Remington - October 26, 2012
%     - Added try/catch logic on the fecth command to try to reset the database
%       connection first and attempt to fetch data again before throwing an error
%   Revised - Chris Remington - February 3, 2014
%     - Added additional filtering abilityies matching revised getEventData method
%   Revised - Chris Remington - April 7, 2014
%     - Moved to the use of tryfetch from just fetch to commonize error handling
%   Revised - Yiyuan Chen - 2014/12/17
%     - Modified the SQL query to fetch data from archived database as well
%   Revised - Yiyuan Chen - 2015/04/05
%     - Modified the SQL query to fetch data from Acadia's archived database as well
%   Revised - Yiyuan Chen - 2015/05/31
%     - Modified the SQL query to fetch data from Seahawk's archived database as well
%   Revised - Yiyuan Chen - 2015/07/28
%     - Modified to process special diagnostics
%   Revised - Yiyuan Chen - 2015/08/10
%     - Modified the SQL query to fetch data from Pacific's archived database 3 (from 2014/12/01) as well
%   Revised - Blaisy Rodrigues - 2016/01/11
%     - Modified the SQL query to fetch data from Sierra's archived database  (for SEIDs 12526, 11170, 11171, 11172 which log too frequently) as well, also for Nighthawk(where data before Nov-15 was moved to NighthawkArchive)
%   Revised - Blaisy Rodrigues - 2016/01/15
%     - Modified the SQL query to fetch data from Seahawk's archived database, SeahawkArchive2
%   Revised - Blaisy Rodrigues - 2016/02/9
%     - Modified the SQL query to fetch data from Acadia's archived database, AcadiaArchive2
    %% Process the inputs
    % Creates a new input parameter parser object to parse the inputs arguments
    p = inputParser;
    % Add the four properties and their default falues
    p.addParamValue('family', 'all', @ischar)%antiquated
    p.addParamValue('truck', 'all', @ischar)%antiquated
    p.addParamValue('software', [], @isnumeric)
    p.addParamValue('date', [], @isnumeric)
    p.addParamValue('emb', 0, @isnumeric)
    p.addParamValue('trip', 0, @isnumeric)
    p.addParamValue('values', [], @isnumeric)
    p.addParamValue('engfam', {''}, @iscellstr)
    p.addParamValue('vehtype', {''}, @iscellstr)
    p.addParamValue('vehicle', {''}, @iscellstr)
    p.addParamValue('rating', {''}, @iscellstr)
    % Parse the actual inputs passed in
    p.parse(varargin{:});
    
    %% Grab Data from Database
    % Define the sql for the fetch command
    % Make the where statement
    where = makeWhere(SEID, p.Results);
    % Sort the data by truck, then by date, then by ExtID to aid in matching  %%--%%
    % Formulate the entire SQL query for Pacific with its two archived databases
    if strcmp(obj.program, 'HDPacific')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [PacificArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [PacificArchive2].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [PacificArchive3].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
    % Formulate the entire SQL query for Vanguard with its archived database
    elseif strcmp(obj.program, 'Vanguard')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [VanguardArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [VanguardArchive].[dbo].[tblEventDrivenData2] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
    % Formulate the entire SQL query for Acadia with its archived database
    elseif strcmp(obj.program, 'Acadia')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [AcadiaArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
			'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [AcadiaArchive2].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
    % Formulate the entire SQL query for Seahawk with its archived database
    elseif strcmp(obj.program, 'Seahawk')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [SeahawkArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
			'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [SeahawkArchive2].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
        
     % Formulate the entire SQL query for Sierra with its archived database
    elseif strcmp(obj.program, 'Sierra')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [SierraArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
			
	% Formulate the entire SQL query for Nighthawk with its archived database
    elseif strcmp(obj.program, 'Nighthawk')
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [NighthawkArchive].[dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            'SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];		
						
    % Formulate the entire SQL query for other prgrams
    else
        sql = ['SELECT [datenum],[ECMRunTime],[ExtID],[DataValue],[TruckName],[Family],[CalibrationVersion] ' ...
            'FROM [dbo].[tblEventDrivenData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblEventDrivenData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum], [ExtID] ASC'];
    end
    
    % Move to the useage of the common tryfetch
    rawData = obj.tryfetch(sql,100000);
    
    % If there was no data in the database
    if isempty(rawData)
        % return an empty set
        matched = [];
        header = [];
        % Exit the function
        return
    end
    
    % Find the number of ExtIDs present
    % Below is the old method that has a problem when a system error only
    % broadcast one parameter on an ExtID of 1 (specifically SEID 7834)
    ExtIDList = unique(rawData.ExtID);
    numParams = length(ExtIDList); % use this method again for special diagnostics
    
    %% Process Data
    
    % Initalize the output (make it as long as rawData, trim at the end)
    matched = cell(length(rawData.datenum),numParams+5);
    % datenum | ECMRunTime | TruckName | Family | Software | Param0 | Param1 | Param2 | Param3 | Param4
    writeIdx = 1;
    
    % Create the header row
    header = cell(1,numParams+5);
    header(1:5) = {'datenum', 'ECM_Run_Time', 'TruckName', 'Family', 'Software'};
    % Fill in the parameter names
    for i = 1:numParams
        % Fill in the name of this parameter
        header{i+5} = obj.getEvddInfo(SEID, ExtIDList(i), 0);
    end
    
    % If there is only data from 1 SEID present, do this the easy way
    if numParams == 1
        matched(:,1) = num2cell(rawData.datenum);
        matched(:,2) = num2cell(rawData.ECMRunTime);
        matched(:,3) = rawData.TruckName;
        matched(:,4) = rawData.Family;
        matched(:,5) = num2cell(rawData.CalibrationVersion);
        matched(:,6) = num2cell(rawData.DataValue);
        % Return out of the function as matched and header have been defined
        return
    end
    
    % Otherwise, time-grid the parameters together
    % Initalize the readIdx at 1
    readIdx = 1;
    % Initalize the structure to hold onto the current value to fill the columns above
    d = struct('datenum', [], 'ECMRunTime', [], 'TruckName', [], 'Family', [], 'Software' , []);
    % Loop through the listing of data, try to find matches for each parameter
    while readIdx <= length(rawData.datenum)
        
        % Fill in the current value for these parameters based on the current line
        d.datenum = rawData.datenum(readIdx);
        d.ECMRunTime = rawData.ECMRunTime(readIdx);
        d.TruckName = rawData.TruckName{readIdx};
        d.Family = rawData.Family{readIdx};
        d.Software = rawData.CalibrationVersion(readIdx);
        
        % Search out the number of matching timestamps that are within 1/2 second of
        % eachother. This would imply all of that data is from one broadcast "set"
        % Look at the next "numParams" of lines to see how many match
        for j = 0:(numParams-1) % Counts up to the value of the largest ExtID
            
            try
                % If the next timestamp is more than 0.5 seconds in the future
                % or the name of the truck changed
                if abs(rawData.datenum(readIdx+j+1)-d.datenum) > 1/86400 || ...
                        ~strcmp(d.TruckName, rawData.TruckName{readIdx+j+1})
                    % break the for loop
                    break
                    % This leaves j at the number of additional matching lines beyone readIdx
                end
            catch ex
                % If the error was not because we reached the end of the matrix
                if ~strcmp(ex.identifier, 'MATLAB:badsubscript')
                    % Rethrow the original exception
                    rethrow(ex)
                end
                % Otherwise ignor the error, as it will leave j at the correct value
                % Break out of the loop as we're at the end
                break
            end
        end
        
        % Print the data out to one line of the output cell array
        % Pass in only the 2 - 5 lines that need matching
        try
            % Try to match the parameters together
            matched(writeIdx,:) = createLine(d, numParams, ExtIDList, ...
                rawData.ExtID(readIdx:readIdx+j), rawData.DataValue(readIdx:readIdx+j));
        catch ex
            % If there was an error, move on to the next line
            if strcmp(ex.identifier, 'EventProcessor:matchEventData:createLine:DuplicateData')
                readIdx = readIdx + j + 1;
                % Don't increment the writeIdx so that this line get re-written
                % Continue to the next itaration
                continue
            elseif strcmp(ex.identifier, 'EventProcessor:matchEventData:createLine:MatchingFailure')
                % In reality, this exception is thrown when a truly unknown thing is
                % happening. For now, just ignor it like above and continue
                readIdx = readIdx + j + 1;
                continue
            else
                % Otherwise, rethrow the original exception as it is really unknown
                rethrow(ex)
            end
        end
        % Increment readIdx the appropriate number of lines
        readIdx = readIdx + j + 1;
        % Add one to the writeIdx
        writeIdx = writeIdx + 1;
        
    end
    
    % Trim the empty cells that were left behind on the bottom of "matched"
    matched = matched(1:writeIdx-1,:);
    
end

function line = createLine(d, numParams, ExtIDList, ExtID, DataValue)
%   This takes in the separate parameter values for a "set" of parameters that were
%   broadcast and writes them into a single line
%   
%   ExtID is a small numeric array with the ExtID value, e.g., [0 1 2 3 4] or [2 4] for
%   partial data sets
%   DataValue is a small numberic array with the data values, e.g., [20 1.23 5543 0 0] or
%   [5543 0] for partial sets
    
    % Initalize output and fill in the metadata
    line = cell(1,numParams+5);
    line{1} = d.datenum;
    line{2} = d.ECMRunTime;
    line{3} = d.TruckName;
    line{4} = d.Family;
    line{5} = d.Software;
    
    % For each parameter that should be present (each ExtID that should have data)
    for i = 1:numParams
        % Get the index of the ExtID
        idx = ExtID==ExtIDList(i);
        % If it is in the list of data passed in
        if sum(idx) == 1
            % Add it to the appropriate location
            line{5+i} = DataValue(idx);
        elseif sum(idx) == 0
            % Else set that location to a NaN
            line{5+i} = NaN;
        else % there was more than one match
            % Check to see if there is duplicate data present in the database
            if length(unique(DataValue)) < length(DataValue)
                % Throw an appropriate error for duplicate data
                error('EventProcessor:matchEventData:createLine:DuplicateData', ...
                      'There was duplicate data entries in the database, failed to properly match input');
            else
                % Throw an error that this was an unknown failure type
                % Getting here means there is really some type of unhandled exception
                % happening
                error('EventProcessor:matchEventData:createLine:MatchingFailure', ...
                      'There was more than one unique value with ExtID %.0f passed in. Failed to recover from the case of duplicated data points.', i);
            end
        end
    end
    
    % Output would be either
    % {datenum, ECMRunTime, TruckName, Engine, Software, 20, 1.23, 5543, 0, 0} or
    % {datenum, ECMRunTime, TruckName, Engine, Software, NaN, NaN, 5543, NaN, 0}
    % depending on which of the example inputs was passed into the function
    
end

% Copied from getEventData, slightly modified to remove the ExtID filter condition
function where = makeWhere(xseid, args)
    % This function processses the input options and generates the proper WHERE clause
    
    % Evaluate the xseid that was passed in 
    if xseid > 65535 % >= 2^16
        % Then this must be an xSEID, decompose into SEID and ExtID for the where clause
        % [seid, extid] = decomposexSEID(xseid); %%%%%%%%%%%%%%%%
        [seid, ~] = decomposexSEID(xseid);
    else
        % Either an xseid < 2^16 was passed in (meaning that the ExtID = 0, the default)
        % Or a seid was passed in with a non-zero ExtID specified
        seid = xseid;
        % extid = args.ExtID; %%%%%%%%%%%%%%%
    end
    
    % Start the where clause with the Public Data ID
    %where = sprintf('WHERE [SEID] = %.0f And [ExtID] = %.0f',seid, extid); %%%%%%%%%%%%%
    where = sprintf('WHERE [SEID] = %.0f',seid);
    
    %% Add filtering based on the EMBFlag if needed
    if args.emb == 0
        % Return only values without EMB, this is the default option
        where = strcat(where, ' And [EMBFlag] = 0');
    elseif args.emb == 1
        % Return only values with EMB
        where = strcat(where, ' And [EMBFlag] = 1');
    end
    % Otherwise, if emb is set to a NaN or any other number erroneously, don't filter on
    % the EMBFlag at all
    
    %% Add filtering based on the TripFlag if needed
    if args.trip == 0
        % Return only the values that weren't from a test trip, this is the default
        where = strcat(where, ' And [TripFlag] = 0');
    elseif args.trip == 1
        % Return only the values that were from a test trip
        where = strcat(where, ' And [TripFlag] = 1');
    end
    % Otherwise, if trip is set to NaN or any other number erroneously, don't filter on
    % the TripFlag at all
    
    %% Add filtering based on the engine family desired
    % Old Manual filtering for Pacific
    switch args.family
        case 'all' % Default, Do nothing, there should be no additional filtering for this
        case 'x1' % Filter only X1 trucks out
            % Add this phrase to the end of the WHERE clause
            where = strcat(where, ' And [Family] = ''X1''');
        case 'x3' % Filter only X2/3 trucks out
            % Add this phrase to the end of the WHERE clause
            where = strcat(where, ' And ([Family] = ''X2'' Or [Family] = ''X3'')');
        case 'black' % Filter only black trucks out
            % Add this phrase to the end of the WHERE clause
            where = strcat(where, ' And [Family] = ''Black''');
        case 'Atlantic'
            where = strcat(where, ' And [Family] = ''Atlantic''');
        otherwise
            % Throw an error as there was invalid input
            error('Capability:matchEventData:InvalidFamily','''family'' input must be either ''all'', ''x1'', ''x3'', or ''black''');
    end
    
    %% Add filtering based on the truck type desired
    switch args.truck
        case 'all' % Default, Do nothing, there whould be no additional filtering
        case 'field' % Field Test Trucks Only
            % Filter by only trucks whos name begins with 'F_'
            where = strcat(where, ' And LEFT([TruckName],2) = ''F_''');
        case 'eng' % Engineering Trucks Only
            % Filter by only trucks whos name begins with 'ENG_'
            where = strcat(where, ' And LEFT([TruckName],4) = ''ENG_''');
        otherwise
            % Throw an error as there was invalid input
            error('Capability:matchEventData:InvalidTruck','''truck'' input must be either ''all'', ''field'', or ''eng''');
    end
    
    %% Add filtering by the date
    % If the input is not an empty set (the default to indicate no software filter)
    if ~isempty(args.date)
        % If the array has a length of two
        if length(args.date) == 2
            % If the first value of the two passed in was a NaN ([NaN 734929])
            if isnan(args.date(1)) && ~isnan(args.date(2)) % Keep evenything up to the second date
                where = sprintf('%s And [datenum] < %f',where,args.date(2));
            % If the second value of the two passed in was a NaN ([734929 NaN])
            elseif isnan(args.date(2)) && ~isnan(args.date(1)) % Keep everything after the fisrt date
                where = sprintf('%s And [datenum] > %f',where,args.date(1));
            elseif ~isnan(args.date(2)) && ~isnan(args.date(1)) % Nither was a NaN, use both value to filter between the range
                where = sprintf('%s And [datenum] Between %f And %f',where,args.date(1),args.date(2));
            % else both were a NaN, don't do any filtering
            end
        else
            error('Capability:matchEventData:InvalidInput', 'Invalid input for property ''date''')
        end
    end
    
    %% Add filtering by the software version
    % If the input is not an empty set (the default to indicate no software filter)
    if ~isempty(args.software)
        % Work based on the length of the input (either one value or two)
        switch length(args.software)
            % If there was only one input to indicate software equals this value
            case 1
                % Add the criteria where the software must be equal to this value
                where = sprintf('%s And [CalibrationVersion] = %0.f',where,args.software);
                
            % If there were two inputs to the software field
            case 2
                % If both entries were a NaN, don't do any filtering by software (like [])
                if isnan(args.software(1)) && isnan(args.software(2))
                    % Don't add any filtering to the SQL string, do nothing
                
                % If the first value of the two values passed in was an NaN ( [NaN 413006])
                elseif isnan(args.software(1)) % Keep everything before the second software version
                    where = sprintf('%s And [CalibrationVersion] <= %.0f',where,args.software(2));
                
                % If the second value of the two values passed in was an NaN ( [413006 NaN])
                elseif isnan(args.software(2)) % Keep everything after the fisrt software version
                    where = sprintf('%s And [CalibrationVersion] >= %.0f',where,args.software(1));
                
                % Nither was an NaN, both start and end filters were valid filter criteria
                else % Keep all values between the two software ranges
                    where = sprintf('%s And [CalibrationVersion] Between %.0f and %.0f', ...
                                     where, args.software(1), args.software(2));
                end
                
            % Too many software filters specified
            otherwise 
                error('Capability:matchEventData:InvalidInput', 'Invalid input for property ''software''')
        end
    end
    
    %% Add filtering by the data value itself
    % If the input is not an empty set (the default to indicate no value filtering)
    if~isempty(args.values)
        switch length(args.values)
            case 2 % There were two entries specified
                if isnan(args.values(1)) && ~isnan(args.values(2))
                    % Filtering by values smaller than ValB
                    where = sprintf('%s And [DataValue] <= %g',where,args.values(2));
                elseif ~isnan(args.values(1)) && isnan(args.values(2))
                    % Filtering by values larger than ValA
                    where = sprintf('%s And [DataValue] >= %g',where,args.values(1));
                elseif ~isnan(args.values(1)) && ~isnan(args.values(2))
                    % Filtering by values between ValA and ValB
                    where = sprintf('%s And [DataValue] Between %g And %g',where,args.values(1),args.values(2));
                end % else both NaN, don't do any filtering either
            case 3 % There were three entries specified
                % Filtering by values smaller than ValA and greater than ValB
                where = sprintf('%s And ([DataValue] <= %g Or [DataValue] >= %g)',where,args.values(1),args.values(3));
            otherwise
                error('Capability:matchEventData:InvalidInput', 'Invalid input for property ''values''')
        end
    end
    
    %% Add filtering by the Engine Family
    % If the input is not the default of {''}
    if ~isempty(args.engfam{1})
        % If any of the families specified is 'All', no filtering needed
        if ~any(strcmp('All',args.engfam))
            % Start the where
            where = sprintf('%s And (',where);
            % For each family name specified
            for i = 1:length(args.engfam)
                % Build up the where
                if i==length(args.engfam)
                    % Last one (or only one in the case of length = 1)
                    where = sprintf('%s[Family] = ''%s'')',where,args.engfam{i});
                else
                    % First or middle one
                    where = sprintf('%s[Family] = ''%s'' Or ',where,args.engfam{i});
                end
            end
        end
        % No filtering is needed for 'All' families
    end
    
    %% Add filtering by the Vehicle Type
    % If the input is not the default of {''}
    if ~isempty(args.vehtype{1})
        % If any of the families specified is 'All', no filtering needed
        if ~any(strcmp('All',args.vehtype))
            % Start the where
            where = sprintf('%s And (',where);
            % For each family name specified
            for i = 1:length(args.vehtype)
                % Build up the where
                if i==length(args.vehtype)
                    % Last one (or only one in the case of length = 1)
                    where = sprintf('%s[TruckType] = ''%s'')',where,args.vehtype{i});
                else
                    % First or middle one
                    where = sprintf('%s[TruckType] = ''%s'' Or ',where,args.vehtype{i});
                end
            end
        end
        % No filtering is needed for 'All' vehicle types
    end
    
    %% Add filtering by the Vehicle Name
    % If the input is not the default of {''}
    if ~isempty(args.vehicle{1})
        % If any of the families specified is 'All', no filtering needed
        if ~any(strcmp('All',args.vehicle))
            % Start the where
            where = sprintf('%s And (',where);
            % For each family name specified
            for i = 1:length(args.vehicle)
                % Build up the where
                if i==length(args.vehicle)
                    % Last one (or only one in the case of length = 1)
                    where = sprintf('%s[TruckName] = ''%s'')',where,args.vehicle{i});
                else
                    % First or middle one
                    where = sprintf('%s[TruckName] = ''%s'' Or ',where,args.vehicle{i});
                end
            end
        end
        % No filtering is needed for 'All' vehicles
    end
    
    %% Add filtering by the Engine Rating
    % If the input is not the default of {''}
    if ~isempty(args.rating{1})
        % If any of the families specified is 'All', no filtering needed
        if ~any(strcmp('All',args.rating))
            % Start the where
            where = sprintf('%s And (',where);
            % For each family name specified
            for i = 1:length(args.rating)
                % Build up the where
                if i==length(args.rating)
                    % Last one (or only one in the case of length = 1)
                    where = sprintf('%s[Rating] = ''%s'')',where,args.rating{i});
                else
                    % First or middle one
                    where = sprintf('%s[Rating] = ''%s'' Or ',where,args.rating{i});
                end
            end
        end
        % No filtering is needed for 'All' vehicles
    end
    
end

function [seid, extid] = decomposexSEID(xSEID)
% Decompese the xSEID into separate SEID and ExtID parts
    % Pull the ExtID off the front of the bytes (shift 2 bytes right)
    extid = floor(xSEID/65536);
    % Use the result to get back the SEID
    seid = xSEID - extid*65536;
end
