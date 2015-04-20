function Summary_FC(TruckNumber,y,m)

warning off
fprintf('\n Running Summary_FC_Tracking... \n')

datestr(now)
d = 1;
PathDefns

dataDateStr = datestr(dataDateNum, 'yyyy_mm');
dataDateStr2 = datestr(dataDateNum, 'mmmyy');

if ~exist(FaultCodeSummaryDir, 'dir')
    mkdir(FaultCodeSummaryDir);
end

io_FC_AccumulationHistory = [FaultCodeSummaryDir TruckNumber '_' TruckPowerRating '_' dataDateStr '_FaultCodeHistory.mat'];
xlastdatenum  = 0;
xTruckProgram = [];
xTruckNumber  = [];
xdatestamp    = [];
xCalibration  = [];
xFC           = [];
xinFC         = {};
xECMRunTime   = [];
xMilesActive  = [];
xTimeActive   = [];
xMilesPerDay  = [];
xTimePerDay   = [];
xFCindex      = {};
xFCfile       = {};
xMIL          = {};
xMILS         = {};
xWarnLamp     = {};
xStopLamp     = {};
xFCtime       = {};
xInFCindex      = {};

TruckNum = TruckNumber;
sheetName = dataDateStr2;

xlsName = [FaultCodeSummaryDir, TruckNumber ' FaultCodeHistory.xlsx'];     %, ' ', dataDateStr,'.xls'];

mat_dir = MatFileDir;
eval(['matfiles_dir = [mat_dir,''' TruckNumber '*.mat''];'])
filenames = struct2cell(dir(matfiles_dir));
if isempty(filenames)
    clear all
    disp('No data for that month')
    return
end
[a,xx2] = size(filenames);

disp(' ')
disp(['Starting FC Tracking summary for ' sheetName])
disp(' ')
InitFiles = '';
for file_no = 1:xx2
    no10 = 0; %flag for existance of 10sec matfile.
