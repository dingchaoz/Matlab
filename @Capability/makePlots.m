function makePlots(obj, rootDir, masterDateFilt, masterSwFilt)
%Master method that makes the standard array of plots for an engine program
%   This should control the mapping of where the plots are made and the total assortment
%   of plots that are generated
%   
%   Usage: errors = makePlots(obj, rootDir)
%   
%   Inputs -
%   rootDir: Directory where the system error folders will be stored
%   
%   Outputs-
%   errors:  Cell array of any error that occoured in processing
%   
%   
%   Original Version - Chris Remington - March 31, 2014
%   Revised - N/A - N/A
    
    %% Master Date Filtering
    % If this argument wasn't passed in
    if ~exist('masterDateFilt','var') || isempty(masterDateFilt)
        % Default to no date filtering
        obj.filt.date = [NaN NaN];
    else
        % Use the user input values
        obj.filt.date = masterDateFilt;
    end
    
    %% Master Software Fitering
    % Can also specify a starting software filtering if desired so the overall cumulative
    % plot will use this filtering, then only softwares present inside of this would get
    % plotted individually
    
    % If this argument wasn't passed in
    if ~exist('masterSwFilt','var') || isempty(masterSwFilt)
        % Default to no software filtering
        masterSwFilt = [NaN NaN];
    else
        % Use the user input values (already named correctly)
    end
    
    % Find the index of this system error for testing
    %idx = find(strcmp('UREA_SM_HTR_HIGH_ERR',obj.ppi.Name));
    
    %% Plotter per System Error
    % Loop through ppi
    for i = 1:length(obj.ppi.SEID) % Pacific test of all combinations [1 2 4 5 20 51 112 134]%
        try % For now
        
        % Pull out short name for a few things
        sename = obj.ppi.Name{i};
        % Use this variable for the name to save the plot as
        param = obj.ppi.CriticalParam{i};
        % Clip parameter name to keep file names short
        if length(param) > 35
            % Trim for the file name
            param = param(1:35);
        end
        % Get rid of characters that don't agree well with file names
        for j = 1:length(param)
            if any(param(j)=='\/:*?"<>|')
                % Set these to an _ that is valid in a file name
                param(j) = '_';
            end
        end
        
        % Use Normal Distribution for every system error
        obj.hist.Dist = 'norm';
        
        % Display the system error being worked on
        disp([obj.program ' - ' sename]);
        
        % Fill in plot system error info
        obj.fillFiltPlotInfo(i)
        
        % For each engine family
        for j = 1:length(obj.filtDisp.engfams)
            
            % Get the currently selected engine family(s)
            family = obj.filtDisp.engfams{j};
            % If any selected families were 'All'
            if strcmp('All',family)
                % Use the 'Default' family to export thresholds
                family = 'Default';
                % Set the family folder name to be 'All Families'
                famFolder = 'All Families';
            else
                % Set the family folder name to be 
                famFolder = family;
            end
            
            % Populate the values of the thresholds for this engine family
            obj.filt.LSL = obj.getSpecValue(obj.filt.LSLName,family);
            obj.filt.USL = obj.getSpecValue(obj.filt.USLName,family);
            
            % Set the engine family filtering
            obj.filt.engfam = obj.filtDisp.engfams(j);
            
            % Calculate the folders used to store the plots
            boxPlotFold = fullfile(rootDir,sename,'BoxPlots',famFolder);
            histFold = fullfile(rootDir,sename,'Histograms',famFolder);
            %dotPlotFold = fullfile(rootDir,sename,'DotPlots',famFolder);
            
            % Make the family directory
            mkdir(boxPlotFold)
            mkdir(histFold)
            %mkdir(dotPlotFold)
            
            % For each truck type (disable for now)
            for k = 1%:length(obj.filtDisp.vehtypes)
                % Set the truck type filtering
                obj.filt.vehtype = obj.filtDisp.vehtypes(k);
                
                % Start with the masterSwFilt (usually this is set to nothing)
                obj.filt.software = masterSwFilt;
                
                % Fill filtering info into objects
                obj.fillBoxInfo
                obj.fillHistInfo
                %obj.fillDotInfo
                
                %% Box Plot All Software Grouped By Truck
                % Make plot name string
                plotFileName = sprintf('%s_All SW.png',param);
                % Plot for all software
                try
                    % Load the data in for this grouping
                    obj.fillBoxData(1)
                    % Make the plot (visible for now, set to 0 for production)
                    obj.box.makePlot(0)
                    % Save the plot
                    obj.box.savePlot(fullfile(boxPlotFold,plotFileName))
                catch ex
                    if strcmp('Capability:fillBoxData:NoDataFound',ex.identifier)
                        % Skip this plot, this is fine
                    else
                        % Catch no data errors, etc.
                        rethrow(ex)
                    end
                end
                
                %% Box Plot All Software Grouped By Software
                % Make plot name string
                plotFileName = sprintf('%s_Grouped By SW.png',param);
                % Plot for all software
                try
                    % Load the data in for this grouping
                    obj.fillBoxData(0)
                    % Make the plot (visible for now, set to 0 for production)
                    obj.box.makePlot(0)
                    % Save the plot
                    obj.box.savePlot(fullfile(boxPlotFold,plotFileName))
                catch ex
                    if strcmp('Capability:fillBoxData:NoDataFound',ex.identifier)
                        % Skip this plot, this is fine
                    else
                        % Catch no data errors, etc.
                        rethrow(ex)
                    end
                end
                
                %% Histogram All Software
                plotFileName = sprintf('%s.png',param);
                % Plot for all software
                try
                    % Load the data in for this grouping
                    obj.fillHistData
                    % Make the plot (visible for now, set to 0 for production)
                    obj.hist.makePlot(0)
                    % Save the plot
                    obj.hist.savePlot(fullfile(histFold,plotFileName))
                catch ex
                    if strcmp('Capability:fillHistData:NoDataFound',ex.identifier)
                        % Skip this plot, this is fine
                    else
                        % Catch no data errors, etc.
                        rethrow(ex)
                    end
                end
                
                %% DotPlot All Software
                
                
                %% Box Plot For Each Software Present Grouped By Truck
                % Get unique software versions from overally box plot grouped by software
                swPresent = unique(obj.box.GroupData);
                
                % Plot for each software version
                for x = 1:length(swPresent)
                    % Generate the file name of the plot
                    plotFileName = sprintf('%s_%s.png',param,swPresent{x});
                    % Set the software filtering
                    obj.filt.software = [str2double(swPresent{x}) str2double(swPresent{x})];
                    % Fill in plot and filtering info
                    %obj.fillFiltPlotInfo(i)
                    % Fill filtering into the box plot
                    obj.fillBoxInfo
                    % Make a plot for this software
                    try
                        % Load the data in for this grouping
                        obj.fillBoxData(1)
                        % Make the plot (visible for now, set to 0 for production)
                        obj.box.makePlot(0)
                        % Save the plot
                        obj.box.savePlot(fullfile(boxPlotFold,plotFileName))
                    catch ex
                        if strcmp('Capability:fillBoxData:NoDataFound',ex.identifier)
                            % Skip this plot, this is fine
                        else
                            % Catch no data errors, etc.
                            rethrow(ex)
                        end
                    end
                end
                
                %% Histogram For Each Software Present
                % Plot for each software version
                for x = 1:length(swPresent)
                    % Generate the file name of the plot
                    plotFileName = sprintf('%s_%s.png',param,swPresent{x});
                    % Set the software filtering
                    obj.filt.software = [str2double(swPresent{x}) str2double(swPresent{x})];
                    % Fill filtering into the box plot
                    obj.fillHistInfo
                    % Make a plot for this software
                    try
                        % Load the data in for this grouping
                        obj.fillHistData
                        % Make the plot (visible for now, set to 0 for production)
                        obj.hist.makePlot(0)
                        % Save the plot
                        obj.hist.savePlot(fullfile(histFold,plotFileName))
                    catch ex
                        if strcmp('Capability:fillHistData:NoDataFound',ex.identifier)
                            % Skip this plot, this is fine
                        else
                            % Catch no data errors, etc.
                            rethrow(ex)
                        end
                    end
                end
                
                %% DotPlots by Software Version (if desired)
                
                
                
            end
            
            %% Export One Raw Data File
            % Use the master time and software filter
            
            % TBD
            
        end
        
        catch ex
            % Display the error
            disp(ex.getReport)
            % Should log the error
            
            % Move on to next system error
        end
    end
end

function str = groupStr(groupCode)
% Generate a human readable string based on the grouping code for the file name
    switch groupCode
        case 0
            str = 'SW';
        case 1
            str = 'Truck';
        case 2
            str = 'Family';
        case 3
            str = 'Month';
    end
end
