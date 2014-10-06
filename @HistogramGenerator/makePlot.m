function makePlot(obj, visible)
%Main method that will generate a plot based on the information passed in
%   This functions will take the dataset and propertires specified in the
%   HistogramGenerator object and create a histogram using the values
%
%   Usage: makePlot(obj, visible)
%
%   Inputs ---
%   visible:    True or false as to whether or not the make the plot visible upon creation
%
%   Outputs ---
%   None
%
%   Original Version - Chris Remington - October 23, 2012
%   Revised - Chris Remington - Novermber 2, 2012
%       - Fixed a bug where the LSL and USL weren't flipped when the sign of the data-set
%         was flipped
%   Revised - Chris Remington - February 4, 2013
%       - Modified labeling: added Ppk, Mean, Sigma, FC; removed a few things

%% Calculate Statistics
% If a distribution is specified
if ~isempty(obj.Dist)
    try
        % Call calcCapability to get the statistics for the data-set and spec limits
        obj.c = obj.calcCapability(obj.Data, obj.LSL, obj.USL, obj.Dist);
        % Re-assign the filtered data-set as returned from calcCapability to the Data
        % propery of this object
        obj.Data = obj.c.X;
        % Re-assign the LSL and USL if the signs were flipped
        obj.LSL = obj.c.LSL;
        obj.USL = obj.c.USL;
        
        % Lazy, calculate these here once
        mu = nanmean(obj.Data);
        sigma = nanstd(obj.Data);
        % Note: For incompatable distributions, the errors will travel up through here and
        % back to the GUI so they can be handles inside the GUI
        
    catch ex
        % If there was neither a LSL or USL,
        if strcmp('StatProcessor:calcCapability:invalidLimits',ex.identifier)
            % Don't calculate the capability, just make a histogram without a fit
            obj.c = [];
            % Set the distribution to an empty set to turn it off
            obj.Dist = [];
        else % oterwise this is an unhandled exception
            % Rethrow the original error
            rethrow(ex)
        end
    end
else
    % Make sure that c is set to an empty set
    obj.c = [];
end

%% Plot histogram
% Generate the proper number of bars for the histogram
amtData = length(obj.Data);
if amtData<100
    numBars = 15;
elseif amtData<250
    numBars = 30;
elseif amtData<500
    numBars = 60;
else
    numBars = 100;
end

% If a visible plot is desired
if visible
    % Make a new figure
    figure('Name', ['Histogram of ' obj.SystemErrorName],'defaulttextinterpreter','none');
else
    % Create a blank figure that is not visible to speed up plot creation
    figure('Visible','off','Name', ['Histogram of ' obj.SystemErrorName],'defaulttextinterpreter','none');
end

% Make the historgam
hist(obj.Data,numBars)
% Turn hold on so all additional plots are over-laid
hold on

% If a distribution is desired to be plotted
if ~isempty(obj.Dist)
    % Capture the bins with another call to hist (when this output argument is used, hist
    % doesn't actually make the figure. You can call bar(xout, bins) to make it, but it
    % doesn't look as good as when hist makes it)
    [bins,xout] = hist(obj.Data,numBars);
    
    % Plot pdf
    % Scale the pdf for plotting on the histogram if it isn't empty (i.e., skipped due to
    % no data in the range of that distribution)
    if ~isempty(obj.c.pdf)
        % Multiple the pdf by the number of data points and the dx of the bin spacing
        % This scales the pdf properly for plotting on the histogram
        yy = obj.c.pdf*sum(bins)*min(diff(xout));
    else
        % Set the empty
        yy = []; % Can you ever get here?
    end
    % Add the plot of pdf as a red line over the histogram
    plot(obj.c.dfScale,yy,'Color','Red','LineWidth',1)
    
else
    % Don't plot the red pdf line on the plot
end

%% Plot USL and LSL
% Find the y-limits to determine how high to make the spec limit lines
yLimits = ylim;

