% Cal file location for test
matFile =  '..\tempcal\Acadia\Default\Default_export.mat';

% Get all the threshold names from the mat file
thNames = who('-file', matFile);

% Cell array to hold threshold values
thValues = {};

% Load all threshold names and values

load(matFile);

for i = 1:length(thNames)
    
    thValues{i} = eval(thNames{i});
    
end

% Reshape thValuess to conform to thNames
    
thValues = reshape(thValues,[length(thValues),1]);

program = 'Acadia';

% Define connection
conn = database(program,'','','com.microsoft.sqlserver.jdbc.SQLServerDriver',...
           sprintf('%s%s;%s','jdbc:sqlserver://W4-S132377;instanceName=CapabilityDev;database=',program,...
            'integratedSecurity=true;loginTimeout=5;'));
        
family = 'Acadia';


        
        
% Upload the data and engine family to the database
fastinsert(conn,'[dbo].[tblCals1]',{'Value'},{thValues});
        