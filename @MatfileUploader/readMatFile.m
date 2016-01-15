%%% parameters that are identified as Duty Cycle
%% Vehicle_Speed or Engine_Speed-- It is engine speed in mr program
%% Net_Engine_Torque
%% Idle_engine_Run_Time --- NO this parameter? is this the right name? 
%% Key_Off_Count --- NO this parameter? is this the right name? is it Key_Switch
%% Accelerator_Pedal_Position
%% Net_Engine_Torque
%%% The abover are prvoided by Lalit
%% Any other parametsrs ? shall we ask our customers
%% like ActiveFaults,Ambient_Air_Press,Boost_Pressure,Charge_Air_Cooler_Outlet_Tmptr,Coolant_Temperature
%% EGR_Position, etc, just name a few

%% time parameters that we OBD need
%%PC_Timestamp,abs_time(datenum format),ECM_Run_Time

%% faultcode summary: faultsActive,faultsActiveList,faultsActiveStr

function readMatFile(obj,matfolder,file,truckID,program)

%program = 'DragonCC';

 % Define Conn
% conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
%            sprintf('%s%s;%s','jdbc:sqlserver://W4-S129433;instanceName=CapabilityDB;database=',program,...
%             'integratedSecurity=true;loginTimeout=5;'));
 
% form the full matfile path
%matfile = char(fullfile(matfolder,file));
matfile = '\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\DragonFront\FieldTest_FDV3\T8758_BG573629_3500\MatData_Files\12-01_matfiles\T8758_BG573629_3500_FDV3_120128.mat';
% load the matfile into workspace
load(matfile);

dutyCycParams = {'TruckID','abs_time','PC_Timestamp','ECM_Run_Time',...
    'Engine_Speed','Net_Engine_Torque','Accelerator_Pedal_Position',...
    'Ambient_Air_Press','Coolant_Temperature','EGR_Position',...
    'Boost_Pressure','Charge_Air_Cooler_Outlet_Tmptr','GPS_Altitude',...
    'GPS_Latitude','GPS_Longitude','GPS_Speed'};


% Get all the parameter names from the mat file
 allParams = who('-file', matfile);
 
 %% Need to add error handling if ActiveFaults can't be found
 % Find possible active faults arrays on different screen
fIndex = strmatch('ActiveFaults',allParams); 

stabs_time_array = {};
endabs_time_array = {};
stpc_time_array = {};
endpc_time_array = {};
stecm_time_array = {};
endecm_time_array = {};
screen_array = {};
fc_array = {};

% Loop through active fault code array
for i = 1:length(fIndex)
    
    % fault code array
    fcArray = eval(char(allParams(fIndex(i))));
    
    % Get the index of fcArray if there is fault code
    % triggered
    %acfIndex = find(~ismember(fcArray,'') == 1);
    
    %% Need to add error handling if faultsActiveList does not exist
    %% what to do, maybe switch to faultsUnique or faultsActive
    % if there are faults
    %% can we use faultsUnique? when no fault code ,it is {''}--need to find an example that uses
    % faultsUnique
    if length(faultsActiveList) > 0
        
        % Loop through the fault code list
        for j = 1:length(faultsActiveList)
            
            % get the fault code number
            fcnum = faultsActiveList(j);
            
            % string concatenate to conform to the format of fault code 00: xxxx
            % in ActiveFaults array 
            if numel(num2str(fcnum)) == 4
               fc = strcat('00:',num2str(fcnum)); 
            elseif numel(num2str(fcnum)) == 3
               fc = strcat('00:0',num2str(fcnum));
            elseif numel(num2str(fcnum)) == 2
               fc = strcat('00:00',num2str(fcnum));
            elseif numel(num2str(fcnum)) == 1
               fc = strcat('00:000',num2str(fcnum)); 
            end
            
            
            % Search each fault code if exist in the
            %acfIndex = strfind(fcArray,fc);
            acfIndex = ~cellfun('isempty',strfind(fcArray,fc));
            acfIndex = find([acfIndex] == 1);
            
            % If the fc found in the current fault code array
            if length(acfIndex) > 0 
                
                % get the start and end time of abs_time
                stabs_time = abs_time(min(acfIndex));
                endabs_time = abs_time(min(acfIndex));
                % Append to abs_time_array
                stabs_time_array = [stabs_time_array,stabs_time];
                endabs_time_array = [endabs_time_array,endabs_time];
                
                % get the start and end time of PC_timestamp
                stpc_time = PC_Timestamp(min(acfIndex));
                endpc_time = PC_Timestamp(min(acfIndex));
                % Append to PC_timestamp_array
                stpc_time_array = [stpc_time_array,stpc_time];
                endpc_time_array = [endpc_time_array,endpc_time];
                
                % get the start and end time of ECM_Run_Time
                stecm_time = ECM_Run_Time(min(acfIndex));
                endecm_time = ECM_Run_Time(min(acfIndex));
                % Append to ECM_Run_Time_array
                stecm_time_array = [stecm_time_array,stecm_time];
                endecm_time_array = [endecm_time_array,endecm_time];
                
                % Get the screen
                screen = char(allParams(fIndex(i)));
                if strcmp(screen,'ActiveFaults')
                    screen = strcat(screen,'_1_Sec_Screen_1');
                end
                
                screen_array = [screen_array,screen];
                fc_array = [fc_array,fcnum];
                
            end
            
        end
       
        
    end
    
    
   
    
