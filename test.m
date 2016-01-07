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

%% faultcode summary: faultsActive,faultsUnique

function test(matfolder,file)


 % Define Conn
% conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
%            sprintf('%s%s;%s','jdbc:sqlserver://W4-S129433;instanceName=CapabilityDB;database=',program,...
%             'integratedSecurity=true;loginTimeout=5;'));
 
% form the full matfile path
matfile = char(fullfile(matfolder,file));

% load the matfile into workspace
load(matfile);

dutyCycParams = {'abs_time','PC_Timestamp','ECM_Run_Time','ActiveFaults','Engine_Speed','Net_Engine_Torque','Accelerator_Pedal_Position'};

% Get all the parameter names from the mat file
        allParams = who('-file', matfile);

        % Cell array to hold threshold values
        Value = cell(1,length(dutyCycParams));

        % Fill up value cell array
        for i = 1:length(dutyCycParams)
            
            %% check if the duty cycle parameter exists in matfile
            %% if yes, then move on to grab the data
            %% else, insert '' and write to error log
            %index = find(cellfun('length',regexp(allParams,dutyCycParams{1})) == 1)
            index = find(ismember(allParams, dutyCycParams{i}));
            
            if ~isempty(index) 
               
                Value{i} = eval(allParams{index});
           
            else
                % create an empty value cell array
                Value{i} = cell(length(Value{1}),1);
            end

        end
        
         % Create calTable struct to hold table to be inserted
        %calTable = struct('Family',{},'CalVersion',{},'CalRev',{},'Threshold',{},'Value',{});
        % needs to add the truckname
        %matTable = struct('TruckID',{},'abs_time',{},'PC_Timestamp',{},'ECM_Run_Time',{},'ActiveFaults',{},'Engine_Speed',{},'Net_Engine_Torque',{},'Accelerator_Pedal_Position',{});
        
%         % Fill up the structure of Caltable
%         calTable(1).Threshold = Threshold;
%         calTable(1).Value = Value;
%         calTable(1).Family = Family;
%         calTable(1).CalVersion = CalVersion;
%         calTable(1).CalRev = CalRev;
% 
%         % Upload the data and engine family to the database
%         fastinsert(conn,'[dbo].[tblCals1]',fields(calTable),calTable);
%         
%         % Close the database connection
%         close(conn)
%     
%         % Else print cal already uploaded    
%         fprintf('Cal Version %s and Revision %s is uploaded to database cal table in Family %s of program %s.\n',calVersion,calRev, family,program);
end