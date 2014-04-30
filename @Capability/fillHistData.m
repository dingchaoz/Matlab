function fillHistData(obj)
%Pulls data from database given critera in filt and sets in box object
%   Given the filtering criteria of the current settings in the filt strucutre, this will
%   determine whether there is Min/Max or Event Driven data, fetch the appropriate data
%   set, and place it into the hist object.
%   
%   Usage: fillHistData(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for new vehcile filtering
    
    % Pull out the filtering values from the filt structure
    sw = obj.filt.software;
    date = obj.filt.date;
    trip = obj.filt.trip;
    emb = obj.filt.emb;
    % New filtering critera
    engfam = obj.filt.engfam;
    vehtype = obj.filt.vehtype;
    vehicle = obj.filt.vehicle;
    
    % Two main paths: Min/Max data or Event Driven data
    
    % If the ExtID is a NaN
    if isnan(obj.filt.ExtID)
        
        % Get the public data id
        pdid = obj.getPublicDataID(obj.filt.CriticalParam);
        
        % Try to fetch the data with the specified filtering conditions
        d = obj.getMinMaxData(pdid,'software',sw,'date',date,'trip',trip,'emb',emb,'grouping',4,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        % If there was no data for this parameter
        if isempty(d)
            % Throw an error so that the GUI can react and execution of this code stops
            error('Capability:fillHistData:NoDataFound', 'No data found for the specified filtering conditions.');
        end
        
        % If no thresholds are specified, plot Min and Max data
        if isnan2(obj.filt.LSL) && isnan2(obj.filt.USL)
            % Plot both min and max data together
            obj.hist.Data = [d.DataMin;d.DataMax];
            % Set the label for the data set that is being plotted
            obj.hist.DataType = 'Min and Max Data';
        % If this is a LSL diagnostic
        elseif isnan2(obj.filt.USL)
            % Plot only the min data
            obj.hist.Data = d.DataMin;
            % Set the label for the data set that is being plotted
            obj.hist.DataType = 'Min Data';
        % If this is an USL diagnostic
        elseif isnan2(obj.filt.LSL)
            % Plot only the max data
            obj.hist.Data = d.DataMax;
            % Set the label for the data set that is being plotted
            obj.hist.DataType = 'Max Data';
        % Must be a two-sided diagnostic
        else
            % Plot both min and max data together
            obj.hist.Data = [d.DataMin;d.DataMax];
            % Set the label for the data set that is being plotted
            obj.hist.DataType = 'Min and Max Data';
        end
        
    else % ExtID ~= NaN
        % Get the SEID and ExtID
        SEID = obj.filt.SEID;
        ExtID = obj.filt.ExtID;
        
        % Try to fetch the data with the specified filtering conditions
        d = obj.getEventData(SEID,ExtID,'software',sw,'date',date,'trip',trip,'emb',emb,'grouping',4,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        
        % If there was no data for this parameter
        if isempty(d)
            % Throw an error so that the GUI can react and execution of this code stops
            error('Capability:fillHistData:NoDataFound', 'No data found for the specified filtering conditions.');
        end
        
        % Add the plotting data to the box object
        obj.hist.Data = d.DataValue;
        % Set the label for the data set that is being plotted
        obj.hist.DataType = 'Event Driven Data';
    end
end

% Copied directly from @MinMaxProcessor.makeBoxPlots
function r = isnan2(a)
    % If a string is passed in, this will return a single value as opposed the the default
    % isnan function with returns a result for each character in the string
    
    % If a sting is passed in
    if ischar(a)
        % A cannot be a NaN
        r = 0;
    % If a is a number
    elseif isnumeric(a)
        % If it is a NaN
        if isnan(a)
            % a is a NaN
            r = 1;
        else
            % a is not a NaN
            r = 0;
        end
    else % a is another datatype, set r = 0;
        r = 0;
    end
end
