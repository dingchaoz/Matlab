function CompareCapToMat
% Compare capability data to .mat files present on the network
    
    % Right now this is set for Dragnet_X and Field Test data only
    
    % Spreadsheet name
    outputFile = sprintf('CompareCapToMat_%s.xlsb',datestr(now,'yymmdd_HHMMSS'));
    
    % Use for database connection
    db = Capability('HDPacific');
    
    % Select the distinct trucks and days of data present for SEID 3796 as this
    % runs almost all the time and will increase the speed of the query
    sql = ['SELECT [TruckName],[datenum] FROM ',...
           '(SELECT DISTINCT [TruckID],FLOOR([datenum]) As datenum ',...
           'FROM [dbo].[tblEventDrivenData] WHERE [SEID] = 3796) As A ',...
           'LEFT OUTER JOIN [dbo].[tblTrucks] On [tblTrucks].[TruckID] = A.[TruckID] ',...
           '/*WHERE [TruckType] = ''Dragnet'' Or [TruckType] = ''Field Test''*/ ',...
           'ORDER BY [TruckName],[datenum]'];
    
    % Get the data
    dataS = fetch(db.conn, sql);
    % Format structure into cell array
    data = cell(length(dataS.TruckName),6);
    data(:,1) = dataS.TruckName;
    data(:,2) = cellstr(datestr(dataS.datenum,23));
    data(:,3) = num2cell(dataS.datenum);
    data(:,4) = cellstr(datestr(dataS.datenum,'yymmdd'));
    data(:,5) = strcat(data(:,1),'_ALA_',data(:,4),'.mat'); % Mat File Name
    
    % Pull out the listing from the network
    data2 = findETDFiles('\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\Pacific\MatData');
    
    % For each MinMax truck-day of data
    for i = 1:size(data,1)
        % Check for a .mat file present
        data{i,6} = any(strcmp(data{i,5},data2(:,5)));
    end
    
    % For each .mat file found
    for i = 1:size(data2,1)
        % Check for MinMax data present
        data2{i,6} = any(strcmp(data2{i,5},data(:,5)));
    end
    
    % Add headers
    data = [{'Truck','Date','Datenum','YYMMDD','Mat File Name Would Be','Mat File Exists?'};data];
    data2 = [{'Truck','Date','Datenum','YYMMDD','Mat File Name','MinMax Exists?'};data2];
    
    % Write the raw results for each to an excel spreadsheet
    xlswrite(outputFile,data,'MinMax_TruckDays')
    xlswrite(outputFile,data2,'MatFiles_TruckDays')
    
    % Push the raw results back out to the workspace
    assignin('base','dataS',dataS)
    assignin('base','data',data)
    assignin('base','data2',data2)
end

function output = findETDFiles(rootDir)
%Blah Blah Blah
    % Initalize output cell array
    output = {};
    % Look for trucks
    trucks = dir(rootDir);
    % For each truck folder
    for i = 3:length(trucks)
        % Pull out truck name
        truck = trucks(i).name;
        % Only do dragnet and field test for now
        %if (strncmp('QV_',truck,3) && ~strcmp('QV_Navistar_9224_9564',truck) && ~strcmp('QV_Freymiller_0215_9813',truck)) || strncmp('F_',truck,2)
            % Check for cumulative folder to make sure this is a truck folder
            if ~exist(fullfile(rootDir,truck,'cumulative_matfiles'),'dir')
                % Skip
                fprintf('Skipping %s\r',truck)
                continue
            end
            fprintf('Working on %s\r',truck)
            % Get month folders
            mnths = dir(fullfile(rootDir,truck,'*_matfiles'));
            % For each month folder
            for j = 1:length(mnths)
                % Get the file name
                files = dir(fullfile(rootDir,truck,mnths(j).name,'*.mat'));
                for k = 1:length(files);
                    % Screen for files that end in _5000ms, _1000ms, etc.
                    if  strcmp('ms.mat',files(k).name(end-5:end))
                        disp(['Skipping ' files(k).name])
                        % Skip looking at them
                        continue
                    end
                    
                    try
                        % Calculate datenum
                        fileDatenum = datenum(files(k).name([end-9:end-4]),'yymmdd');
                        % Appeand the datenum and truck name to the output
                        output = [output;{truck,datestr(fileDatenum,23),fileDatenum,files(k).name(end-9:end-4),files(k).name,[]}];
                    catch ex
                        % Use this output for debugging
                        disp(truck)
                        disp(files(k).name)
                        disp(ex.getReport)
                    end
                end
            end
        %end
    end
end
