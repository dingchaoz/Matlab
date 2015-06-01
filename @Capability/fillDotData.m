function fillDotData(obj, groupCode, group2Code)
%Pulls data from database given critera in filt and sets in dot object
%   Given the filtering criteria of the current settings in the filt strucutre, this will
%   determine whether there is Min/Max or Event Driven data, fetch the appropriate data
%   set, and place it into the dot object.
%   
%   Usage: fillDotData(obj, groupCode, group2Code)
%   
%   Inputs - 
%   groupCode:  Integer representing what data to group the box plots by
%               0:  Group by software version
%               1:  Group by truck name
%               2:  Group by engine family
%               3:  Group by month
%   group2Code: Integer representingthe second group to plot using
%               -1: No second grouping
%               0:  Group by software version
%               1:  Group by truck name
%               2:  Group by engine family
%               3:  Group by month
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 3, 2012
%   Revised - Chris Remington - July 18, 2013
%     - Revised how the software group into is passed to the box plot function
%       so that is won't put out 8 digit cal versions in scientific notation
%   Revised - Chris Remington - February 4, 2014
%     - Added support for new vehcile filtering
%   Revised - Chris Remingotn - March 20, 2014
%     - Merged Sri's functions for the dot plot into the main code
%   Revised - Chris Remington - April 10, 2014
%     - Added functionality to plot the second grouping if desired
%   Revised -Dingchao Zhang - March 20, 2015
% Add the Fault Code matching data to the obg.dot object
%   Revised -Dingchao Zhang - April 6, 2015
% Add the Fault Code group data to the obg.dot.FaultCode.GroupData, 
% GroupOrder,Group2Data, Group2Order objects if required by grouping
%   Revised - Dingchao Zhang - May 29, 2015
%     - Added lines to query data by excluding a period of dates
 
    
    % Pull out the filtering values from the filt structure
    sw = obj.filt.software;
    date = obj.filt.date;
    trip = obj.filt.trip;
    emb = obj.filt.emb;
    % New filtering critera
    engfam = obj.filt.engfam;
    vehtype = obj.filt.vehtype;
    vehicle = obj.filt.vehicle;
    
    % If group2Code wasn't passed in
    if ~exist('group2Code','var')
        % Set it to -1 so it doesn't do anything
        group2Code = -1;
    end
    
    % Calculate the columns of data to select so only the required columns are selected
    % If MinMax
    if isnan(obj.filt.ExtID)
        % Do DataMin and DataMax columns
        fields = {'DataMin','DataMax'};
    else % Event Driven
        %Start with the DataValue column
        fields = {'DataValue'};
    end
    % Add on the first grouping
    fields = [fields,{getFieldName(groupCode)}];
    % Add the second grouping if it is selected and not the same as the first selection
    if group2Code ~= -1 && groupCode ~= group2Code
        fields = [fields,{getFieldName(group2Code)}];
    end
    
    % Two main paths: Min/Max data or Event Driven data
    
    % If the ExtID is a NaN
    if isnan(obj.filt.ExtID)
        
        % Get the public data id
        pdid = obj.getPublicDataID(obj.filt.CriticalParam);
        
        % Try to fetch the data with the specified filtering conditions
        %d = obj.getMinMaxData(pdid,'software',sw,'date',date,'trip',trip,'emb',emb,'grouping',groupCode,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        %if there is only include dates input by user, generate one date array
        % if exclude start date or exclude to date is missing
        if ~isfield(obj.filt,'exFromDateString')|~isfield(obj.filt,'exToDateString')
          d = obj.getMinMaxData(pdid,'software',sw,'date',date,'trip',trip,'emb',emb,'fields',fields,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        elseif ~isempty(obj.filt.exFromDateString)&& ~isempty(obj.filt.exToDateString)
          date_a = [date(1),datenum(obj.filt.exFromDateString)];
          date_b = [datenum(obj.filt.exToDateString),date(2)];
          d = obj.getMinMaxData(pdid,'software',sw,'date_a',date_a,'date_b',date_b,'trip',trip,'emb',emb,'fields',fields,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        end
        % If there was no data for this parameter
        if ~isfield(d,'DataMax')&& ~isfield(d,'DataMin')
            % Throw an error so that the GUI can react and execution of this code stops
            error('Capability:fillDotData:NoDataFound', 'No data found for the specified filtering conditions.');
        end
        
        % Add the Fault Code matching data to the obg.dot object
        if isfield(d,'fc')
          obj.dot.FaultCode = d.fc;
        else
          obj.dot.FaultCode = [];
        end
        
        % If no thresholds are specified, plot Min and Max data
        if isnan2(obj.dot.LSL) && isnan2(obj.dot.USL)
            % Plot both min and max data together
            obj.dot.Data = [d.DataMin;d.DataMax];
            % Set the label for the data set that is being plotted
            obj.dot.DataType = 'Min and Max Data';
            % Set the group data properly based on the groupCode
            assignGroupDataM(obj, d, groupCode, group2Code, true);
        % If this is a LSL diagnostic
        elseif isnan2(obj.dot.USL)
            % Plot only the min data
            obj.dot.Data = d.DataMin;
            % Set the label for the data set that is being plotted
            obj.dot.DataType = 'Min Data';
            % Set the group data properly based on the groupCode
            assignGroupDataM(obj, d, groupCode, group2Code, false);
        % If this is an USL diagnostic
        elseif isnan2(obj.dot.LSL)
            % Plot only the max data
            obj.dot.Data = d.DataMax;
            % Set the label for the data set that is being plotted
            obj.dot.DataType = 'Max Data';
            % Set the group data properly based on the groupCode
            assignGroupDataM(obj, d, groupCode, group2Code, false);
        % Must be a two-sided diagnostic
        else
            % Plot both min and max data together
            obj.dot.Data = [d.DataMin;d.DataMax];
            % Set the label for the data set that is being plotted
            obj.dot.DataType = 'Min and Max Data';
            % Set the group data properly based on the groupCode
            assignGroupDataM(obj, d, groupCode, group2Code, true);
        end
        
     
    else % ExtID ~= NaN
        % Get the SEID and ExtID
        SEID = obj.filt.SEID;
        ExtID = obj.filt.ExtID;
        
        % Try to fetch the data with the specified filtering conditions
        %d = obj.getEventData(SEID,ExtID,'software',sw,'date',date,'trip',trip,'emb',emb,'grouping',groupCode,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        d = obj.getEventData(SEID,ExtID,'software',sw,'date',date,'trip',trip,'emb',emb,'fields',fields,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        
        % If there was no data for this parameter
        if ~isfield(d,'DataValue')
            % Throw an error so that the GUI can react and execution of this code stops
            error('Capability:fillDotData:NoDataFound', 'No data found for the specified filtering conditions.');
        end
        
        % Add the plotting data to the box object
        obj.dot.Data = d.DataValue;
        % Set the label for the data set that is being plotted
        obj.dot.DataType = 'Event Driven Data';       
        % Add the Fault Code matching data to the obg.dot object
        if ~isempty(d.fc)
          obj.dot.FaultCode = d.fc;
        else
          obj.dot.FaultCode = [];
        end
        
         % Set the group data properly based on the groupCode
        assignGroupDataE(obj, d, groupCode, group2Code);
    end
end

% Copied directly from @EventProcessor.makeBoxPlots, just renamed
function assignGroupDataE(obj, d, groupCode, group2Code)
% Correctly assigns the group data based on the grouping code
    
    % Set the grouping based on the groupCode passed in
    switch groupCode
        case 0 % Group data by software version
            % Need to convert these to individual strings because software over 100000
            % causes %g to output group names in scientific notation confusing boxplot
            obj.dot.GroupData = cellstr(num2str(d.CalibrationVersion,'%.0f'));
            if ~isempty(obj.dot.FaultCode)
              obj.dot.FaultCode.GroupData = cellstr(num2str(obj.dot.FaultCode.CalVersion,'%.0f'));
            else
              obj.dot.FaultCode.GroupData = [];
            end
            % Set the group data to be the calibration version
            %obj.dot.GroupData = d.CalibrationVersion;
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
        case 1 % Group data by truck name
            % Set the group data to be the truck name
            obj.dot.GroupData = d.TruckName;
            if ~isempty(obj.dot.FaultCode)
               obj.dot.FaultCode.GroupData = obj.dot.FaultCode.TruckName;
            else
               obj.dot.FaultCode.GroupData = [];
            end
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
        case 2 % Group data by family
            % Set the group data to be the family
            obj.dot.GroupData = d.Family;
            if ~isempty(obj.dot.FaultCode)
               obj.dot.FaultCode.GroupData = obj.dot.FaultCode.Family;
            else
               obj.dot.FaultCode.GroupData = [];
            end
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
        case 3 % Group data by month
            %%% This was the old method, simple to understand, but took forever
            % Set the group data to be a string generated from the timestamp that
            % indicates the month that data was logged in
            %obj.dot.GroupData = cellstr([datestr(d.datenum, 'yy-mm_') datestr(d.datenum, 'mmmm yyyy')]);
            
            %%% Below is way faster than the above, but it is quite complex and obscure
            % Calculate the date vectors of all the serial date numbers
            vecs = datevec(d.datenum);
            if ~isempty(obj.dot.FaultCode)
               fcvecs = datevec(obj.dot.FaultCode.datenum);
            else
                fcvecs  =[];
            end
            % Calculate a unique number calculation based on the month and year, this will
            % be the group value for each individual data point
            obj.dot.GroupData = cellstr(num2str(vecs(:,1)+vecs(:,2)/20,'%.2f'));
            if ~isempty(fcvecs)
              obj.dot.FaultCode.GroupData = cellstr(num2str(fcvecs(:,1)+fcvecs(:,2)/20,'%.2f'));
            else 
              obj.dot.FaultCode.GroupData = [];
            end
            % Get the unique month and year combinations
            obj.dot.GroupOrder = flipud(unique(obj.dot.GroupData));
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.GroupOrder = flipud(unique(obj.dot.FaultCode.GroupData));
            else
              obj.dot.FaultCode.GroupOrder = [];
            end
            % Flush those out to fake date vectors
            uniqueYearMonthCalc = flipud(unique(vecs(:,1)+vecs(:,2)/20));
            if ~isempty(fcvecs)
              fcuniqueYearMonthCalc = flipud(unique(fcvecs(:,1)+fcvecs(:,2)/20));
            else
              fcuniqueYearMonthCalc = [];
            end
            labelDateVecs = [floor(uniqueYearMonthCalc) round(mod(uniqueYearMonthCalc,1)*20) ones(length(uniqueYearMonthCalc),4)];
            if ~isempty(fcuniqueYearMonthCalc)
              fclabelDateVecs = [floor(fcuniqueYearMonthCalc) round(mod(fcuniqueYearMonthCalc,1)*20) ones(length(fcuniqueYearMonthCalc),4)];
            else
              fclabelDateVecs = [];
            end
            % Pull the result in to make the text label strings
            obj.dot.Labels = strcat(cellstr(datestr(labelDateVecs, 'mmmm')),cellstr(datestr(labelDateVecs, ' yyyy')));
            if ~isempty(fclabelDateVecs)
              obj.dot.FaultCode.Labels = strcat(cellstr(datestr(fclabelDateVecs, 'mmmm')),cellstr(datestr(fclabelDateVecs, ' yyyy')));
            else
              obj.dot.FaultCode.Labels = [];
            end
            % As a side note, this fcn will give you unqie year/month combinations
            % unique(vecs(:,1:2), 'rows')
    end
    % Set the second grouping based on the group2Code passed in
    switch group2Code
        case -1 % No second grouping
            obj.dot.Group2Data = [];
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Data = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 0 % Group data by software version
            % Need to convert these to individual strings because software over 100000
            % causes %g to output group names in scientific notation confusing boxplot
            obj.dot.Group2Data = cellstr(num2str(d.CalibrationVersion,'%.0f'));
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = cellstr(num2str(obj.dot.FaultCode.CalVersion,'%.0f'));
            else
              obj.dot.FaultCode.Group2Data = [];
            end
            % Set the group data to be the calibration version
            %obj.dot.GroupData = d.CalibrationVersion;
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 1 % Group data by truck name
            % Set the group data to be the truck name
            obj.dot.Group2Data = d.TruckName;
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = obj.dot.FaultCode.TruckName;
            else
              obj.dot.FaultCode.Group2Data = [];
            end
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 2 % Group data by family
            % Set the group data to be the family
            obj.dot.Group2Data = d.Family;
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = obj.dot.FaultCode.Family;
            else 
               obj.dot.FaultCode.Group2Data =[];
            end
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 3 % Group data by month
            %%% This was the old method, simple to understand, but took forever
            % Set the group data to be a string generated from the timestamp that
            % indicates the month that data was logged in
            %obj.dot.Group2Data = cellstr([datestr(d.datenum, 'yy-mm_') datestr(d.datenum, 'mmmm yyyy')]);
            
                  %%% Below is way faster than the above, but it is quite complex and obscure
            % Calculate the date vectors of all the serial date numbers
            vecs = datevec(d.datenum);
            if ~isempty(obj.dot.FaultCode.GroupData)
               fcvecs = datevec(obj.dot.FaultCode.datenum);
            else
                fcvecs  =[];
            end
            % Calculate a unique number calculation based on the month and year, this will
            % be the group value for each individual data point
            obj.dot.Group2Data = cellstr(num2str(vecs(:,1)+vecs(:,2)/20,'%.2f'));
            if ~isempty(fcvecs)
              obj.dot.FaultCode.Group2Data = cellstr(num2str(fcvecs(:,1)+fcvecs(:,2)/20,'%.2f'));
            else 
              obj.dot.FaultCode.Group2Data = [];
            end
            % Get the unique month and year combinations
            obj.dot.Group2Order = flipud(unique(obj.dot.Group2Data));
            if ~isempty(obj.dot.FaultCode.Group2Data)
              obj.dot.FaultCode.Group2Order = flipud(unique(obj.dot.FaultCode.Group2Data));
            else
              obj.dot.FaultCode.Group2Order = [];
            end
            % Flush those out to fake date vectors
            uniqueYearMonthCalc = flipud(unique(vecs(:,1)+vecs(:,2)/20));
            if ~isempty(fcvecs)
              fcuniqueYearMonthCalc = flipud(unique(fcvecs(:,1)+fcvecs(:,2)/20));
            else
              fcuniqueYearMonthCalc = [];
            end
            labelDateVecs = [floor(uniqueYearMonthCalc) round(mod(uniqueYearMonthCalc,1)*20) ones(length(uniqueYearMonthCalc),4)];
            if ~isempty(fcuniqueYearMonthCalc)
              fclabelDateVecs = [floor(fcuniqueYearMonthCalc) round(mod(fcuniqueYearMonthCalc,1)*20) ones(length(fcuniqueYearMonthCalc),4)];
            else
              fclabelDateVecs = [];
            end
            % Pull the result in to make the text label strings
            obj.dot.Labels2 = strcat(cellstr(datestr(labelDateVecs, 'mmmm')),cellstr(datestr(labelDateVecs, ' yyyy')));
            if ~isempty(fclabelDateVecs)
              obj.dot.FaultCode.Labels2 = strcat(cellstr(datestr(fclabelDateVecs, 'mmmm')),cellstr(datestr(fclabelDateVecs, ' yyyy')));
            else
              obj.dot.FaultCode.Labels2 = [];
            end
    end
end

% Copied directly from @MinMaxProcessor.makeBoxPlots, just renamed
function assignGroupDataM(obj, d, groupCode, group2Code, double)
% Correctly assigns the group data based on the grouping code and whether or not both Min
% and Max data is being plotted together
    
    % Set the grouping based on the groupCode passed in
    switch groupCode
        case 0 % Group data by software version
            % Need to convert these to individual strings because software over 100000
            % causes %g to output group names in scientific notation confusing boxplot
            obj.dot.GroupData = cellstr(num2str(d.CalibrationVersion,'%.0f'));
            if ~isempty(obj.dot.FaultCode)
              obj.dot.FaultCode.GroupData = cellstr(num2str(obj.dot.FaultCode.CalVersion,'%.0f'));
            else
              obj.dot.FaultCode.GroupData = [];
            end
            % Set the group data to be the calibration version
            %obj.dot.GroupData = d.CalibrationVersion;
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
        case 1 % Group data by truck name
            % Set the group data to be the truck name
            obj.dot.GroupData = d.TruckName;
            if ~isempty(obj.dot.FaultCode)
               obj.dot.FaultCode.GroupData = obj.dot.FaultCode.TruckName;
            else
               obj.dot.FaultCode.GroupData = [];
            end
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
        case 2 % Group data by family
            % Set the group data to be the family
            % Set the group order and labels to their default
            obj.dot.Labels = [];
            obj.dot.GroupOrder = [];
            obj.dot.FaultCode.GroupOrder = [];
            obj.dot.FaultCode.Labels = [];
            obj.dot.GroupData = d.Family;
            if ~isempty(obj.dot.FaultCode)
               obj.dot.FaultCode.GroupData = obj.dot.FaultCode.Family;
            else
               obj.dot.FaultCode.GroupData = [];
            end
        case 3 % Group data by month
%             % Set the group data to be a string generated from the timestamp that
%             % indicates the month that data was logged in
%             obj.dot.GroupData = cellstr([datestr(d.datenum, 'yy-mm_') datestr(d.datenum, 'mmmm yyyy')]);
%             % Set the group order and labels to their default
%             obj.dot.Labels = [];
%             obj.dot.GroupOrder = [];
            
            
            %%% Below is way faster than the above, but it is quite complex and obscure
            % Calculate the date vectors of all the serial date numbers
            vecs = datevec(d.datenum);
            if ~isempty(obj.dot.FaultCode)
               fcvecs = datevec(obj.dot.FaultCode.datenum);
            else
                fcvecs  =[];
            end
            % Calculate a unique number calculation based on the month and year, this will
            % be the group value for each individual data point
            obj.dot.GroupData = cellstr(num2str(vecs(:,1)+vecs(:,2)/20,'%.2f'));
            if ~isempty(fcvecs)
              obj.dot.FaultCode.GroupData = cellstr(num2str(fcvecs(:,1)+fcvecs(:,2)/20,'%.2f'));
            else 
              obj.dot.FaultCode.GroupData = [];
            end
            % Get the unique month and year combinations and flip their order
            obj.dot.GroupOrder = flipud(unique(obj.dot.GroupData));
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.GroupOrder = flipud(unique(obj.dot.FaultCode.GroupData));
            else
              obj.dot.FaultCode.GroupOrder = [];
            end
            % Flush those out to fake date vectors
            uniqueYearMonthCalc = flipud(unique(vecs(:,1)+vecs(:,2)/20));
            if ~isempty(fcvecs)
              fcuniqueYearMonthCalc = flipud(unique(fcvecs(:,1)+fcvecs(:,2)/20));
            else
              fcuniqueYearMonthCalc = [];
            end
            labelDateVecs = [floor(uniqueYearMonthCalc) round(mod(uniqueYearMonthCalc,1)*20) ones(length(uniqueYearMonthCalc),4)];
            if ~isempty(fcuniqueYearMonthCalc)
              fclabelDateVecs = [floor(fcuniqueYearMonthCalc) round(mod(fcuniqueYearMonthCalc,1)*20) ones(length(fcuniqueYearMonthCalc),4)];
            else
              fclabelDateVecs = [];
            end
            % Pull the result in to make the text label strings
            if ~isempty(fclabelDateVecs)
              obj.dot.FaultCode.Labels = strcat(cellstr(datestr(fclabelDateVecs, 'mmmm')),cellstr(datestr(fclabelDateVecs, ' yyyy')));
            else
              obj.dot.FaultCode.Labels = [];
            end
            obj.dot.Labels = strcat(cellstr(datestr(labelDateVecs, 'mmmm')),cellstr(datestr(labelDateVecs, ' yyyy')));
    end
    
    % Set the second grouping based on the group2Code passed in
    switch group2Code
        case -1 % No second grouping
            obj.dot.Group2Data = [];
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Data = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 0 % Group data by software version
            % Need to convert these to individual strings because software over 100000
            % causes %g to output group names in scientific notation confusing boxplot
            obj.dot.Group2Data = cellstr(num2str(d.CalibrationVersion,'%.0f'));
            % Set the group data to be the calibration version
            %obj.dot.GroupData = d.CalibrationVersion;
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = cellstr(num2str(obj.dot.FaultCode.CalVersion,'%.0f'));
            else
              obj.dot.FaultCode.Group2Data = [];
            end
        case 1 % Group data by truck name
            % Set the group data to be the truck name
            obj.dot.Group2Data = d.TruckName;
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = obj.dot.FaultCode.TruckName;
            else
              obj.dot.FaultCode.Group2Data = [];
            end
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
        case 2 % Group data by family
            % Set the group data to be the family
            % Set the group order and labels to their default
            obj.dot.Labels2 = [];
            obj.dot.Group2Order = [];
            obj.dot.FaultCode.Group2Order = [];
            obj.dot.FaultCode.Labels2 = [];
            obj.dot.Group2Data = d.Family;
            if ~isempty(obj.dot.FaultCode.GroupData)
              obj.dot.FaultCode.Group2Data = obj.dot.FaultCode.Family;
            else 
               obj.dot.FaultCode.Group2Data =[];
            end
        case 3 % Group data by month
%             % Set the group data to be a string generated from the timestamp that
%             % indicates the month that data was logged in
%             obj.dot.GroupData = cellstr([datestr(d.datenum, 'yy-mm_') datestr(d.datenum, 'mmmm yyyy')]);
%             % Set the group order and labels to their default
%             obj.dot.Labels = [];
%             obj.dot.GroupOrder = [];
            
            
            %%% Below is way faster than the above, but it is quite complex and obscure
            % Calculate the date vectors of all the serial date numbers
            vecs = datevec(d.datenum);
            if ~isempty(obj.dot.FaultCode.GroupData)
               fcvecs = datevec(obj.dot.FaultCode.datenum);
            else
                fcvecs  =[];
            end
            % Calculate a unique number calculation based on the month and year, this will
            % be the group value for each individual data point
            obj.dot.Group2Data = cellstr(num2str(vecs(:,1)+vecs(:,2)/20,'%.2f'));
            if ~isempty(fcvecs)
              obj.dot.FaultCode.Group2Data = cellstr(num2str(fcvecs(:,1)+fcvecs(:,2)/20,'%.2f'));
            else 
              obj.dot.FaultCode.Group2Data = [];
            end
            % Get the unique month and year combinations and flip their order
            obj.dot.Group2Order = flipud(unique(obj.dot.Group2Data));
            if ~isempty(obj.dot.FaultCode.Group2Data)
              obj.dot.FaultCode.Group2Order = flipud(unique(obj.dot.FaultCode.Group2Data));
            else
              obj.dot.FaultCode.Group2Order = [];
            end
            % Flush those out to fake date vectors
            uniqueYearMonthCalc = flipud(unique(vecs(:,1)+vecs(:,2)/20));
            if ~isempty(fcvecs)
              fcuniqueYearMonthCalc = flipud(unique(fcvecs(:,1)+fcvecs(:,2)/20));
            else
              fcuniqueYearMonthCalc = [];
            end
            labelDateVecs = [floor(uniqueYearMonthCalc) round(mod(uniqueYearMonthCalc,1)*20) ones(length(uniqueYearMonthCalc),4)];
            if ~isempty(fcuniqueYearMonthCalc)
              fclabelDateVecs = [floor(fcuniqueYearMonthCalc) round(mod(fcuniqueYearMonthCalc,1)*20) ones(length(fcuniqueYearMonthCalc),4)];
            else
              fclabelDateVecs = [];
            end
            % Pull the result in to make the text label strings
            if ~isempty(fclabelDateVecs)
              obj.dot.FaultCode.Labels2 = strcat(cellstr(datestr(fclabelDateVecs, 'mmmm')),cellstr(datestr(fclabelDateVecs, ' yyyy')));
            else
              obj.dot.FaultCode.Labels2 = [];
            end
            obj.dot.Labels2 = strcat(cellstr(datestr(labelDateVecs, 'mmmm')),cellstr(datestr(labelDateVecs, ' yyyy')));
    end
    
    % If Min and Max data are being plotted together
    if double
        % Double the size of the group data
        obj.dot.GroupData = [obj.dot.GroupData;obj.dot.GroupData];
        obj.dot.Group2Data = [obj.dot.Group2Data;obj.dot.Group2Data];
        obj.dot.FaultCode.Group2Data = [obj.dot.FaultCode.Group2Data;obj.dot.FaultCode.Group2Data];
        obj.dot.FaultCode.GroupData = [obj.dot.FaultCode.GroupData;obj.dot.FaultCode.GroupData];
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

function field = getFieldName(code)
% Return the name of the database column that contains the data for this group code
    switch code
        case 0 % Software
            field = 'CalibrationVersion';
        case 1 % Truck
            field = 'TruckName';
        case 2 % Family
            field = 'Family';
        case 3 % Serial date number
            field = 'datenum';
    end
end
