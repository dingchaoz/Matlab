function separationLines = dotplot(obj,data,group,groupOrder,groupLabels,group2,group2Order,group2Labels,varargin)
%  dotplot version 1.0 plots individual value plots of the data grouped by
%  the subgroups "Grouping". The original program was authored by Chris
%  Remington. This program uses the logic to modify to meet the GUI tool
%  needs thats being put out by the Data Analysis team.
% USE: dotplot(obj, Data,Grouping)
% WHERE: Data is a n by 1 matrix
%        Grouping is a cell n by 2 matrix
%        The outer grouping is the second column of the cell "Grouping"
% EXAMPLE:

    %% Definintons / Prelims
    % Define the input to the colormap property to color the groups
    cmap = [0 1 1;    % cyan
            0 0 0;    % black
            1 0 0;    % red
            0 1 0;    % green
            0 0 1;    % blue
            1 0.5 0;  % orange
            1 0 1;   % magenta
            0 0.6 0];    % green
    
    % Empty array to hold the label names
    labels = {};
    % Empty array to hold where separation lines need to be
    separationLines = [];
    
    % Start at group number 1
    groupNum = 1;
    % Start color selection index at 0
    colorSel = 1;
    % Initalize group index numbers
    groupIndex = zeros(size(data));
    % initalize the color value of each data point
    colorVal = zeros(size(data));
    
    %% Plot Each Data group
    
    % For each unique primary group present
    for i = 1:length(groupOrder)
        
        % If there is a second group present
        if ~isempty(group2Order)
            
            % For each second group present
            for j = 1:length(group2Order)
                
                % Find the index values in data of this combination
                idx = strcmp(groupOrder{i},group)&strcmp(group2Order{j},group2);
                % If there was no data for this combination
                if sum(idx) == 0
                    % Skip this vehicle
                    continue
                end
                % Set those index values to have the unique group number
                groupIndex(idx) = groupNum;
                % Set those index values to the current color selection
                colorVal(idx) = colorSel;
                
                % Define the label name
                labels{groupNum} = sprintf('%s --- %s',groupLabels{i},group2Labels{j});
                
                % Increment group number
                groupNum = groupNum + 1;
                
            end
            
            % Add this group to the separation lines
            separationLines = [separationLines; groupNum];
            % Make the label an empty set
            labels{groupNum} = [];
            % Increment group number
            groupNum = groupNum + 1;
            % Increnent the current color
            incColor;
            
        else % There is only one grouping
            
            % Get the index values in data of this combination
            idx = strcmp(groupOrder{i},group);
            % If there was no data for this combination
            if sum(idx) == 0
                % Skip this vehicle
                continue
            end
            % Set those index values to have the unique group number
            groupIndex(idx) = groupNum;
            % Set those index values to a unique color
            colorVal(idx) = colorSel;
            
            % Define the label name
            labels{groupNum} = sprintf('%s',groupLabels{i});
            
            % Increment group number
            groupNum = groupNum + 1;
            % Increnent the current color
            incColor;
            
            % If we're at the end add an empty label to the end just like the multi
            % grouping so that the bottom code works right
            if i==length(groupOrder)
                % Make the label an empty set
                labels{groupNum} = [];
                % Increment group number
                groupNum = groupNum + 1;
            end
        end
    end
    
    %% Plot the Data
    % Set the color map colors
    colormap(cmap)
    % Plot all the data once with the correct color coding
    scatter(data, groupIndex,[],colorVal)
    
    %% Add Y-Axis Labels and Adjust Y-axis Limits
    % Set the y-axis limit
    ylim([0 groupNum-1])
    % Add Tick Labels to the y-axis
    set(gca,'YTick',1:(length(labels)-1))
    set(gca,'YTickLabel',labels(1:end-1))
    
    %% Nested Functions
    % Function to increment the current color selection
    function incColor
        % Add one to the color selection
        colorSel = colorSel + 1;
        % If we reached the last color
        if colorSel > size(cmap,1)
            % Start back at the first color
            colorSel = 1;
        end
    end
    
end
