function [matched, header] = matchMinMaxData(obj, publicDataID)
%Timegrid the specified parameters together for each MinMax data set
%   This will take a specified set of MinMax parameter PublicDataID values and "time-gird"
%   them together, matching data from different parameters on a single "key-off" event to
%   a singular "line" in the ouput
%   
%   Inputs ---
%   publicDataID: vector of Public Data IDs that should be timegridded together
%   
%   Outputs---
%   matched:      Cell array of data matched to each other, columns 6 and later contain the
%                   actual data values
%   
%   Original Version - Chris Remington - March 23, 2012
%   Revised - Chris Remington - April 7, 2014
%     - Moved to the use of tryfetch from just fetch to commonize error handling
    
    % Get the listing of all ConditionsIDs and meta-data
    a = obj.tryfetch(['SELECT [ConditionID],[datenum],[ECMRunTime],[CalibrationVersion],[TruckName],[Family] ' ...
                             'FROM [dbo].[tblMinMaxDataConditions] LEFT OUTER JOIN [dbo].[tblTrucks] ' ...
                             'ON [tblMinMaxDataConditions].[TruckID] = [tblTrucks].[TruckID]'], 10000);
    
    % Set the total number of parameters that are to be timegridded
    numParams = length(publicDataID);
    
    % Generate the section of the where clause containing the desired PublicDataIDs
    for i = 1:numParams
        if i==1
            % For the first parameter, do it this way
            filterText = sprintf('WHERE ([PublicDataID] = %.0f ', publicDataID(i));
        elseif i==numParams
            % For the last one, do it this way
            filterText = [filterText  sprintf('Or [PublicDataID] = %.0f) ',publicDataID(i))];
        else
            % Append additional parameters to the end
            filterText = [filterText  sprintf('Or [PublicDataID] = %.0f ',publicDataID(i))];
        end
    end
    
    % Generate the sql statement
    sql = ['SELECT [PublicDataID], [DataMin], [DataMax], [ConditionID] ' ...
           'FROM [dbo].[tblMinMaxData] ' filterText];
    
    % Grab all the Min/Max data for the publicDataIDs specified
    data = obj.tryfetch(sql,100000);
    
    % Initalize the output
    matched = cell(length(a.ConditionID)+1, 5 + numParams*2);
    % {datenum | ECMRunTime | TruckName | Family | Software | data1 Min | data1Max | ... | dataN Min | dataN Min}
    
    % Create the header
    header = {'Timestamp', 'ECMRunTime', 'TruckName', 'Family', 'Software'};
    % Find the newest cal version present to use when getting the names of the parameters
    newestCal = max(a.CalibrationVersion);
    % Autopopulate the parameter names based on their publicDataIDs
    for i = 1:numParams
        % Get the parameter name for this publicDataID
        paramName = obj.getDataInfo(publicDataID(i), newestCal, 'Data');
        % Set its name in the header
        header{4+2*i} = [paramName ' Min'];
        header{5+2*i} = [paramName ' Max'];
    end
    
    % Set the writeIdx to 1
    writeIdx = 1;
    
    % Loop through all the ConditionIDs, finding the matches in the MinMax data
    for i = 1:length(a.ConditionID)
        
        % Find all data for this conditionID
        idx = data.ConditionID==a.ConditionID(i);
        
        % Pull out the data for that conditionID
        if ~any(idx)
            % There was no data for the conditionID, skip and move on
            continue
        end
        
        try
            % Add the metadata for this particular conditionID
            matched(writeIdx,1:5) = {a.datenum(i),a.ECMRunTime(i),a.TruckName{i},a.Family{i},a.CalibrationVersion(i)};
            % Add the actual MinMax data to the line
            matched(writeIdx,6:end) = createLine(publicDataID, data.PublicDataID(idx), data.DataMin(idx), data.DataMax(idx));
            % Increment writeIdx
            writeIdx = writeIdx + 1;
        catch ex
            % Just skip this, don't increment the writeIdx
            continue
        end
    end
    
    % Trim any blanks from the end
    matched = matched(1:(writeIdx-1),:);
end

function line = createLine(order, PublicDataID, DataMin, DataMax)
%Parses raw lines of MinMax data and grid the parameters together in order
%   Pull out the individual parameters and place them in the correct location specified by
%   the order variable
%   
%   Inputs -
%   order:        The vector of publicDataIDs passed into matchMinMaxData
%   PublicDataID: PublicDataID values for each MinMax data point
%   DataMin:      The DataMin value for each MinMax data point
%   DataMax:      The DataMax value for each MinMax data point
%   
%   Outputs -
%   line:         The gridded Min/Max by conditionID
%   
    
    % Initalize line
    line = cell(1,2*length(order));
    
    % For each publicDataID in order
    for i = 1:length(order)
        % Look for a match in the data passed in
        idx = order(i)==PublicDataID;
        % If there was no match
        if ~any(idx)
            % Set the Min and Max to a NaN
            line{2*i-1} = NaN;
            line{2*i} = NaN;
        elseif sum(idx) > 1
            % There were too many matches
            % Throw an error
            error('Capability:matchMinMaxData:MatchingError', ...
                 ['There was more than one instance of an identical parameter found in the data. %s' ...
                  'Lilely cause is duplicate MinMax data is present in the database.']);
        else
            % Add the min and max values to the correct place on the line
            line{2*i-1} = DataMin(idx);
            line{2*i} = DataMax(idx);
        end
    end
end
