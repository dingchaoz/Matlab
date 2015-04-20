%This is a development to parse the multi tab FaultCodeCumulativehistory
%spreadsheet into databse

% Initiate excel application
% exl = actxserver('excel.application');
% exlWkbk = exl.Workbooks;
% 
% % Initiate excel object exlFile
% exlFile = exlWkbk.Open(['C:\Users\ks692\Documents\MATLAB\CapabilityGUI\FaultCodeHistoryscripts\Dragnet_DragonFront_CumulativeFaultCodeHistory.xlsx']);

% numFiles = 5;
% range = 'A2:R20';
% sheet = 1;
% myData = cell(1,numFiles);
filename = 'C:\Users\ks692\Documents\MATLAB\CapabilityGUI\FaultCodeHistoryscripts\Dragnet_DragonFront_CumulativeFaultCodeHistory.xlsx';
[type,sheetname] = xlsfinfo(filename);
m=size(sheetname,2); 
alldata =cell(1, m);

% for sheet = 1:numFiles
%     
%     myData{sheet} = AddFC2vector(fileName,sheet,range);
% end