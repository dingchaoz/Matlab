% This program is for retrieving necessary parameters for assessing PM
% sensor diagnostics' capability.
% Author: Sri Seshadri; Diagnostics Data Analysis Group Leader; 2015 AUG 15

function data = PMSensorCapData(path,varargin)
%% initializing variables
data = [];
Concatenated_Data =[];
Concatenated_truck = [];
%% Get the inputs passed via varargin argument; else set the defaults
if ~isempty(varargin)
    % code to get Truck; Software; Date Range need to get here.
else
    % setting deafault date range for data
    startdate = '2015-07-01';
    enddate = date;
    
end %  ~isempty(varargin)
%% looping through path to arrive at the target folders and mat files based
%% on the input start and end dates
Syymm = datestr(startdate,'yy-mm');
Eyymm = datestr(enddate,'yy-mm');
pathcontents = dir(path);
for i = 3:length(pathcontents) % loop through the truck folders.
    if pathcontents(i).isdir == 1
        truckname = pathcontents(i).name;
        MatFilesPath = fullfile(path,truckname,'MatData_Files');
        if exist(MatFilesPath,'dir')
            foldercontents = dir(MatFilesPath);
            for j = 3:length(foldercontents) % loop through matfiles folder within the truck
                try
                    if foldercontents(j).isdir
                        name = foldercontents(j).name;
                        if ~isempty(strfind(name,'_matfiles'))
                            nameparts = toklin(name,'_');
                            if datenum(nameparts{1})>= datenum(Syymm) && datenum(nameparts{1})<= datenum(Eyymm) % Check if folder yy-mm is within the startdate and enddate
                                %% Get Data from the respective mat file.
                                folderdata = ParseMatfile(fullfile(MatFilesPath,name),startdate,enddate,'V_PMSC_mg_PMFE_SootAllow','V_ATP_ec_PMSC_Out','J39_PM_MeasurementActive');
                                [rows col] = size(folderdata);
                                truck = repmat(truckname,rows,1);
                                Concatenated_Data = [Concatenated_Data;folderdata];
                                Concatenated_truck = strvcat(Concatenated_truck,truck);
                            end % if datenum(nameparts{1})>= datenum(Syymm) && datenum(nameparts{1})<= datenum(Eyymm)
                        end %  if ~isempty(strfind(name,'_matfiles'))
                    end % if foldercontents(j).isdir
                catch ex
                    msgstr = getReport(ex);
                    obj.error = logWriter('ErrorLog','C:\Users\ku906\Documents\CapabilityAutomation\MatFileLogs');
                    obj.error.writef('MatFileParser Error Log File - %s \r\n PATH:- %s  \r\n',truckname, fullfile(MatFilesPath,foldercontents(j).name));
                    obj.error.write(msgstr);
                end
%                 clearvars 'folderdata' 'rows' 'truck' 'Concatenated_Data'
            end % for j = 3:length(foldercontents)
        else
            disp(['No mat data available for the truck ' truckname])
        end % if exist(fullfile(path,truckname,MatData_Files),'dir')
    end % if pathcontents(i).isdir == 1
end % for i = 1:length(pathcontents)
if ~isempty(Concatenated_Data)
    data.V_PMSC_mg_PMFE_SootAllow = Concatenated_Data(:,1);
    data.V_ATP_ec_PMSC_Out = Concatenated_Data(:,2);
    data.J39_PM_MeasurementActive = Concatenated_Data(:,3);
    data.truck = Concatenated_truck;
    data.datenum = Concatenated_Data(:,4);
end