% If the LSL is specified
if ~isnan(obj.LSL)
    % Add a red, dotted, vertical line for the LSL
    plot([obj.LSL obj.LSL], [0 max(yLimits)],'Color','Red','LineWidth',1,'LineStyle','--');
    % Label it with 'LSL' in red
    text(obj.LSL,yLimits(2),'LSL','HorizontalAlignment','Center','VerticalAlignment','Bottom','Color','Red');
end

% If the USL is specified
if ~isnan(obj.USL)
    % Add a red, dotted, vertical line for the USL
    plot([obj.USL obj.USL], [0 max(yLimits)],'Color','Red','LineWidth',1,'LineStyle','--');
    % Label it with 'USL' in red
    text(obj.USL,yLimits(2),'USL','HorizontalAlignment','Center','VerticalAlignment','Bottom','Color','Red');
end

%% Adjust x-limts

% Get the x-limits so they can be adjusted to fully include the LSL and USL
xLimits = xlim;

% If the LSL is equal to the lower x-limit
if obj.LSL==xLimits(1)
    % Open up the lower x-limit
    xlim([xLimits(1)-0.05*diff(xLimits) xLimits(2)]);
    % Refresh the xlimits (in case the upper x-limit needs to be adjusted below)
    xLimits = xlim;
end

% If the USL is equal to the upper x-limit
if obj.USL==xLimits(2)
    % Open up the upper x-limit
    xlim([xLimits(1) xLimits(2)+0.04*diff(xLimits)]);
end

%% Label Plot

% If there was a distribution / statistics
if 0%~isempty(obj.Dist)
    % Set the Title string (for the top of the plot) and include a distribution name
    title({sprintf('FC %.0f - SEID %.0f - %s', obj.FC, obj.SEID, obj.SystemErrorName), ...
        sprintf('%s Distribution',obj.getDistName(obj.c.dist)), ...
        sprintf('Family: %s   Truck Type: %s   Vehicle: %s',obj.FamilyFilter,obj.TruckFilter,obj.VehicleFilter), ...
        sprintf('Date Filter: %s   Data Type: %s',obj.MonthFilter,obj.DataType), ...
        sprintf('%s   Program: ',getSWFiltStr,obj.Program),...
        ''},'FontSize',13);
else % Set the Title string (for the top of the plot) and dont' include a distribution name
    title({sprintf('FC %.0f - SEID %.0f - %s', obj.FC, obj.SEID, obj.SystemErrorName), ...
        sprintf('Family: %s   Truck Type: %s   Vehicle: %s',obj.FamilyFilter,obj.TruckFilter,obj.VehicleFilter), ...
        sprintf('Date: %s   Data Type: %s',obj.MonthFilter,obj.DataType), ...
        sprintf('%s   Program: %s',getSWFiltStr,obj.Program),...
        ''},'FontSize',13);
end

% Build and set the X-Asis text (for the bottom of the plot)
xText = {sprintf('%s (%s)',obj.ParameterName, obj.ParameterUnits)};
% Add the LSL if it is defined
if ~isnan(obj.LSL),xText = [xText {sprintf('LSL: %s = %g', obj.LSLName, obj.LSL)}];end
% Add the USL if it is defined
if ~isnan(obj.USL),xText = [xText {sprintf('USL: %s = %g', obj.USLName, obj.USL)}];end

% If there were specification limits specified and obj.Dist could be calculated
if ~isempty(obj.Dist)
    % Add a line for Ppk, sample size, and failure information
    xText = [xText {sprintf('Sample Size: %.0f   Failures: %.0f   Ppk: %.3f',obj.c.numDataPts,obj.c.numFail,calcPpk)}];
    % Add a line for the min/max/mean and std dev if normal distribution
    xText = [xText {sprintf('Min: %g   Max: %g   Mean: %g   Std: %g',obj.c.min,obj.c.max,mu,sigma)}];
