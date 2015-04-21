function [Program,TruckName,CalVersion,Date1,ActiveFaultCode,TimeFaultFirstOccurred,ActiveErrorIndex,ECMRunTimes,MilestheFCwasactive,HourstheFCwasactive,TotalMilesthatday,TotalHoursthatday,InactiveFaults,MILStatus,Odometerkmwhenfaultisset,FilenamewhereFaultFirstOccurred,InactiveErrorIndex,VehicleSpeedattimeofFaultmph] = AddFC2vector(workbookFile,sheetName,startRow,endRow)
%IMPORTFILE Import data from a spreadsheet into vector columns
%   [Program,TruckName,CalVersion,Date1,ActiveFaultCode,TimeFaultFirstOccurred,ActiveErrorIndex,ECMRunTimes,MilestheFCwasactive,HourstheFCwasactive,TotalMilesthatday,TotalHoursthatday,InactiveFaults,MILStatus,Odometerkmwhenfaultisset,FilenamewhereFaultFirstOccurred,InactiveErrorIndex,VehicleSpeedattimeofFaultmph]
%   = IMPORTFILE(FILE) reads data from the first worksheet in the Microsoft
%   Excel spreadsheet file named FILE and returns the data as column
%   vectors.
%
%   [Program,TruckName,CalVersion,Date1,ActiveFaultCode,TimeFaultFirstOccurred,ActiveErrorIndex,ECMRunTimes,MilestheFCwasactive,HourstheFCwasactive,TotalMilesthatday,TotalHoursthatday,InactiveFaults,MILStatus,Odometerkmwhenfaultisset,FilenamewhereFaultFirstOccurred,InactiveErrorIndex,VehicleSpeedattimeofFaultmph]
%   = IMPORTFILE(FILE,SHEET) reads from the specified worksheet.
%
%   [Program,TruckName,CalVersion,Date1,ActiveFaultCode,TimeFaultFirstOccurred,ActiveErrorIndex,ECMRunTimes,MilestheFCwasactive,HourstheFCwasactive,TotalMilesthatday,TotalHoursthatday,InactiveFaults,MILStatus,Odometerkmwhenfaultisset,FilenamewhereFaultFirstOccurred,InactiveErrorIndex,VehicleSpeedattimeofFaultmph]
%   = IMPORTFILE(FILE,SHEET,STARTROW,ENDROW) reads from the specified
%   worksheet for the specified row interval(s). Specify STARTROW and
%   ENDROW as a pair of scalars or vectors of matching size for
%   dis-contiguous row intervals. To read to the end of the file specify an
%   ENDROW of inf.
%
%	Non-numeric cells are replaced with: NaN
%
% Example:
%   [Program,TruckName,CalVersion,Date1,ActiveFaultCode,TimeFaultFirstOccurred,ActiveErrorIndex,ECMRunTimes,MilestheFCwasactive,HourstheFCwasactive,TotalMilesthatday,TotalHoursthatday,InactiveFaults,MILStatus,Odometerkmwhenfaultisset,FilenamewhereFaultFirstOccurred,InactiveErrorIndex,VehicleSpeedattimeofFaultmph]
%   =
%   importfile('Dragnet_DragonFront_CumulativeFaultCodeHistory.xlsx','T0106_EG100166_3500',2,95);
%
%   See also XLSREAD.

% Dingchao Zhang on 2015/03/04 

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 3
    startRow = 2;
    endRow = 95;
end

%% Import the data
[~, ~, raw] = xlsread(workbookFile, sheetName, sprintf('A%d:R%d',startRow(1),endRow(1)));
for block=2:length(startRow)
    [~, ~, tmpRawBlock] = xlsread(workbookFile, sheetName, sprintf('A%d:R%d',startRow(block),endRow(block)));
    raw = [raw;tmpRawBlock]; %#ok<AGROW>
end
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
Program = cellVectors(:,1);
TruckName = cellVectors(:,2);
CalVersion = cellVectors(:,3);
Date1 = cellVectors(:,4);
ActiveFaultCode = cellVectors(:,5);
TimeFaultFirstOccurred = data(:,1);
ActiveErrorIndex = cellVectors(:,6);
ECMRunTimes = data(:,2);
MilestheFCwasactive = data(:,3);
HourstheFCwasactive = data(:,4);
TotalMilesthatday = data(:,5);
TotalHoursthatday = data(:,6);
InactiveFaults = cellVectors(:,7);
MILStatus = cellVectors(:,8);
Odometerkmwhenfaultisset = data(:,7);
FilenamewhereFaultFirstOccurred = cellVectors(:,9);
InactiveErrorIndex = cellVectors(:,10);
VehicleSpeedattimeofFaultmph = data(:,8);

