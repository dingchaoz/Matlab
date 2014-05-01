function makePlot(obj, visible)
%Save the Box Plot that makePlot generated
%   This will save the current figure using the settings correct for a box plot
%   to a file name that is specified.
%   
%   Usage: savePlot(obj, fileName)
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
    
    %% Create the box plot
    % If visible was set to 1
    if visible
        % Create a visible figure
        figure('Name', ['PpK Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none');
    else
        % Otherwise make an invisible figure
        figure('Name', ['PpK Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none','visible','off');
    end
    
    % Make the shell of the box plot
    % If there is actually data present
    if ~isempty(obj.PpK)
        %xindex = (1:length(obj.PpK))';
        h = plot(obj.PpK,'.b','MarkerSize',10);
        % Turn on the grid
        grid on
        %hh=plot(obj.FailureDataPoints);
    end
    %% Label the Plot
    % Generate the title
    titleText = {sprintf('FC %.0f - SEID %.0f - %s',obj.FC,obj.SEID,obj.SystemErrorName)};
    titleText = [titleText {sprintf('Family: %s   Truck Type: %s   Vehicle: %s',obj.FamilyFilter,obj.TruckFilter,obj.VehicleFilter)}];
    titleText = [titleText {sprintf('Date Filter: %s   Data Type: %s',obj.MonthFilter,obj.DataType)}];
    titleText = [titleText {sprintf('%s   Program: %s',getSWFiltStr,obj.Program)}]; % Software Filter
    titleText = [titleText {sprintf('RYG disposition: {\\color{%s}%s}',getDisposition,getDisposition)}];
    % For each line of title text
    for i = 1:length(titleText)
        % Do the replacement of _ with \_ for this line
        titleText{i} = regexprep(titleText{i},'\_','\\\_');
    end
    title(titleText,'FontSize',13,'Interpreter','tex') % Actually set the title
    labels = [obj.TruckName,num2cell(obj.TimePeriod), num2cell(obj.CalibrationVersion)];
    customDataCursor(h,labels);
    
    % Generate and set the x label
    % Parameter name and units
    xText = {'Data Index',...
             sprintf('Total Diagnostic Sample Values: %.0f',sum(obj.DataPoints)),...
             sprintf('Min Ppk: %.2f   Max Ppk: %.2f',min(obj.PpK),max(obj.PpK)),...
             sprintf('Median Ppk: %.2f   Failure Points: %.0f',nanmedian(obj.PpK),sum(obj.FailureDataPoints))};
    yText = {'PpK'};
    % Display the threshold name and value, also calculate min and max of the data
    % inside of the threshold(s) (if applicable)
    %nonFailMinMaxText = '';
    % If there is a LSL specificed
%     if ~isempty(obj.LSL) && ~isnan(obj.LSL) % Set the LSL text
%         xText = [xText {sprintf('LSL: %s = %g',obj.LSLName,obj.LSL)}];
%         %nonFailMinMaxText = sprintf('   Min (>LSL): %g',min(obj.Data(obj.Data>obj.LSL)));
%     end
%     % If there is an USL specified
%     if ~isempty(obj.USL) && ~isnan(obj.USL) % Set the USL text
%         xText = [xText {sprintf('USL: %s = %g',obj.USLName,obj.USL)}];
%         %nonFailMinMaxText = [nonFailMinMaxText sprintf('   Max(<USL): %g',max(obj.Data(obj.Data<obj.USL)))];
%     end
%     % Old
%     %xText = [xText {sprintf('Sample Size: %.0f   Failures: %0.f   Ppk: %.3f',length(obj.Data),calcNumFail,min([obj.USL-mu,mu-obj.LSL])/(3*sigma))}];
%     %xText = [xText {sprintf('Min: %g   Max: %g%s  Mean: %g   Std: %g',min(obj.Data),max(obj.Data),nonFailMinMaxText,mu,sigma)}];
%     
%     % Number of data points and the nunmber of failures
%     xText = [xText {sprintf('Sample Size: %.0f   Failures: %0.f   Ppk: %.3f',length(obj.Data),calcNumFail,min([obj.USL-mu,mu-obj.LSL])/(3*sigma))}];
%     % Global minima and global maxima
%     xText = [xText {sprintf('Min: %g   Max: %g  Mean: %g   Std: %g',min(obj.Data),max(obj.Data),mu,sigma)}];
    % Set the actual strings to the xlabel
    xlabel(xText,'FontSize',13);
    ylabel(yText,'FontSize',13);
    
    % Second figure
    if visible
        % Create a visible figure
        figure('Name', ['Number Failed Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none');
    else
        % Otherwise make an invisible figure
        figure('Name', ['Number Failed Plot of ' obj.SystemErrorName],'defaulttextinterpreter','none','visible','off');
    end
    hh = plot(obj.FailureDataPoints,'.b','MarkerSize',10);
    % Turn on the grid
    grid on
    customDataCursor(hh,labels);
    xText = {'Data Index',...
             sprintf('Total Diagnostic Sample Values: %.0f',sum(obj.DataPoints)),...
             sprintf('Min Ppk: %.2f   Max Ppk: %.2f',min(obj.PpK),max(obj.PpK)),...
             sprintf('Median Ppk: %.2f   Failure Points: %.0f',nanmedian(obj.PpK),sum(obj.FailureDataPoints))};
    yText = {'Number of Failure'};
    
    xlabel(xText,'FontSize',13);
    ylabel(yText,'FontSize',13);
    
    title(titleText,'FontSize',13,'Interpreter','tex') % Actually set the title
    
    %% Nested Functions
    % Nested function which will calculate the number of failure data-points
    % present
    function num = calcNumFail
        % Each will be zero if a spec equals NaN
        num = sum(obj.Data<=obj.LSL) + sum(obj.Data>=obj.USL);
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
    
    % Calculate the Red, Yellow, or Green
    function disposition = getDisposition
        if isempty(obj.PpK)
            disposition = 'Black';
            return
        elseif nanmedian(obj.PpK)>=1.5 && sum(obj.FailureDataPoints)==0
            disposition = 'Green';
        elseif nanmedian(obj.PpK)< 1.5 && sum(obj.FailureDataPoints)> 0
            disposition = 'Red';
        else
            disposition = 'Yellow';
        end
    end
end