else % There were no threshold limits associated with this parameter
    % Add a line for Ppk, sample size, and failure information
    xText = [xText {sprintf('Sample Size: %.0f   Failures: %.0f   Ppk: %.3f',length(obj.Data),[],[])}];
    % Add a line for the min/max/mean and std dev if normal distribution
    xText = [xText {sprintf('Min: %g   Max: %g   Mean: %g   Std: %g',min(obj.Data),max(obj.Data),nanmean(obj.Data),nanstd(obj.Data))}];
end

%     % If there was a distribution / statistics
%     if ~isempty(obj.Dist)
%         % Old
%         xText = [xText {sprintf('P-Value: %g   PPM: %g   ISO Ppk: %.3f   Minitab Ppk: %.3f',obj.c.p,obj.c.ppm,obj.c.PpkIso,obj.c.Ppk)}];
%         xText = [xText {sprintf('Sample Size: %.0f   Filtered Zeros: %.0f   Observed Failures: %.0f',obj.c.numDataPts,obj.c.numZeros,obj.c.numFail)}];
%         if strcmp('norm', obj.c.dist),xText = [xText {sprintf('Min: %g   Max: %g   Mean: %g   Std: %g',obj.c.min,obj.c.max,obj.c.mean,obj.c.sigma)}];
%         else xText = [xText {sprintf('Min: %g   Max: %g   Mean: %g',obj.c.min,obj.c.max,obj.c.mean)}];
%         end
%     else
%         % Add a line for sample size and failure information
%         xText = [xText {sprintf('Sample Size: %.0f   Filtered Zeros: %.0f   Observed Failures: %.0f',length(obj.Data),0,calcNumFail(obj.Data,obj.LSL,obj.USL))}];
%         % Add a line for min, max, and mean
%         xText = [xText {sprintf('Min: %g   Max: %g   Mean: %g',min(obj.Data),max(obj.Data),mean(obj.Data))}];
%     end

% Set the cell array as the x-label
xlabel(xText,'FontSize',13);
% Set the y-label
ylabel('Count','FontSize',13);

% Set the x-axis tick mode back to auto so the tick labels will get re-generated
% Sometimes there was an issue wherein the axis scale would be updated with the spec
% limit line, but the tick labels wouldn't get updated and would be crunched together
set(gca, 'XTickMode', 'auto');

%% Nested Functions
    function swFiltStr = getSWFiltStr
        %Generate the string that will indicate the software filtering used
        % Pull software filtering into a local copy
        sw = obj.SoftwareFilter;
        % Decide on how to display the filtering
        if isnan(sw(1))
            if isnan(sw(2))
                % No software filtering is present
                swFiltStr = 'Software Filter: None';
            else
                % Software filtering up to a certain software
                swFiltStr = sprintf('Software Filter: Up to %s',obj.num2dot(sw(2)));
            end
        else
            if isnan(sw(2))
                % Software filtering everything above a software version
                swFiltStr = sprintf('Software Filter: %s and later',obj.num2dot(sw(1)));
            elseif sw(1)==sw(2)
                % Single software version specified
                swFiltStr = sprintf('Software Filter: %s',obj.num2dot(sw(1)));
            else
                % Software filtering between two versions of software
                swFiltStr = sprintf('Software Filter: Between %s and %s',obj.num2dot(sw(1)),obj.num2dot(sw(2)));
            end
        end
    end
    function ppk = calcPpk
        % Calculate the Ppk using the standard formula
        ppk = min([obj.USL-mu,mu-obj.LSL])/(3*sigma);
        % Set it to empty if it is a NaN
        if isnan(ppk)
            ppk = [];
        end % function ppk = calcPpk
    end
end

function a = calcNumFail(X, LSL, USL)
% Calculate the number of data points outside the LSL and USL for the given data set
% Calculate number below the LSL
below = sum(X<=LSL); % This will be zero if the LSL is a NaN
above = sum(X>=USL); % This will be zero is the USL is a NaN
a = below + above;
end

% Nested funciton to calculate the Ppk

