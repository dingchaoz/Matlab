function makePlot(obj, visible)
%Save the Box Plot that makePlot generated
%   This will save the current figure using the settings correct for a dot plot
%   to a file name that is specified.
%   
%   Usage: makePlot(obj, fileName)
%   
%   Inputs - 
%   fileName: Name of the file that the plot should be saved into
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - April 11, 2012
%   Revised - Chris Remington - May 11, 2012
%       - Added labeling for the total number of data points and number of failures in the
%         plot
%       - Revised the way outliers are plotted to make sure they are easier to see if they
%         happen to be plotted over a spec line
%   Revised - Chris Remington - July 6, 2012
%       - Added the SoftwareFilter property that will label on the plot any relevant
%         software filtering criteria
%       - Aded grey horizontal lines between the groups so make the plots easier to read
%   Revised - Chris Remington - September 17, 2012
%       - Added additional functionality whereby you can manually specify a 'grouporder'
%         and 'labels' properties for the boxplot function. If these are left as an empty
%         set, this will default to the old method of data sorting for the groups.
%   Revised - Chris Remington - February 4, 2013
%       - Modified labeling: added Ppk, Mean, Sigma, FC; removed a few things
%   Revised - Chris Remington - April 10, 2014
%       - Adapted from boxplot to a dot plot, added ability to do 2 grouping
%   Revised - Dingchao Zhang - March 20, 2015
%       - Added variable to count fault code match instances and to display it  
%   Revised - Dingchao Zhang - June 1, 2015
%       - Added line to display exclude dates 
    %% Sort Data
    % If the group order isn't manually specified
    if isempty(obj.GroupOrder)
        % Get a unique listing of the groups present
        %groups = unique(obj.GroupData);
        groups = unique(obj.GroupData);
        % Sort the groups in decending order
        if isnumeric(groups)
            % You can't get here anymore because software is converted to a string 
            % before it is passed to this function so that 8 digit number get displayed
            % correctly in the box plot
            
            % For numeric groupings (like software version) use the output of unique
            % in reverse (unique this returns the list sorted in ascending order)
            % The GroupData needs to be a single column (size(obj.GroupData,2)==1) in
            % order for this to work
            obj.GroupOrder = num2str(groups(end:-1:1));
            % If it ends up as a character array (i.e., only one group)
            %if ischar(groupOrder)
            %    groupOrder = {groupOrder};
            %end
            
            % Set the labels to be the same as the group strings
            obj.Labels = obj.GroupOrder;
            
        else % should be a cellstring
            % Convert to lower case so strings are sorted properly
            [~, IX] = sortrows(lower(groups), -1);
            % Recapture the correctly sorted lowercase group order using the original
            % labels in their original case
            obj.GroupOrder = groups(IX);
            % Set the labels to be the same as the group strings
            obj.Labels = obj.GroupOrder;
        end
        %numGroups = length(obj.GroupOrder);
    else
        % Use the specified groups, calculate the number of groups present
        %numGroups = length(obj.GroupOrder);
    end
    
    % If the group order isn't manually specified
    if isempty(obj.Group2Order)
        % Get a unique listing of the groups present
        groups2 = unique(obj.Group2Data);
        % Sort the groups in decending order
        if isnumeric(groups2)
            % You can't get here anymore because software is converted to a string 
            % before it is passed to this function so that 8 digit number get displayed
            % correctly in the box plot
            
            % For numeric groupings (like software version) use the output of unique
            % in reverse (unique this returns the list sorted in ascending order)
            % The GroupData needs to be a single column (size(obj.GroupData,2)==1) in
            % order for this to work
            obj.Group2Order = num2str(groups2(end:-1:1));
            % If it ends up as a character array (i.e., only one group)
            %if ischar(groupOrder)
            %    groupOrder = {groupOrder};
            %end
            
            % Set the labels to be the same as the group strings
            obj.Labels2 = obj.Group2Order;
            
        else % should be a cellstring
            % Convert to lower case so strings are sorted properly
            [~, IX] = sortrows(lower(groups2), -1);
            % Recapture the correctly sorted lowercase group order using the original
            % labels in their original case
            obj.Group2Order = groups2(IX);
            % Set the labels to be the same as the group strings
            obj.Labels2 = obj.Group2Order;
        end
        %numGroups = length(obj.GroupOrder);
    else
        % Use the specified groups, calculate the number of groups present
        %numGroups = length(obj.GroupOrder);
    end
    
    
    
    %% If Fault Code is empty
    if isempty(obj.FaultCode)
        
        obj.FaultCode.GroupData = [];
        obj.FaultCode.Group2Data = [];
    else
    
        %% Sort Fault Code Group Data
        % If the group order isn't manually specified
        if isempty(obj.FaultCode.GroupOrder)
            % Get a unique listing of the groups present
            %groups = unique(obj.GroupData);
            fcgroups = unique(obj.FaultCode.GroupData);
            % Sort the groups in decending order
            if isnumeric(fcgroups)
                % You can't get here anymore because software is converted to a string 
                % before it is passed to this function so that 8 digit number get displayed
                % correctly in the box plot

                % For numeric groupings (like software version) use the output of unique
                % in reverse (unique this returns the list sorted in ascending order)
                % The GroupData needs to be a single column (size(obj.GroupData,2)==1) in
                % order for this to work
                obj.FaultCode.GroupOrder = num2str(fcgroups(end:-1:1));
                % If it ends up as a character array (i.e., only one group)
                %if ischar(groupOrder)
                %    groupOrder = {groupOrder};
                %end

                % Set the labels to be the same as the group strings
                obj.FaultCode.Labels = obj.FaultCode.GroupOrder;

            else % should be a cellstring
                % Convert to lower case so strings are sorted properly
                [~, IX] = sortrows(lower(fcgroups), -1);
                % Recapture the correctly sorted lowercase group order using the original
                % labels in their original case
                obj.FaultCode.GroupOrder = fcgroups(IX);
                % Set the labels to be the same as the group strings
                obj.FaultCode.Labels = obj.FaultCode.GroupOrder;
            end
            %numGroups = length(obj.GroupOrder);
        else
            % Use the specified groups, calculate the number of groups present
            %numGroups = length(obj.GroupOrder);
        end

        % If the group order isn't manually specified
        if isempty(obj.FaultCode.Group2Order)
            % Get a unique listing of the groups present
            fcgroups2 = unique(obj.FaultCode.Group2Data);
            % Sort the groups in decending order
            if isnumeric(fcgroups2)
                % You can't get here anymore because software is converted to a string 
                % before it is passed to this function so that 8 digit number get displayed
                % correctly in the box plot

                % For numeric groupings (like software version) use the output of unique
                % in reverse (unique this returns the list sorted in ascending order)
                % The GroupData needs to be a single column (size(obj.GroupData,2)==1) in
                % order for this to work
                obj.FaultCode.Group2Order = num2str(fcgroups2(end:-1:1));
                % If it ends up as a character array (i.e., only one group)
                %if ischar(groupOrder)
                %    groupOrder = {groupOrder};
                %end

                % Set the labels to be the same as the group strings
                obj.FaultCode.Labels2 = obj.FaultCode.Group2Order;

            else % should be a cellstring
                % Convert to lower case so strings are sorted properly
                [~, IX] = sortrows(lower(fcgroups2), -1);
                % Recapture the correctly sorted lowercase group order using the original
                % labels in their original case
                obj.FaultCode.Group2Order = fcgroups2(IX);
                % Set the labels to be the same as the group strings
                obj.FaultCode.Labels2 = obj.FaultCode.Group2Order;
            end
            %numGroups = length(obj.GroupOrder);
        else
            % Use the specified groups, calculate the number of groups present
            %numGroups = length(obj.GroupOrder);
        end
    end
    %% Create the Dot plot
    % If visible was set to 1
    if visible
        % Create a visible figure
        figure('Name', ['Dot Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none');
    else
        % Otherwise make an invisible figure
        figure('Name', ['Dot Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none','visible','off');
    end
    
    % If there is actually data present
    if ~isempty(obj.Data)
        % Make the plot, capture where separation lines need to be drawn (do those at end)
         separationLines = obj.dotplot(obj.Data, obj.GroupData, obj.GroupOrder, obj.Labels, obj.Group2Data, obj.Group2Order, obj.Labels2);
        %separationLines = obj.dotplot2(obj.Data, obj.GroupData, obj.GroupOrder, obj.Labels, obj.Group2Data, obj.Group2Order, obj.Labels2);
    else
        % Don't think it's possible to make it here
        error('Where''s my data? No Data to Plot.')
    end
    
    %% Plot USL and LSL
    
    % Freeze the plot window so that the LSL and/or USL lines can be added
    hold on
    
    % Find the y-limits to determine how high to make the spec limit lines
    yLimits = ylim;
    
    % If the LSL is specified
    if ~isempty(obj.LSL) && ~isnan(obj.LSL)
        % Add a red, dotted, verticle line for the LSL
        plot([obj.LSL obj.LSL], [0 max(yLimits)],'Color','Red','LineWidth',1,'LineStyle','--');
        % Label it with 'LSL' in red
        text(obj.LSL,yLimits(2),'LSL','HorizontalAlignment','Center','VerticalAlignment','Bottom','Color','Red');
    end
    
    % If the USL is specified
    if ~isempty(obj.USL) && ~isnan(obj.USL)
        % Add a red, dotted, verticle line for the USL
        plot([obj.USL obj.USL], [0 max(yLimits)],'Color','Red','LineWidth',1,'LineStyle','--');
        % Label it with 'USL' in red
        text(obj.USL,yLimits(2),'USL','HorizontalAlignment','Center','VerticalAlignment','Bottom','Color','Red');
    end
    
    %% Adjust x-limts to contain the LSL and USL
    
    % Get the x-limits so they can be adjusted to fully include the LSL and USL
    xLimits = xlim;
    
    % If the LSL is less than or equal to the lower x-limit
    if obj.LSL <= xLimits(1)
        % Open up the lower x-limit past the LSL
        xlim([obj.LSL-0.05*diff(xLimits) xLimits(2)]);
        % Refresh the xlimits (in case the upper x-limit needs to be adjusted below)
        xLimits = xlim;
    end
    
    % If the USL is greater than or equal to the upper x-limit
    if obj.USL>=xLimits(2)
        % Open up the upper x-limit past the USL
        xlim([xLimits(1) obj.USL+0.04*diff(xLimits)]);
    end
    
    % Open the limits another 3% on each side no matter what
    newXlim = xlim;xdiff = diff(newXlim);
    xlim([newXlim(1)-0.03*xdiff newXlim(2)+0.03*xdiff]);
    
    %% Separation Lines (do this last so the lines go all the way across the plot)
    % Get plot axis limits
    if ~isempty(separationLines) % ???
        xAxisLimits = xlim;
        % Draw all the separation lines (don't plot if there's only one line or the last line)
        for i = 2:length(separationLines)
            % Draw a separation line between softwares
            plot(xAxisLimits,[separationLines(i-1) separationLines(i-1)],'k','LineWidth',2)
        end
    end
    
    %% Data Labeling
    
    % TO DO, need to add the following to the plot
    % - Number of data points per grouping (i.e, truck, engine family, etc.)
    % - Numerical minimum in each grouping, labeled on the plot
    % - Numerical maximum in each grouping, labeled on the plot
    
    % Lazy, calculate these here once
    mu = nanmean(obj.Data);
    sigma = nanstd(obj.Data);
    
    %% Label the Plot
    % Generate the title
    titleText = {sprintf('FC %.0f - SEID %.0f - %s',obj.FC,obj.SEID,obj.SystemErrorName)};
    titleText = [titleText {sprintf('Family: %s   Truck Type: %s   Vehicle: %s',obj.FamilyFilter,obj.TruckFilter,obj.VehicleFilter)}];
    titleText = [titleText {sprintf('Dates include: %s   Data Type: %s',obj.MonthFilter,obj.DataType)}];
    % if exclude from and to dates are properties of obj
    if isprop(obj,'Exdatesfrom') && isprop(obj,'Exdatesto')
        % if at least one of the properties is not empty
        if ~isempty(obj.Exdatesfrom)||~isempty(obj.Exdatesto)
       %if ~isempty(obj.Exdatesfrom)& ~isempty(obj.Exdatesto)
         titleText = [titleText {sprintf('Exclude date from: %s   to: %s',obj.Exdatesfrom,obj.Exdatesto)}];
        end
%        %elseif ~isempty(obj.Exdatesto)
%          titleText = [titleText {sprintf('Exclude date up to : %s   ',obj.Exdatesfrom)}];
%        elseif ~isempty(obj.Exdatesfrom)
%          titleText = [titleText {sprintf('Exclude date to: %s   ',obj.Exdatesfrom)}];
%        end
    end
    
    % if filter is applied, pass the user inputs to the label
    if strcmp(obj.Fltplot,'Yes')
       if ~isempty(obj.FltUSL) && ~isempty(obj.FltLSL) 
         titleText = [titleText {sprintf('Data is filtered by %s <= %s %s >= %s',obj.FltValue,obj.FltLSL,obj.FltCondition,obj.FltUSL)}];
       elseif isempty(obj.FltUSL)
         titleText = [titleText {sprintf('Data is filtered by %s <= %s',obj.FltValue,obj.FltLSL)}];
       elseif isempty(obj.FltLSL)
         titleText = [titleText {sprintf('Data is filtered by %s >= %s',obj.FltValue,obj.FltUSL)}];  
       end
    end
    titleText = [titleText {sprintf('%s   Program: %s',getSWFiltStr,obj.Program),''}]; % Software Filter
    title(titleText,'FontSize',10) % Actually set the title
    
    % Generate and set the x label
    % Parameter name and units
    xText = {sprintf('%s (%s)', obj.ParameterName, obj.ParameterUnits)};
    % Display the threshold name and value, also calculate min and max of the data
    % inside of the threshold(s) (if applicable)
    %nonFailMinMaxText = '';
    % If there is a LSL specificed
    if ~isempty(obj.LSL) && ~isnan(obj.LSL) % Set the LSL text
        xText = [xText {sprintf('LSL: %s = %g',obj.LSLName,obj.LSL)}];
        %nonFailMinMaxText = sprintf('   Min (>LSL): %g',min(obj.Data(obj.Data>obj.LSL)));
    end
    % If there is an USL specified
    if ~isempty(obj.USL) && ~isnan(obj.USL) % Set the USL text
        xText = [xText {sprintf('USL: %s = %g',obj.USLName,obj.USL)}];
        %nonFailMinMaxText = [nonFailMinMaxText sprintf('   Max(<USL): %g',max(obj.Data(obj.Data<obj.USL)))];
    end
    % Old
    %xText = [xText {sprintf('Sample Size: %.0f   Failures: %0.f   Ppk: %.3f',length(obj.Data),calcNumFail,min([obj.USL-mu,mu-obj.LSL])/(3*sigma))}];
    %xText = [xText {sprintf('Min: %g   Max: %g%s  Mean: %g   Std: %g',min(obj.Data),max(obj.Data),nonFailMinMaxText,mu,sigma)}];
    
    % Number of data points and the nunmber of failures
    xText = [xText {sprintf('Sample Size: %.0f   Failures: %0.f   Ppk: %.3f',length(obj.Data),calcNumFail,calcPpk)}];
    % Global minima and global maxima
    xText = [xText {sprintf('Min: %g   Max: %g  Mean: %g   Std: %g',min(obj.Data),max(obj.Data),mu,sigma)}];
    % Global minima and global maxima
    %FC_count = length(unique(fc_match.Date));
    if isempty(obj.FaultCode.GroupData)
        FC_count = 0 ;
    else
        FC_count = length(unique(obj.FaultCode.Date));
    end
    xText = [xText {sprintf('FaultCode Instances: %.0f',FC_count)}];

    % Set the actual strings to the xlabel
    xlabel(xText,'FontSize',10);
%     xText2 = 'test';
%     xlabel(xText2,'FontSize',13,'Color','r');
    
    
    %% Nested Functions
    % Nested function which will calculate the number of failure data-points
    % present
    function num = calcNumFail
        % Each will be zero if a spec equals NaN
        num = sum(obj.Data<=obj.LSL) + sum(obj.Data>=obj.USL);
        % If there were no threshold values
        if isnan(obj.LSL) && isnan(obj.USL)
            % Set the number of failures to an empty set
            num = [];
        end
    end
    
    % Nested funciton to calculate the Ppk
    function ppk = calcPpk
        % Calculate the Ppk using the standard formula
        ppk = min([obj.USL-mu,mu-obj.LSL])/(3*sigma);
        % Set it to empty if it is a NaN
        if isnan(ppk)
            ppk = [];
        end
    end
    
    % Nested function that generates the software filtering string for the title
    function swFilt = getSWFiltStr
        % Generate the string that will indicate the software filtering used
        % If the SoftwareFilter property is left blank
        if isempty(obj.SoftwareFilter)
            swFilt = 'Software Filter: None';
            return
        end
        % If a to and from software were specified
        if isnan(obj.SoftwareFilter(1))
            if isnan(obj.SoftwareFilter(2))
                % No software filtering is present
                swFilt = 'Software Filter: None';
            else
                % Software filtering up to a certain software
                swFilt = sprintf('Software Filter: Up to %s',obj.num2dot(obj.SoftwareFilter(2)));
            end
        else
            if isnan(obj.SoftwareFilter(2))
                % Software filtering everything above a software version
                swFilt = sprintf('Software Filter: %s and later',obj.num2dot(obj.SoftwareFilter(1)));
            elseif obj.SoftwareFilter(1)==obj.SoftwareFilter(2)
                % Single software version specified
                swFilt = sprintf('Software Filter: %s',obj.num2dot(obj.SoftwareFilter(1)));
            else
                % Software filtering between two versions of software
                swFilt = sprintf('Software Filter: Between %s and %s',obj.num2dot(obj.SoftwareFilter(1)),obj.num2dot(obj.SoftwareFilter(2)));
            end
        end
    end
end
