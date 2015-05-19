%% Programs
% Generate plots for all these engine programs

% Define the program names to work on
programs = {...
            'Pacific';
            'Acadia';
            'Atlantic';
            'Ayrton';
            'Mamba';
            'Pele';
            'DragonCC';
            'DragonMR';
            'Seahawk';
            'Yukon';
            'Nighthawk';
            'Blazer';
            'Bronco';
            'Clydesdale';
            'Shadowfax';
            'Vanguard';
            'Ventura';
            'Sierra';
            };

%% Output Location and Filtering

% Starting output directory (new folder based on current time-stamp)
startDir = ['..\Plots_Generated_' datestr(now,'yy-mm-dd_HH-MM-SS')];

% Define the starting and end date to plot data from
% Start 90 days ago
startDate = ceil(now)-90;
% No End Filter (i.e. data up to today)
endDate = now;

% % Plot Folder Name
% plotFold = ['Plots_' datestr(startDate,'yymmdd') '_' datestr(endDate,'yymmdd')];

% Master Date Filtering (based on above)
masterDateFilt = [startDate endDate];

% Master Software Filtering (should only be used on one program at a time)
% This should usually be [NaN NaN]
masterSwFilt = [NaN NaN];

%% Make Plots
% Initalize vector to hold the time it took to run each program
timeToRun = zeros(size(programs));

% For each desired program
for i = 1:length(programs)
    % Plot Folder Name
    plotFold = [programs{i} '_Plots_' datestr(startDate,'yymmdd') '_' datestr(endDate,'yymmdd')];

    try % For now
    tic
    % Open a capability object
    cap = Capability(programs{i});
    % Make the correct folder name for the plots
%     outputDir = fullfile(startDir,programs{i},plotFold);
    outputDir = fullfile(startDir,plotFold);
    % Make the standard array of plots for this program
    cap.makePlots(outputDir,masterDateFilt,masterSwFilt)
    % Eventually copy them to the network
    %!xcopy
    % Clear cap to free any memory it leaked
    clear cap
    % Save the time to complete
    timeToRun(i) = toc;
    catch ex
        disp(ex.getReport)
    end
end

% Blank line
disp(' ');

% Print to total times to run plots for each program
for i = 1:length(programs)
    fprintf('Time to run % 15s: % 3.1f minutes\r',programs{i},timeToRun(i)/60)
end

%% xcopy to Network
% ?



%% Run time for the initial try (missed some runs becase of errors)
% Time to run         Pacific:  339.2 minutes
% Time to run        Atlantic:  ?.? minutes
% Time to run           Mamba:  ?.? minutes
% Time to run            Pele:  ?.? minutes
% Time to run        DragonCC:  ?.? minutes
% Time to run        DragonMR:  115.3 minutes
% Time to run         Seahawk:  172.6 minutes
% Time to run           Yukon:  92.8 minutes

%% Big Run April 22, 2014
% Time to run         Pacific:  453.6 minutes
% Time to run        Atlantic:  49.2 minutes
% Time to run           Mamba:  35.6 minutes
% Time to run            Pele:  37.4 minutes
% Time to run        DragonCC:  134.4 minutes
% Time to run        DragonMR:  126.3 minutes
% Time to run         Seahawk:  363.7 minutes
% Time to run           Yukon:  118.3 minutes
% Time to run          Blazer:  23.1 minutes
% Time to run          Bronco:  37.2 minutes
