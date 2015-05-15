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
%ActiveErrorIndex = {};
% InactiveFaults = {};
% MILStatus = {};
% InactiveErrorIndex = {};
% FilenamewhereFaultFirstOccurred = {};
ECMRunTimes = [];
TimeFaultFirstOccurred = [];
% MilestheFCwasactive = [];
HourstheFCwasactive = [];
% TotalMilesthatday = [];
% TotalHoursthatday = [];
% Odometerkmwhenfaultisset = [];
% VehicleSpeedattimeofFaultmph = [];

% FCCumulativehistory workbook
wkbk = 'C:\Users\ks692\Documents\MATLAB\CapabilityGUI\FaultCodeUploader\Dragnet_DragonFront_CumulativeFaultCodeHistory.xlsx'
% Read the workbook's info
[type,sheetname] = xlsfinfo(wkbk);

% Get the number of spreasheets in the workbook
m=size(sheetname,2); 

% Initiate an array to hold new data
newdata = {};
%% Import the data
for sheet = 1 : m
    % [~, ~, raw] = xlsread(wkbk,sheet,'A2:R15');
    table = readtable(wkbk,'Sheet',sheetname{sheet});
     % table to cell table2cell
    % table to array table2array
    % vertically combine several cell arrays c = [c1;c2;c3...]
    
    newdata = [newdata;table];
   
end


%Remove not needed column
newdata(:,[1,7,13,14,17]) = [];

%Insert numDate, abs_time columns
newdata.numDate = datenum(newdata.Date);
% newdata.numTimeFCActive = datenum(newdata.TimeFaultFirstOccurred);

% Get the y,m,d of numtimeFCActive
% [y,m,d]=datevec(newdata.numTimeFCActive);
%Create array named DataValue = datenum(y,m,d)
% DataValue = datenum(y,m,d);
%Create array named TimeValue
% TimeValue = newdata.TimeFaultFirstOccurred - DateValue;
% Calculate the abs_time of the fault code occured
newdata.abs_time = newdata.numDate + newdata.TimeFaultFirstOccurred;

% remove column 5
newdata(:,[5]) = [];

% Create TruckID , set default to 0 which will be updated via SQL trigger
newdata.TruckID = zeros(size(newdata.abs_time));

% Fast insert the records to db, one option is to not to import truckID
% data since we don't know it 
% need to figure out how to get obj.conn
 cols = {'Truckname','CalVersion','Date','ActiveFaultCode',...
     'ECMRunTime','MilestheFCwasactive','HourstheFCwasactive','TotalMilesthatday'...
     'TotalHoursthatday','Odometer','Filename','VehicleSpeed','numDate','abs_time','TruckID'
     };
 % initiate a new column Cal to hold double type of cal
 newdata.Cal = zeros(size(newdata.abs_time));

for i= 1:length(newdata{:,2})
    % remove dot 
    newdata{i,2} = strrep(newdata{i,2},'.','');
    
    % push double type cal into Cal column
    newdata.Cal(i) = str2num(char(newdata{i,2}));
    
    % remove FC_ chars
    newdata{i,4} = strrep(newdata{i,4},'FC_','');
%     newdata{i,4} = char(newdata{i,4});
    %newdata{i,2} = str2num(char(newdata{i,2}));
    
    
    %To do change ECMRunTimes,numDate,abs_time to char type to match sql
%      newdata.runt = num2str(newdata{:,5});
%      newdata.numd = num2str(newdata{:,13});
%      newdata.abst = num2str(newdata{:,14});
     
     
end

% make truckname type to char to match sql
newdata.tr = char(newdata{:,1});

% make date type to char to match sql
newdata.dat = char(newdata{:,3});

% make faultcode type to char to match sql
newdata.fc = char(newdata{:,4});

% make filename type to char to match sql
newdata.fi = char(newdata{:,11});

 newdata.numd = num2str(newdata{:,13});
     
 newdata.abst = num2str(newdata{:,14});
    
% swap column Calversion and column Cal
i = 2;
j = 16;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

% swap column tr and column TruckName
i = 1;
j = 17;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

% swap column dat and column Date
i = 3;
j = 18;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

