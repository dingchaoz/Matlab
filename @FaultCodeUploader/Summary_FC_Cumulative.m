
%**************************************************************************
% Script to pull the cumulative Fault code history for a truck over a
% period of time
% Sravanthi Goparaju 11/3/2011 Version 1
% Phil Jacher 8/23/2012 Version 2 - Added Fault index/inactive faults
% Shruthi Srivatsan 11/19/2013 Version 3 - Modified program for HD Acadia
% Only
%**************************************************************************

function Summary_FC_Cumulative(TruckNumber)

PathDefns
warning off
fprintf('\n Running Summary_FC_Cumulative... \n')

datestr(now)

Total_TruckProgram = [];
Total_TruckNumber  = [];
Total_datestamp    = [];
Total_Calibration  = [];
Total_FC           = [];
Total_ECMRunTime   = [];
Total_MilesActive  = [];
Total_TimeActive   = [];
Total_MilesPerDay  = [];
Total_TimePerDay   = [];
Total_inFC         = [];
Total_FCindex      = {};
Total_InFCindex    = {};
Total_FCfile       = {};
Total_MIL          = {};
Total_WarnLamp     = {};
Total_StopLamp     = {};
Total_FCtime       = {};

xlsName = FaultCodeCumDir; 

if length(TruckNumber)>= 31
    cumuSheetName = TruckNumber(1:30);
else
    cumuSheetName = TruckNumber;
end



mat_dir = FaultCodeSummaryDir;
matfiles_dir = [mat_dir,'*.mat'];
filenames = struct2cell(dir(matfiles_dir));
if isempty(filenames)
    clear all
    disp('No data for that truck')
    return
end
[a,xx2] = size(filenames);

disp(' ')
disp(['Starting Cumulative FC Tracking summary for ' cumuSheetName])
disp(' ')

for file_no = 1:xx2
    disp(['Running ',filenames{1,file_no}])
    load([mat_dir, filenames{1,file_no}],'xFCtime','xTruckProgram','xTruckNumber','xCalibration','xdatestamp','xFC','xECMRunTime','xMilesActive','xTimeActive',...
        'xMilesPerDay','xTimePerDay','xinFC','xInFCindex','xFCindex','xMIL','xWarnLamp','xStopLamp','xFCfile')
    
    if exist('xTruckProgram','var')
        Total_TruckProgram  = cat(1, Total_TruckProgram, xTruckProgram);
    end
    if exist('xTruckNumber','var')
        Total_TruckNumber    = cat(1, Total_TruckNumber, xTruckNumber);
    end
    if exist('xCalibration','var')
        Total_Calibration     = cat(1, Total_Calibration, xCalibration);
    end
    if exist ('xdatestamp','var')
        Total_datestamp     = cat(1, Total_datestamp, xdatestamp);
    end
    if exist('xFC','var')
        Total_FC     = cat(1, Total_FC, xFC);
    end
    if exist('xFCfile','var')
        Total_FCfile     = cat(1, Total_FCfile, xFCfile);
    else
        if ~isempty(xMilesActive)
        for k = 1:length(xMilesActive)
            xFCfile{k,1} = 'No info';
        end
        else
            xFCfile = [];
        end
        Total_FCfile     = cat(1, Total_FCfile, xFCfile);
    end
    if exist('xFCtime','var')
        Total_FCtime     = cat(1, Total_FCtime, xFCtime);
    else
        if ~isempty(xMilesActive)
        for k = 1:length(xMilesActive)
            xFCtime{k,1} = 'No info';
        end
        else
            xFCtime = [];
        end
        Total_FCtime     = cat(1, Total_FCtime, xFCtime);
    end
    if exist('xinFC','var')
        Total_inFC     = cat(1, Total_inFC, xinFC);
    else
        if ~isempty(xMilesActive)
        for k = 1:length(xMilesActive)
            xinFC{k,1} = 'No info';
        end
        else
            xinFC = [];
        end
        Total_inFC     = cat(1, Total_inFC, xinFC);
    end
    if exist('xFCindex','var')
        Total_FCindex     = cat(1, Total_FCindex, xFCindex);
    else
        if ~isempty(xMilesActive)
        for k = 1:length(xMilesActive)
            xFCindex{k,1} = 'No index data available';
        end
        else
            xFCindex = [];
        end
        Total_FCindex     = cat(1, Total_FCindex, xFCindex);
    end
    
    if exist('xInFCindex','var' )
        Total_InFCindex = cat(1,Total_InFCindex,xInFCindex);
    else
        if ~isempty(xMilesActive)
            for k = 1:length(xMilesActive)
                xInFCindex{k,1} = 'No index data available';
            end
        else
            xInFCindex = [];
        end
        Total_InFCindex = cat(1,Total_InFCindex,xInFCindex);
    end
        
    if exist('xECMRunTime','var')
        Total_ECMRunTime = [Total_ECMRunTime; xECMRunTime];
    end
    if exist('xMilesActive','var')
        Total_MilesActive = [Total_MilesActive; xMilesActive];
    end
    if exist('xTimeActive','var')
        Total_TimeActive  = [Total_TimeActive; xTimeActive];
    end
    if exist('xMilesPerDay','var')
        Total_MilesPerDay    = [Total_MilesPerDay; xMilesPerDay];
    end
    if exist('xTimePerDay','var')
        Total_TimePerDay = [Total_TimePerDay; xTimePerDay];
    end   
    Total_MIL = [Total_MIL;xMIL];
%    Total_MILS = [Total_MILS;xMILS];
    Total_WarnLamp = [Total_WarnLamp;xWarnLamp];
    Total_StopLamp = [Total_StopLamp;xStopLamp];
    clearvars -except TruckNumber TruckProgram xlsName cumuSheetName mat_dir filenames file_no xx2 Total_*
end

header_text = {
    'Program'
    'TruckName'
    'Cal Version'
    'Date'
    'Active Fault Code'
    'Time Fault First Occurred'
    'Active Error Index'
    'ECM Run Time(s)'
    'Miles the FC was active'
    'Hours the FC was active'
    'Total Miles that day'
    'Total Hours that day'
    'Inactive Faults'
    'MIL Status'   
    'Inactive Error Index'
    'Warning Lamp'
    'Stop Lamp'  
    'File Name Where Fault First Occurred'
    };
header_text = transpose(header_text);
   
if ~isempty(Total_TruckProgram)
xlsdata = [header_text;[cellstr(Total_TruckProgram),cellstr(Total_TruckNumber),Total_Calibration,cellstr(Total_datestamp), ...
cellstr(Total_FC),Total_FCtime,Total_FCindex,num2cell(Total_ECMRunTime),num2cell(Total_MilesActive),num2cell(Total_TimeActive), ...
num2cell(Total_MilesPerDay),num2cell(Total_TimePerDay),Total_inFC,Total_MIL,Total_InFCindex,Total_WarnLamp,Total_StopLamp,Total_FCfile]];

disp(' ')
disp(['saving FC Tracking Summary for ' cumuSheetName ' ...'])
disp(' ')

xlswrite(xlsName,xlsdata,cumuSheetName,'A1');
else
    display('Nothing to save')
end
datestr(now)
clear all
clear java