%% Master Capability Running Script
% This script will be the master script used to control the processing of the OBD
% capabilty data
% The last full run, this took 7.35 hours to complete

% Calling this script updates the calibratable parameters for all three engine families
% using the latest values in the mainline
%run('D:\Matlab\Capability\utilities\cal\paramExporter.m')

% Define the root folder for all the output to be dumped into
% Started using full paths because the was a goofy problem where some box plots would get
% dumped into a directory one level deeper than specified
root = 'D:\Matlab\Capability\output\June10_FP\'; % ALWAYS make sure that you have a '\' on the ending folder
jobId = '12 - Cumulative to June 10'; % The folders the plots will be separated into
spreadsheetName = 'Results Summary FP June 10 2013.xlsx'; % Name of the summary spreadsheet

% Define if there is a date or trip filter
trip = 0;  % Don't use trip data (the default behavior)
date = []; % No date filtering (the default behavior)
%% Trip Defenitions
% Polar Trip 2012 -
%trip = 1;                                       % Only trip data
%date = [datenum(2012,1,9) datenum(2012,2,2)];   % Jan 9, 2012 - Feb 2, 2012 (one day before, one day after)
% Arctic Trip 2012 -
%trip = 1;                                       % Only trip data
%date = [datenum(2012,3,11) datenum(2012,4,26)]; % Mar 11, 2012 - Apr 26, 2012 (one day before, one day after)
% Verification Trip 2012 -
%trip = 1;                                       % Only trip data
%date = [datenum(2012,6,23) datenum(2012,7,4)];  % Jun 23, 2012 - Jul 4, 2012 (one day before, one day after)
% Aurora Trip 2012 -
%trip = 1;                                       % Only trip data
%date = [datenum(2012,7,22) datenum(2012,8,22)]; % July 22, 2012 - Aug 22, 2012 (one day before, one day after)

%% Open a new log file to track how long each of these takes
log = logWriter('Master Capability Runner', '../logs/Capability');
globalStart = tic;

%% Regular Event Driven data and histograms

% Initalize the object inside of the lab
e = EventProcessor;
startEvent = tic;
% This took 59 minutes the last time it was run
result = e.runRegularEvent(jobId,[root spreadsheetName],[root 'Histograms'], 'trip', trip, 'date', date);
% Log the time to generate the histograms and calculate the statistics
log.write(sprintf('Time to processes the event driven data was %g seconds or %g minutes.',toc(startEvent),toc(startEvent)/60));

break
%% Make Regular event driven data box plots
% Remake e to help clear out any memory leaks inside the object
clear e;e = EventProcessor;

startEventBox = tic;
% This took 191 minutes the last time it was run
e.makeBoxPlots([root 'BoxPlotsEvent'],jobId, 'trip', trip, 'date', date)
% Log the time it took to generate the Event Driven box plots
log.write(sprintf('Time to generate Event Driven box plots was %g seconds or %g minutes.',toc(startEventBox),toc(startEventBox)/60));

clear e

%break
%% Special Event Driven data (like floating thresholds) and plots

%% Min/Max data box plots

m = MinMaxProcessor;

startMinMaxBox = tic;
% This takes 137 minutes to run through all the diagnostics
m.makeBoxPlots([root 'BoxPlotsMinMax'],jobId, 'trip', trip, 'date', date)

% Print the time to make all the box plots
log.write(sprintf('Time to generate MinMax box plots was %g seconds or %g minutes.',toc(startMinMaxBox),toc(startMinMaxBox)/60));

clear m


%pause
log.write(sprintf('------> Total time to run everything was %g seconds or %g minutes.',toc(globalStart),toc(globalStart)/60));

%% Export Raw data

% Initalize the data exporting object
o = RawDataExport;