%     try
%     {
        load([mat_dir, filenames{1,file_no}],'faultsActive','MIL_Status','ActiveFaults','ActiveFaults_200ms','ActiveFaults_1_Sec_Screen_1','InactiveFaults','InactiveFaults_1_Sec_Screen_1','faultsActiveList','faultsActiveListStr','m','d','y','TruckProgram',...
            'FC_*','Vehicle_Speed','Vehicle_Speed_1_Sec_Screen_1','ECM_Run_Time','ECM_Run_Time_1_Sec_Screen_1','PC_TimeStamp',...
            'faultsActiveListXtra','Calibration_Version','Calibration_Version_1_Sec_Screen_1','tod','dataDateStr','TruckPhase','tod_1_Sec_Screen_1','tod','dataDateStr');        
        PathDefns
%         if exist([InitFiles,TruckNumber,'_',TruckPhase,'_',dataDateStr,'_10_Sec.mat'], 'file')
%             load([InitFiles,TruckNumber,'_',TruckPhase,'_',dataDateStr,'_10_Sec.mat'],'MIL_Status_10_Sec','ECM_Run_Time_10_Sec','Warning_Lamp_10_Sec','Malfunction_Indicator_Lamp_Status_10_Sec','Stop_Lamp_10_Sec','ECM_Active_Error_Index_*','ECM_Inactive_Error_Index_*')
%         else
            no10 = 1;
%         end
    disp(['Running ',filenames{1,file_no}])
    %         disp(faultsActive)
    if xlastdatenum ~= datenum(y,m,d)
        xlastdatenum = datenum(y,m,d);
    end
    existList = {'ActiveFaults';'ActiveFaults_200ms';'InactiveFaults';'ECM_Run_Time';'Calibration_Version';'tod';'Vehicle_Speed'};
    for ijk = 1:length(existList)
        if eval(['~exist(''' existList{ijk} ''',''var'') && exist(''' existList{ijk} '_1_Sec_Screen_1'',''var'')'])
            eval([existList{ijk} '=' existList{ijk} '_1_Sec_Screen_1;'])
        end
    end
    
    if no10 == 0
        errind = [];
        inerrind = [];
        for ijk = 0:length(who('ECM_Active_Error_Index_*'))-1
            eval(['inerrind = [inerrind;unique(ECM_Active_Error_Index_' num2str(ijk) '__10_Sec)];'])
        end
        for ijk1 = 0:length(who('ECM_Inactive_Error_Index_*'))-1
            eval(['inerrind = [inerrind;unique(ECM_Inactive_Error_Index_' num2str(ijk1) '__10_Sec)];'])
        end
        errind(errind ==0 | isnan(errind)) = [];
        errind = errind';
        errind = num2str(errind);
        errind = regexprep(errind,'-999.99','');
        errind = regexprep(errind, '\s+', ' ');
        
        inerrind(inerrind ==0 | isnan(inerrind)) = [];
        inerrind = inerrind';
        inerrind = num2str(inerrind);
        inerrind = regexprep(inerrind,'-999.99','');
        inerrind = regexprep(inerrind, '\s+', ' ');
    else
        errind = 'No index data available';
        inerrind = 'No index data available';
    end
    if isempty(errind)
        errind = 'No index data available';
    end
    if isempty(inerrind)
        inerrind = 'No index data available';
    end 
    
    if exist('tod','var')
        timediff = [1; diff(tod)];
        timediff(timediff>20) = 1;
    else
        continue
    end
    if ~exist('faultsActive','var')
        continue
    end
    if ~exist('ECM_Run_Time','var')
        continue
    end
    if faultsActive >= 1 && ~isempty(ActiveFaults)
        test1 = [];
        InactiveFaults(cellfun(@(x) all(isnan(x)),InactiveFaults)) = {''};
        test = regexprep(unique(InactiveFaults),'00:','');
        test = regexprep(test,'  ','');
        for ijk = 1:length(test)
            if length(test{ijk}) == 0
                continue
            end
            ab = toklin(test{ijk},' ')';
            test1= [test1; str2double(ab)];
        end
        test1(isnan(test1)) = [];
        inAF = unique(test1)';
        inAF = mat2str(inAF);
        clear test1 ab ijk test
        for q = 1:(length(faultsActiveList))
            str = num2str(faultsActiveList(q), '%04d');
            FCName = ['FC_', str];
            xinFC{end+1,1} = inAF;
            xFCindex = [xFCindex;errind];
            xInFCindex = [xInFCindex;inerrind];
            xFC = cat(1, xFC, FCName);
            eval(['FCValue = ' FCName ';']);
            FC_index_count = find(FCValue == 1);
            xECMRunTime = [xECMRunTime; ECM_Run_Time(FC_index_count(1))];
            
            if exist('Vehicle_Speed','var')
                Vehicle_Speed(isnan(Vehicle_Speed)) = 0;
                if length(Vehicle_Speed) < length(FCValue)
                    Vehicle_Speed(length(Vehicle_Speed)+1:length(FCValue)) = 0;
                end
                VSpeed = Vehicle_Speed(FC_index_count) .* timediff(FC_index_count) ./ (1.609 * 3600);
                if length(Vehicle_Speed) == length(timediff)
                    VSpeedforDay = Vehicle_Speed .* timediff./ (1.609 * 3600);
                else
                    VSpeed = 0;
                    VSpeedforDay = 0;
                end
            else
                VSpeed = 0;
                VSpeedforDay = 0;
            end
            xMilesActive = [xMilesActive;sum(VSpeed)];                  %mile
            xTimeActive = [xTimeActive;(sum(timediff(FC_index_count)))/3600];  %hour
            xMilesPerDay = [xMilesPerDay;sum(VSpeedforDay)];           %miles
            xTimePerDay = [xTimePerDay;sum(timediff)/3600];     %hours
            if exist('faultsActiveListXtra','var')
                if ~isempty(faultsActiveListXtra{q,1})
                    xFCfile = [xFCfile;faultsActiveListXtra{q,1}];
                else
                    xFCfile = [xFCfile; 'No info'];
                end
                if ~isempty(faultsActiveListXtra{q,2})
                    xFCtime = [xFCtime;faultsActiveListXtra{q,2}];
                else
                    xFCtime = [xFCtime; 'No info'];
                end
            else
                xFCfile = [xFCfile; 'No info'];
                xFCtime = [xFCtime; 'No info'];
            end
            if y < 2000, y = 2000 + y; end
            dataDateNum = datenum([y, m, d]);
            dataDateStr = datestr(dataDateNum, 'dd-mmm-yyyy');
            xdatestamp = cat(1, xdatestamp, dataDateStr);
            
            if exist('TruckNumber','var')
                xTruckNumber = cat(1, xTruckNumber, TruckNumber);
            end
            if exist('TruckProgram','var')
                xTruckProgram = cat(1, xTruckProgram, TruckProgram);
            end
            if exist('Calibration_Version','var')
                while isempty(Calibration_Version{1,1}) == 1
                    Calibration_Version(1) = [];
                    [~,c]=size(Calibration_Version);
                    if c == 0
                        break
                    end
                end
                if isempty(Calibration_Version)
                    xCali = '00.00.0.0';
                    xCalibration = cat(1, xCalibration, xCali);
                elseif length(Calibration_Version{1,1}) > 13
                    if length(Calibration_Version) == 1
                        xCali = cellstr('00.00.0.0');
                        xCalibration = cat(1, xCalibration, xCali);
                    elseif isempty(Calibration_Version{2,1})
                        xCali = cellstr('00.00.0.0');
                        xCalibration = cat(1, xCalibration, xCali);
                    else
                        xCalibration = cat(1, xCalibration, cellstr(Calibration_Version{end,1}));
                    end
                else
                    xCalibration = cat(1, xCalibration, cellstr(Calibration_Version{1,1}));
                end
            else
                xCali = cellstr('00.00.0.0');
                xCalibration = cat(1, xCalibration, xCali);
            end
            if ~exist('ECM_Run_Time_10_Sec','var')
                xWarnLamp = [xWarnLamp; 'N/A'];
                xStopLamp = [xStopLamp; 'N/A'];
                xMILS = [xMILS; 'N/A'];
            else
                rECM1 = round(ECM_Run_Time);
                eval(['rECM1 = rECM1(FC_' num2str(faultsActiveList(q),'%04d') '==1);'])
                rECM10 = round(ECM_Run_Time_10_Sec);
                [~,~,ECM10rows]=intersect(rECM1,rECM10);
                if exist('Warning_Lamp_10_Sec','var')
                    if isempty(find(ismember(Warning_Lamp_10_Sec(ECM10rows),'ON'), 1))
                        xWarnLamp = [xWarnLamp; 'OFF'];
                    else
                        xWarnLamp = [xWarnLamp; 'ON'];
                    end
                else
                    xWarnLamp = [xWarnLamp; 'N/A'];
                end
                if isempty(find(ismember(Stop_Lamp_10_Sec(ECM10rows),'ON'), 1))
                    xStopLamp = [xStopLamp; 'OFF'];
                else
                    xStopLamp = [xStopLamp; 'ON'];
                end
                if ~exist('Malfunction_Indicator_Lamp_Status_10_Sec','var')
                    xMILS = [xMILS; 'N/A'];
                else
                    if isempty(find(ismember(Malfunction_Indicator_Lamp_Status_10_Sec(ECM10rows),'ON'), 1))
                        xMILS = [xMILS; 'OFF'];
                    else
                        xMILS = [xMILS; 'ON'];
                    end
                end
            end
            if ~exist('MIL_Status','var') && exist('MIL_Status_10_Sec','var')
                if isempty(find(ismember(MIL_Status_10_Sec(ECM10rows),'ON'), 1))
                    xMIL = [xMIL; 'OFF'];
                else
                    xMIL = [xMIL; 'ON'];
                end
            else
                if ~exist('MIL_Status','var')
                    xMIL = [xMIL;'N/A'];
                elseif eval(['isempty(find(MIL_Status(FC_' num2str(faultsActiveList(q),'%04d') '==1)==1))'])
                %elseif isempty(find(MIL_Status(['FC_' num2str(faultsActiveList(q),'%04d')]) ==1)==1)
                    xMIL = [xMIL; 'OFF'];
                else
                    xMIL = [xMIL; 'ON'];
                end
            end
        end
    end
    clearvars -except io_FC_AccumulationHistory InitFiles TruckNumber TruckProgram xlsName sheetName mat_dir filenames file_no x*
end
%end
save(io_FC_AccumulationHistory)
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
    'Malfunction Indicator Lamp Status'
    'Warning Lamp'
    'Stop Lamp'
    'File Name Where Fault First Occurred'
    'Inactive Error Index'
    };
xlsdata = transpose(header_text);
if ~isempty(xFC)
    xlsdata = [xlsdata;[cellstr(xTruckProgram),cellstr(xTruckNumber),cellstr(xCalibration),cellstr(xdatestamp), ...
        cellstr(xFC),xFCtime,xFCindex,num2cell(xECMRunTime),num2cell(xMilesActive), ...
        num2cell(xTimeActive),num2cell(xMilesPerDay),num2cell(xTimePerDay),xinFC,xMIL,xMILS,xWarnLamp,xStopLamp,xFCfile,xInFCindex]];
end
disp(' ')
disp(['saving FC Tracking Summary for ' sheetName ' ...'])
disp(' ')
xlswrite(xlsName,xlsdata,sheetName);
datestr(now)
clear java
clear all