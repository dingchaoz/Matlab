function plotOwners = generatePlotOwners(obj)
%Generates of unique list of 3-step owners and plots they are the 3-step owner of
%   Generates a unique list of 3-step owners and the plots thay own
%   
%   Original Version - Chris Remington - October 1, 2012
%   Revised - Chris Remington - January 31, 2014
%     - Cliped functionality so that is shouldn't break anything
%     - This needs a re-work to function across HMLDE
%   Revised - Chris Remington - February 21, 2014
%     - Handle situation when ppi is an empty set without throwing an error
    
    % Initalize the output structure
    plotOwners = struct('name', [], 'plots', []);
    
    % Get the listing of SEID values and 3-step owners
    %d = fetch(obj.conn, 'SELECT [SEID], [Owner3StepX1] FROM [dbo].[qryMDLRedX1]');
    %d = fetch(obj.conn, 'SELECT [SEID], [Owner3Step] FROM [dbo].[tbl3StepOwnersTemp]');%%--%%
    % If no data has been added to the table yet because I'm lazy
    if 1%isempty(d)
        % cheet the code into working
        d.Owner3Step = [];
        d.SEID = [];
    end
    
    % Make the unique listing of 3-step owners
    plotOwners.name = [{'Show All Plots'}; unique(d.Owner3Step)];
    % Set an empty cell array to hold the plot lists
    plotOwners.plots = cell(length(plotOwners.name),1);
    
    % If there is no plotting information present
    if ~isempty(obj.ppi)
        % Set the first value manually to all plots present for the 'Show All Plots' selection
        plotOwners.plots{1} = obj.ppi.Name;
    else
        % Default it to an empty set
        plotOwners.plots{1} = [];
    end
    
    % Initalize an empty variable to hold the plot list as it is generated
    plotList = {};
    % Loop through the owner names to pull out all the seid value that are theirs
    for i = 2:length(plotOwners.name)
        % Pull out the system error id values that are owned by this person
        seidList = d.SEID(strcmp(plotOwners.name{i},d.Owner3Step));
        % For each SEID owned by this owner
        for j = 1:length(seidList)
            % Append the plots from the ppi that match this seid
            plotList = [plotList;obj.ppi.Name(obj.ppi.SEID==seidList(j))];
        end
        % Set the overall plot list for this owner
        plotOwners.plots{i} = sort(plotList);
        % Clear out the plot list variable
        plotList = {};
    end
end
