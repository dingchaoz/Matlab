%% Import data from spreadsheet into vector columns
% Script for importing data from the following spreadsheet:
%
%    Workbook:
%    C:\Users\ks692\Documents\MATLAB\CapabilityGUI\FaultCodeHistoryscripts\Dragnet_DragonFront_CumulativeFaultCodeHistory.xlsx
%    Worksheet: T0106_EG100166_3500
%
% To extend the code for use with different selected data or a different
% spreadsheet, generate a function instead of a script.

% Dingchao Zhang on 2015/03/04 

%% Create arrays to hold values
Program = {};
TruckName = {};
CalVersion = {};
Date1 = {};
ActiveFaultCode = {};
ActiveErrorIndex = {};
InactiveFaults = {};
MILStatus = {};
InactiveErrorIndex = {};
FilenamewhereFaultFirstOccurred = {};
ECMRunTimes = [];
TimeFaultFirstOccurred = [];
MilestheFCwasactive = [];
HourstheFCwasactive = [];
TotalMilesthatday = [];
TotalHoursthatday = [];
Odometerkmwhenfaultisset = [];
VehicleSpeedattimeofFaultmph = [];

% FCCumulativehistory workbook
wkbk = 'C:\Users\ks692\Documents\MATLAB\CapabilityGUI\FaultCodeHistoryscripts\Dragnet_HD_CumulativeFaultCodeHistory.xlsx';

% Read the workbook's info
[type,sheetname] = xlsfinfo(wkbk);

% Get the number of spreasheets in the workbook
m=size(sheetname,2); 

%% Import the data
for sheet = 1 : m
[~, ~, raw] = xlsread(wkbk,sheet,'A2:R15');
% Need to get a sanity check to not import NaN values from empty
% spreadsheet
% if ~isempty(raw(,2
% else
%     break;
% end
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,[1,2,3,4,5,7,13,14,16,17]);
raw = raw(:,[6,8,9,10,11,12,15,18]);

%% Replace date strings by MATLAB serial date numbers (datenum)
% R = ~cellfun(@isequalwithequalnans,dateNums,raw) & cellfun('isclass',raw,'char'); % Find spreadsheet dates
% raw(R) = dateNums(R);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
data = reshape([raw{:}],size(raw));


%% Allocate imported array to column variable names
Program = vertcat(Program,cellVectors(:,1));
TruckName = vertcat(TruckName,cellVectors(:,2));
CalVersion = vertcat(CalVersion,cellVectors(:,3));
Date1 = vertcat(Date1,cellVectors(:,4));
ActiveFaultCode = vertcat(ActiveFaultCode,cellVectors(:,5));
TimeFaultFirstOccurred = vertcat(TimeFaultFirstOccurred,data(:,1));
ActiveErrorIndex = vertcat(ActiveErrorIndex,cellVectors(:,6));
ECMRunTimes = vertcat(ECMRunTimes,data(:,2));
MilestheFCwasactive = vertcat(MilestheFCwasactive,data(:,3));
HourstheFCwasactive = vertcat(HourstheFCwasactive,data(:,4));
TotalMilesthatday = vertcat(TotalMilesthatday,data(:,5));
TotalHoursthatday = vertcat(TotalHoursthatday,data(:,6));
InactiveFaults = vertcat(InactiveFaults,cellVectors(:,7));
MILStatus = vertcat(MILStatus,cellVectors(:,8));
Odometerkmwhenfaultisset = vertcat(Odometerkmwhenfaultisset,data(:,7));
FilenamewhereFaultFirstOccurred = vertcat(FilenamewhereFaultFirstOccurred,cellVectors(:,9));
InactiveErrorIndex = vertcat(InactiveErrorIndex,cellVectors(:,10));
VehicleSpeedattimeofFaultmph = vertcat(VehicleSpeedattimeofFaultmph,data(:,8));

%% Clear temporary variables
%clearvars data raw cellVectors R;
end