% swap column fc and column faultcode
i = 4;
j = 19;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

% swap column file and column filename
i = 11;
j = 20;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

i = 13;
j = 21;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);

i = 14;
j = 22;
newdata = newdata(:,[1:i-1,j,i+1:j-1,i,j+1:end]);


% remove column Calversion
newdata(:,[16,17,18,19,20,21,22]) = [];

% change column 2 name from Cal to CalVER
 newdata.Properties.VariableNames{'Cal'} = 'CalVersion';
 newdata.Properties.VariableNames{'fc'} = 'ActiveFaultCode';
 newdata.Properties.VariableNames{'tr'} = 'Truckname';
 newdata.Properties.VariableNames{'dat'} = 'Date';
 newdata.Properties.VariableNames{'fi'} = 'Filename';
 newdata.Properties.VariableNames{'ECMRunTime_s_'} = 'ECMRunTime';
 newdata.Properties.VariableNames{'VehicleSpeedAtTimeOfFault_mph_'} = 'VehicleSpeed';
 newdata.Properties.VariableNames{'Odometer_km_WhenFaultIsSet'} = 'Odometer';
 newdata.Properties.VariableNames{'TotalMilesThatDay'} = 'TotalMilesthatday';
 newdata.Properties.VariableNames{'TotalHoursThatDay'} = 'TotalHoursthatday';
 newdata.Properties.VariableNames{'MilesTheFCWasActive'} = 'MilestheFCwasactive';
 newdata.Properties.VariableNames{'HoursTheFCWasActive'} = 'HourstheFCwasactive';
 newdata.Properties.VariableNames{'numd'} = 'numDate';
 newdata.Properties.VariableNames{'abst'} = 'abs_time';
 
 % change cal version type from double to int
 newdata{:,2} = int16(newdata{:,2});
 
 % change truckID type from double to int
 newdata{:,15} = int16(newdata{:,15});
 
%  newdata.Properties.VariableNames{'runt'} = 'ECMRunTime_s_s';

try
    % Open the database connection
    conn = database('DragonCC','','', ...
        'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
        sprintf('%s%s%s%s%s%s', ...
        'jdbc:sqlserver://','W4-S129433',';instanceName=','CAPABILITYDB', ...
        ';database=','DragonCC', ...
        ';integratedSecurity=true;'));
%      obj.conn = database(in,'','', ...
%         'com.microsoft.sqlserver.jdbc.SQLServerDriver', ...
%         sprintf('%s%s%s%s%s%s', ...
%         'jdbc:sqlserver://',obj.server,';instanceName=',obj.instanceName, ...
%         ';database=',in, ...
%         ';integratedSecurity=true;'));
    % Assign the name to the property field
%     obj.privateProgram = in;
    % Display a message on the workspace
    %fprintf('Successfully connected to the %s database.\n',in)
catch ex

    % If a connection couldn't be made
    if strcmp('database:database:connectionFailure',ex.identifier) || ...
            (strcmp('database:database:cursorError',ex.identifier) &&...
             any(strfind(ex.message,'The SELECT permission was denied')))

        % If it was becase of a bad database name specified
        if strncmp('Cannot open database',ex.message,20) || any(strfind(ex.message,'The SELECT permission was denied')) || strncmp('Login failed for user',ex.message,21)
            % Throw an error that an invalid program name was specified
            error('Capability:InvalidProgram','Couldn''t connect to the %s program database. The database wasn''t found or you don''t have permission to access the data.',in)
        elseif strncmp('The TCP/IP connection to the host',ex.message,33)
            % Throw an error that the TCP/IP connection cound't be made
            error('Capability:UnableToConnect','Couldn''t connect to the specified program of %s',in)
        else
            % Rethrow the original error
            rethrow(ex)
        end

    elseif strcmp('database:database:cursorError',ex.identifier)

    else % unknown error
        % Rethrow the original error
        rethrow(ex)
    end
end

%Insert data to FC table
%Error using database/fastinsert (line 90)
% Variable fields and insert fields do not match
% Need to match type, Cal, Fault Code, ECM time
 fastinsert(conn, '[dbo].[FC]',cols,newdata);