% About 23 minutes
a = tic;
o.MinMaxData([root 'RawData\MinMax\']);
log.write(sprintf('Time to export MinMax raw data was %g seconds or %g minutes.',toc(a),toc(a)/60));

% Clear o in between to hopefully prevent memory leaks and out of memory errors
clear o
o = RawDataExport;

% About 51 miniutes the last time it was run
b = tic;
o.EventData([root 'RawData\EventDriven\']);
log.write(sprintf('Time to export Event Driven raw data was %g seconds or %g minutes.',toc(b),toc(b)/60));

clear o

% Copy that output onto the N: drive


% Make the folder read-only after updating the data


% Log the global time to complete everything
log.write(sprintf('------> Total time to run everything was %g seconds or %g minutes.',toc(globalStart),toc(globalStart)/60));

%% Parallel Figure Generation

% The problem with this code is that when printing a figure from a headless matlab
% instance, Matlab uses Ghostscript to generate the figure instead of the built-in matlab
% drivers. As such, you cannot change the resolution from 72 dpi by using the '-r' command
% to specify dpi as it is ignored for Ghostscript. Search the help for
% "Printing and Exporting without a Display" for more information on this topic.

% % Start the Matlab workers
% matlabpool open local 6
% 
% spmd
%     % Initalize the object inside of the lab
%     e = EventProcessor;
%     
%     % Run different code on different labs
%     switch labindex
%         case 1 % Lab 1
%             All_All = e.runRegularEvent('Cumulative', 0, 0);
%             X1_All = e.runRegularEvent('Cumulative', 1, 0);
%         case 2 % Lab 2
%             X2_3_All = e.runRegularEvent('Cumulative', 2, 0);
%             Black_All = e.runRegularEvent('Cumulative', 3, 0);
%         case 3 % Lab 3
%             All_Field = e.runRegularEvent('Cumulative', 0, 1);
%             X1_Field = e.runRegularEvent('Cumulative', 1, 1);
%         case 4 % Lab 4
%             X2_3_Field = e.runRegularEvent('Cumulative', 2, 1);
%             Black_Field = e.runRegularEvent('Cumulative', 3, 1);
%         case 5 % Lab 5
%             All_Eng = e.runRegularEvent('Cumulative', 0, 2);
%             X1_Eng = e.runRegularEvent('Cumulative', 1, 2);
%         case 6 % Lab 6
%             X2_3_Eng = e.runRegularEvent('Cumulative', 2, 2);
%             Black_Eng = e.runRegularEvent('Cumulative', 3, 2);
%         otherwise
%             disp('Too many labs')
%     end
% end
% 
% clear p
% 
% % Collect the results back into the main workspace
% a = All_All{1};
% b = X1_All{1};
% c = X2_3_All{2};
% d = Black_All{2};
% e = All_Field{3};
% f = X1_Field{3};
% g = X2_3_Field{4};
% h = Black_Field{4};
% i = All_Eng{5};
% j = X1_Eng{5};
% k = X2_3_Eng{6};
% l = Black_Eng{6};
% 
% clear All_All Black_Eng X2_3_Eng X1_Eng All_Eng Black_Field X2_3_Field X1_Field All_Field
% clear Black_All X2_3_All X1_All
% 
% % Close the Matlab workers
% matlabpool close


%% Old Event Driven data code
%%%%%%%%
% % Run all 12 combinations
% All_All = e.runRegularEvent('Cumulative', 0, 0);
% X1_All = e.runRegularEvent('Cumulative', 1, 0);
% X2_3_All = e.runRegularEvent('Cumulative', 2, 0);
% Black_All = e.runRegularEvent('Cumulative', 3, 0);
% All_Field = e.runRegularEvent('Cumulative', 0, 1);
% X1_Field = e.runRegularEvent('Cumulative', 1, 1);
% X2_3_Field = e.runRegularEvent('Cumulative', 2, 1);
% Black_Field = e.runRegularEvent('Cumulative', 3, 1);
% All_Eng = e.runRegularEvent('Cumulative', 0, 2);
% X1_Eng = e.runRegularEvent('Cumulative', 1, 2);
% X2_3_Eng = e.runRegularEvent('Cumulative', 2, 2);
% Black_Eng = e.runRegularEvent('Cumulative', 3, 2);
% 
% startSpreadsheets = tic;
% % Define the name of the spreadsheet
% spreadsheet = '..\output\Results - May 10.xlsx';
% % Save those results into an excel spreadsheet
% xlswrite(spreadsheet,All_All,'All Fam - All');
% xlswrite(spreadsheet,All_Eng,'All Fam - Eng')
% xlswrite(spreadsheet,All_Field,'All Fam - Field')
% xlswrite(spreadsheet,Black_All,'Black - All')
% xlswrite(spreadsheet,Black_Eng,'Black - Eng')
% xlswrite(spreadsheet,Black_Field,'Black - Field')
% xlswrite(spreadsheet,X1_All,'X1 - All')
% xlswrite(spreadsheet,X1_Eng,'X1 - Eng')
% xlswrite(spreadsheet,X1_Field,'X1 - Field')
% xlswrite(spreadsheet,X2_3_All,'X2_3 - All')
% xlswrite(spreadsheet,X2_3_Eng,'X2_3 - Eng')
% xlswrite(spreadsheet,X2_3_Field,'X2_3 - Field')
% % Log the time it took to write the spreadsheets
% log.write(sprintf('Time to write the 12 spreadsheets was %g seconds.', toc(startSpreadsheets)));
%%%%%%%%
