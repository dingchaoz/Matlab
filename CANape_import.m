function data_Array = CANape_import(filename, startRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [TS,KEY_SWITCHNONE,ECM_RUN_TIME_200MSS,SYSTIME,EVENTDRIVENDATAVALUE,EXTID,SYSTEMERRORID,MINMAX_DATAVALUE,PUBLICDATAID,MMM_UPDATE_RATEMSEC]
%   = IMPORTFILE(FILENAME) Reads data from text file FILENAME for the
%   default selection.
%
%   [TS,KEY_SWITCHNONE,ECM_RUN_TIME_200MSS,SYSTIME,EVENTDRIVENDATAVALUE,EXTID,SYSTEMERRORID,MINMAX_DATAVALUE,PUBLICDATAID,MMM_UPDATE_RATEMSEC]
%   = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [ts,Key_SwitchNone,ECM_Run_Time_200mss,systime,EventDrivenDataValue,ExtID,SystemErrorID,MinMax_DataValue,PublicDataID,MMM_Update_RatemSec]
%   = importfile('T166_MinMax_Data_2014_11_25_14_54_32.csv',3, 2972);
%
%    See also TEXTSCAN.

% Dingchao Zhang on 2014/12/08 16:03:22

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 3;
end

%% Format string for each line of text:
%   column1: double (%f)
%	column2: text (%s)
%   column3: double (%f)
%	column4: text (%s)
%   column5: text (%s)
%	column6: text (%s)
%   column7: text (%s)
%	column8: text (%s)
%   column9: text (%s)
%	column10: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%s%f%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
% dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
% for block=2:length(startRow)
%     frewind(fileID);
%     dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
%     for col=1:length(dataArray)
%         dataArray{col} = [dataArray{col};dataArrayBlock{col}];
%     end
% end

dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
data_Array = dataArray;
%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
% ts = data_Array{:, 1};
% Key_SwitchNone = data_Array{:, 2};
% ECM_Run_Time_200mss = data_Array{:, 3};
% systime = data_Array{:, 4};
% EventDrivenDataValue = data_Array{:, 5};
% ExtID = data_Array{:, 6};
% SystemErrorID = data_Array{:, 7};
% MinMax_DataValue = data_Array{:, 8};
% PublicDataID = data_Array{:, 9};
% MMM_Update_Rate = data_Array{:, 10};

%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;