end

        % Cell array to hold threshold values
%         Value = cell(1,length(dutyCycParams));
        
        % Fill up value cell array
%         while item <= length(dutyCycParams) 
%             
%             %% check if the duty cycle parameter exists in matfile
%             %% if yes, then move on to grab the data
%             %% else, insert '' and write to error log
%             %index = find(cellfun('length',regexp(allParams,dutyCycParams{1})) == 1)
%            
%             index = find(ismember(allParams, dutyCycParams{item}));
%            
%             
%             if ~isempty(index) 
%                
%                 Value{item} = eval(allParams{index});
%            
%             else
%                 % create an empty value cell array
%                 Value{item} = cell(length(Value{2}),1);
%             end
%             
%             item = item +1;
% 
%         end
        
        %print('finished');
        
        % Find if fault code exists, if yes, insert into fault code table
        
        
        
        
        
         % Create calTable struct to hold table to be inserted
        matTable = struct('TruckID',{},'abs_time',{},'PC_Timestamp',{},...
            'ECM_Run_Time',{},'Engine_Speed',{},'Net_Engine_Torque',{},...
            'Accelerator_Pedal_Position',{},'Ambient_Air_Press',{},...
            'Coolant_Temperature',{},'EGR_Position',{},'Boost_Pressure',{},...
            'Charge_Air_Cooler_Outlet_Tmptr',{},'GPS_Altitude',{},...
            'GPS_Latitude',{},'GPS_Longitude',{},'GPS_Speed',{});
        
 
         %% Fill up the cell array with strings of values
        TruckID = cell(1,length(abs_time));
        TruckID(1,:) = cellstr(num2str(truckID));
        %abs_time = cell(1,length(Value{2}));
        %abs_time(1,:) = cellstr(num2str(Value{2}));
        %% PC time stamp truckID ok because cell
     
%      % Fill up the structure of matTable
        matTable(1).TruckID = TruckID';
       
        fields = fieldnames(matTable);

        for i = 2:numel(fields)
            
            index = find(ismember(allParams, dutyCycParams{i}));
            
            % if the parameter can be found and the parameter has values
            % collected
            if ~isempty(index) 
              
                if length(eval(allParams{index})) > 0 
                    
                    matTable.(fields{i}) = eval(allParams{index});
                else
                    % create a cell array of the same length as the abs_time
                    var = cell(1,length(abs_time));

                    % if the parameter is a cell, create empty string cell
                    if iscell(eval(allParams{index}))

                        var(1,:) = cellstr('');

                    % if the parameter is a double, then put some unlikely value in the cell
                    % this is not an optimal approach, for GPS coordiante, we
                    % choose -1 to be put in as GPS coordiante can't be -1
                    elseif isa(eval(allParams{index}),'double')
                        var(1,:) = num2cell(-1);
                    end

                    % transpose
                    var = var';
                    % put the cell array into struct
                    matTable.(fields{i}) = var;
                    
                end
            % if the parameter can't be found, to write an error export
            % function and specify the error message specifically which
            % parmeter is missing
            else 
                
                %% BoostPressure is missing from this matfile
                %% need to have error handling here
                print('parameter is missing from this matfile')
                
            end
        
        end
        
         % Upload the data and engine family to the database
        fastinsert(obj.conn,'[dbo].[tblMatData]',fieldnames(matTable),matTable);
        
        % Close the database connection
        close(obj.conn)
        
        % Else print cal already uploaded    
        fprintf('Mat file %s is uploaded to database matData table.\n',file,program);
      
%         matTable(1).abs_time = abs_time;
%         matTable(1).PC_Timestamp = PC_Timestamp;
%         matTable(1).ECM_Run_Time = ECM_Run_Time;
%         matTable(1).Engine_Speed = Engine_Speed;
%         matTable(1).Net_Engine_Torque = Net_Engine_Torque;
%         matTable(1).Accelerator_Pedal_Position = Accelerator_Pedal_Position;
%         matTable(1).Ambient_Air_Press = Ambient_Air_Press;
%         matTable(1).Coolant_Temperature = Coolant_Temperature;
%         matTable(1).Net_Engine_Torque = Net_Engine_Torque;
%         matTable(1).EGR_Position = EGR_Position;
%         matTable(1).Boost_Pressure = Boost_Pressure;
%         matTable(1).Charge_Air_Cooler_Outlet_Tmptr = Charge_Air_Cooler_Outlet_Tmptr;
%         matTable(1).GPS_Longitude = GPS_Longitude;
%         matTable(1).GPS_Latitude = GPS_Latitude;
%         matTable(1).GPS_Speed = GPS_Speed;
% 
%         
end