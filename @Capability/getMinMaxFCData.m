function [data] = getMinMaxFCData(obj, pdid, varargin)
%Pull MinMax data from the database
%   Pull MinMax data from the database. Only return data the meets all of the optional
%   specified data filters.
%   
%   Usage: data = getMinMaxData(publicDataID, property, value,...)
%   
%   For example,
%   data = getMinMaxData(28, 'family', 'x1', 'software', [510001])
%       This will return the data from Public Data ID = 28 (Engine_Run_Time) for trucks
%       with an X1 engine and software of 510001.
%   
%   Inputs ---
%   pdid:      Public Data ID of the parameter
%   varargin:  listing of properties and their values. (see below)
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
%              'fields'    Specified the fields of data to retrieve
%                          {''}            - Retrieve all columns with the data (Default)
%                          {'All'}         - Retrieve all columns with the data
%                          {'col1', ...}   - Retrieve the specified columns with the data
%   
%              'valuemin'  Specifies the filtering based on the [DataMin] of the Min/Max data point
%                          []              - No filtering by the DataMin (Default)
%                          [NaN NaN]       - Analogous to an empty set above, no filtering
%                          [NaN ValB]      - Keep values <= ValB
%                          [ValA NaN]      - Keep values >= ValA
%                          [ValA ValB]     - Keep values between ValA and ValB
%                          [ValA NaN ValB] - Keep values <= ValA or >= ValB
%   
%              'valuemax'  Specifies the filtering based on the [DataMax] of the Min/Max data point
%                          []              - No filtering by the DataMin (Default)
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
%              %%%%%%%%%%%%%%%%%%%%%%%%%%%% Antiquated Field %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              'grouping'  Specifies the columns of data to SELECT depending on the need
%                          NaN             - Returns all columns (Default)
%                          0               - Returns DataMin/Max and CalibrationVersion
%                          1               - Returns DataMin/Max and TruckName
%                          2               - Returns DataMin/Max and Family
%                          3               - Returns DataMin/Max and datenum
%                          4               - Returns DataMin/Max only (for histograms)
%   
%   Outputs ---
%   data:      Structure of data straight from the database toolbox
%   
%   Original Version - Dingchao Zhang - March 20, 2015
%   Revised - Dingchao Zhang - June 4, 2015
%     - Added lines to excluding certain dates when querying fault code
%     data
    
    %% Process the inputs
    % Creates a new input parameter parser object to parse the inputs arguments
    p = inputParser;
    % Add the four properties and their default falues
    p.addParamValue('family', 'all', @ischar)%antiquated
    p.addParamValue('truck', 'all', @ischar)%antiquated
    p.addParamValue('software', [], @isnumeric)
    %if there is only include dates input by user, generate one date array
    % if exclude start date or exclude to date is missing
    %if ~isfield(obj.filt,'exFromDateString')|~isfield(obj.filt,'exToDateString')
    if strcmp(varargin(3),'date')
      % then add only one date array  
      p.addParamValue('date', [], @isnumeric)
    % if exclude start date and exclude to date are both existing
    %elseif ~isempty(obj.filt.exFromDateString)& ~isempty(obj.filt.exToDateString)
    elseif strcmp(varargin(3),'date_a')
       % add two date array, date_a and date_b
       p.addParamValue('date_a', [], @isnumeric)
       p.addParamValue('date_b', [], @isnumeric)
    end
    p.addParamValue('emb', 0, @isnumeric)
    p.addParamValue('trip', 0, @isnumeric)
    p.addParamValue('grouping', NaN, @isnumeric)%antiquated
    p.addParamValue('valuemin', [], @isnumeric)
    p.addParamValue('valuemax', [], @isnumeric)
    p.addParamValue('fields', {''}, @iscellstr)
    p.addParamValue('engfam', {''}, @iscellstr)
    p.addParamValue('vehtype', {''}, @iscellstr)
    p.addParamValue('vehicle', {''}, @iscellstr)
    p.addParamValue('rating', {''}, @iscellstr)
    
    % Parse the actual inputs passed in
    p.parse(varargin{:});
    
    %% Generate the start of the SELECT statement
    switch p.Results.grouping
        case 0 % Select data and software version
            select = 'SELECT [DataMin], [DataMax], [CalibrationVersion]';
        case 1 % Select data and truck name
            select = 'SELECT [DataMin], [DataMax], [TruckName]';
        case 2 % Select data and engine family
            select = 'SELECT [DataMin], [DataMax], [Family]';
        case 3 % Select data and Matlab serial date number
            select = 'SELECT [DataMin], [DataMax], [datenum]';
        case 4 % Select only the data (for histograms)
            select = 'SELECT [DataMin], [DataMax]';
        otherwise % NaN or anything else, select all the columns
            select = 'SELECT [datenum],[ECMRunTime],[DataMin],[DataMax],[TruckName],[Family],[CalibrationVersion],[ConditionID]';
    end
    
    %% Create the SELECT based on the desired fields (overrides grouping if specified)
    % Check is a specified field list was passed in
    if ~isempty(p.Results.fields{1})
        % If any of the fields specified is 'All', do them all
        if ~any(strcmp('All',p.Results.fields))
            % Start the where
            select = 'SELECT ';
            % For each family name specified
            for i = 1:length(p.Results.fields)
                % Build up the where
                if i==length(p.Results.fields)
                    % Last one (or only one in the case of length = 1)
                    select = sprintf('%s[%s]',select,p.Results.fields{i});
                else
                    % First or middle one
                    select = sprintf('%s[%s],',select,p.Results.fields{i});
                end
            end
        else
            % Select everything
            select = 'SELECT [datenum],[ECMRunTime],[DataMin],[DataMax],[TruckName],[Family],[TruckType],[Rating],[CalibrationVersion],[ConditionID]';
        end
    elseif isnan(p.Results.grouping)
        % Select all the fields (Default)
        select = 'SELECT [datenum],[ECMRunTime],[DataMin],[DataMax],[TruckName],[Family],[TruckType],[Rating],[CalibrationVersion],[ConditionID]';
    end
    
    %% Generate the WHERE clause
    where = makeWhere(pdid, p.Results);
    
    %% Fetch the data
    % Formulate the entire SQL query for Pacific with its two archived databases
    if strcmp(obj.program, 'HDPacific')
        sql = [select ' FROM [PacificArchive].[dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            select ' FROM [PacificArchive2].[dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            select ' FROM [dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where];
    % Formulate the entire SQL query for Vanguard with its archived database
    elseif strcmp(obj.program, 'Vanguard')
        sql = [select ' FROM [VanguardArchive].[dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where ' UNION ALL ' ...
            select ' FROM [dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where];
    % Formulate the entire SQL query for other prgrams
    else
        sql = [select ' FROM [dbo].[tblMinMaxData] LEFT OUTER JOIN [dbo].[tblTrucks] ON ' ...
            '[tblMinMaxData].[TruckID] = [tblTrucks].[TruckID] ' where ...
            ' ORDER BY [TruckName], [datenum] ASC'];
    end
         
    % Move to the use of the common tryfetch to get the data
    data = obj.tryfetch(sql,100000);
    
           
    % Generate the select statement for FC matches
    
    % Create the head of the SQL query
    selectfc_head = 'SELECT DISTINCT t3.TruckName, t1.[CalVersion], t1.Date,t1.abs_time,t1.[ActiveFaultCode], t1.[ECMRunTime], t1.TruckID, t2.*,t3.[Family],t3.[TruckType] FROM (SELECT * FROM dbo.FC';
    
    % Create the tail of the SQL query
    selectfc_tail = ['AS t2 ON t1.[CalVersion] = t2.CalibrationVersion AND t1.TruckID = t2.TruckID LEFT JOIN dbo.tbltrucks AS t3 ON t1.[Truck_Name] = t3.TruckName ' where ...        
     ' AND (ABS(t1.abs_time - t2.datenum) <= 0.5)'];
 
    % Combine the head, body, tail together to form the SQL query %
%    if isnan(obj.dot.USL) && isnan(obj.dot.LSL)
%        data.fc = ([]);
   
   if ~isnan(obj.filt.USL)
%        sql_fc = [selectfc_head ' WHERE [Active Fault Code] = ' num2str(obj.filt.FC) ' ) AS t1 INNER JOIN' ...
%        '(SELECT * FROM dbo.tblMinMaxData WHERE PublicDataID = ' num2str(pdid) ' AND DataMax > ' num2str(obj.filt.USL) ' )' selectfc_tail];
   
        % Option 2 to query all fault code though diagnostics made decision
      % within limits
       sql_fc = [selectfc_head ' WHERE [ActiveFaultCode] = ' num2str(obj.filt.FC) ' ) AS t1 INNER JOIN' ...
       '(SELECT * FROM dbo.tblMinMaxData WHERE PublicDataID = ' num2str(pdid) ' )' selectfc_tail];
       % Add the FC match results to data.fc structure
       data.fc = obj.tryfetch(sql_fc,100000);
%        try
%     % Fill the data into the dot object
%        handles.c.fillDotData(group,group2)
%        catch ex
%            if ~isempty(ex.identifier)
%            data.fc = ([]);
%            end
%        end
   elseif ~isnan(obj.filt.LSL)
%        sql_fc = [selectfc_head ' WHERE [Active Fault Code] = ' num2str(obj.filt.FC) ' ) AS t1 INNER JOIN' ...
%        '(SELECT * FROM dbo.tblMinMaxData WHERE PublicDataID = ' num2str(pdid) ' AND DataMin < ' num2str(obj.filt.LSL) ' )' selectfc_tail];
   
         % Option 2 to query all fault code though diagnostics made decision
      % within limits
       sql_fc = [selectfc_head ' WHERE [ActiveFaultCode] = ' num2str(obj.filt.FC) ' ) AS t1 INNER JOIN' ...
       '(SELECT * FROM dbo.tblMinMaxData WHERE PublicDataID = ' num2str(pdid) ' )' selectfc_tail];
       % Add the FC match results to data.fc structure
      data.fc = obj.tryfetch(sql_fc,100000);
        
   end
            
    
   
    
end  

function where = makeWhere(pdid, args)
    % This function processses the input options and generates the proper WHERE clause
    
    % Start the where clause with the Public Data ID
    where = sprintf('WHERE [PublicDataID] = %.0f',pdid);
    
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
        otherwise
            % Throw an error as there was invalid input
            error('Capability:getMinMaxData:InvalidFamily','''family'' input must be either ''all'', ''x1'', ''x3'', or ''black''');
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
            error('Capability:getMinMaxData:InvalidTruck','''truck'' input must be either ''all'', ''field'', or ''eng''');
    end
    
    %% Add filtering by the date
    % If the input is not an empty set (the default to indicate no software filter)
    if isfield(args,'date')
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
                error('Capability:getMinMaxData:InvalidInput', 'Invalid input for property ''date''')
            end
        end
   elseif isfield(args,'date_a')& isfield(args,'date_b')
      if ~isempty(args.date_a) &  ~isempty(args.date_b)
            % If the array has a length of two
            %if length(args.date_a) == 2 & length(args.date_b) == 2
                if ~isnan(args.date_a(1)) && length(args.date_a) == 2
                    where = sprintf('%s And ([datenum] Between %f And %f',where,args.date_a(1),args.date_a(2));      
                elseif length(args.date_a) == 1
                    %where = sprintf('%s And ([datenum] >= %f',where,args.date_a(1));
                    where = where;
                elseif isnan(args.date_a(1)) && length(args.date_a) == 2
                    where = sprintf('%s And ([datenum] <= %f',where,args.date_a(2));
                end
                if length(args.date_b) == 2 && length(args.date_a) == 2
                    where = sprintf('%s Or [datenum] Between %f And %f)',where,args.date_b(1),args.date_b(2));
                elseif length(args.date_a) == 1
                    where = sprintf('%s And [datenum] Between %f And %f',where,args.date_b(1),args.date_b(2));
                else
                    where = strcat(where,')');
                end   
      else
             error('Capability:getMinMaxData:InvalidInput', 'Invalid input for property ''date''')
            %end
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
                error('Capability:getMinMaxData:InvalidInput', 'Invalid input for property ''software''')
        end
    end
    
    %% Add filtering by the DataMin value itself
    % If the input is not an empty set (the default to indicate no value filtering)
    if~isempty(args.valuemin)
        switch length(args.valuemin)
            case 2 % There were two entries specified
                if isnan(args.valuemin(1)) && ~isnan(args.valuemin(2))
                    % Filtering by values smaller than ValB
                    where = sprintf('%s And [DataMin] <= %g',where,args.valuemin(2));
                elseif ~isnan(args.valuemin(1)) && isnan(args.valuemin(2))
                    % Filtering by values larger than ValA
                    where = sprintf('%s And [DataMin] >= %g',where,args.valuemin(1));
                elseif ~isnan(args.valuemin(1)) && ~isnan(args.valuemin(2))
                    % Filtering by values between ValA and ValB
                    where = sprintf('%s And [DataMin] Between %g And %g',where,args.valuemin(1),args.valuemin(2));
                end % else both NaN, don't do any filtering either
            case 3 % There were three entries specified
                % Filtering by values smaller than ValA and greater than ValB
                where = sprintf('%s And ([DataMin] <= %g Or [DataMin] >= %g)',where,args.valuemin(1),args.valuemin(3));
            otherwise
                error('Capability:getMinMaxData:InvalidInput', 'Invalid input for property ''valuemin''')
        end
    end
    
    %% Add filtering by the DataMax value itself
    % If the input is not an empty set (the default to indicate no value filtering)
    if~isempty(args.valuemax)
        switch length(args.valuemax)
            case 2 % There were two entries specified
                if isnan(args.valuemax(1)) && ~isnan(args.valuemax(2))
                    % Filtering by values smaller than ValB
                    where = sprintf('%s And [DataMax] <= %g',where,args.valuemax(2));
                elseif ~isnan(args.valuemax(1)) && isnan(args.valuemax(2))
                    % Filtering by values larger than ValA
                    where = sprintf('%s And [DataMax] >= %g',where,args.valuemax(1));
                elseif ~isnan(args.valuemax(1)) && ~isnan(args.valuemax(2))
                    % Filtering by values between ValA and ValB
                    where = sprintf('%s And [DataMax] Between %g And %g',where,args.valuemax(1),args.valuemax(2));
                end % else both NaN, don't do any filtering either
            case 3 % There were three entries specified
                % Filtering by values smaller than ValA and greater than ValB
                where = sprintf('%s And ([DataMax] <= %g Or [DataMax] >= %g)',where,args.valuemax(1),args.valuemax(3));
            otherwise
                error('Capability:getMinMaxData:InvalidInput', 'Invalid input for property ''valuemax''')
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