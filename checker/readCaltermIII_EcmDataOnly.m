function readCaltermIII_EcmDataOnly(filename)
% 
% readCaltermIII_EcmDataOnly
%
% Reads Calterm III log files with only one data input
%
% Outputs parameters with data, timestamp, abs_time, tod,
% and a list of channel names
% 
% Converts HEX values to decimal
%
%    Based on the following log file structure:
%
%         - The file start time in the header being on its own line
%              and ending in AM or PM
%         - 'Parameter Name' being in the first column of parameter names
%         - The first column next to the data block is empty
%         - One data source -- a continuous block of data in a single format
%         - Filename includes full path
%
%
%    11/07/11  Chris Remington
%    Several things hacked in (all commented with my name) to get this to
%    read Min/Max and Event Driven data from a raw CSV.
%    - Monkey with blank time-stamp values
%    - STOP converting NaN values to 9999
%    - Chang initial read to 100 lines from only 60 lines (align w/ newer
%      versions of this script)
%    - Discovered incompatibility when Calterm decided to write the time on
%      the second line in 24-hour format, bug not fixed
%    
%    6/26/07  Dan Denison
%    CTIII header was modified -- adapted by looking for dashes
%    2/1/06   Dan Denison
%    Error handling for when CTIII drops ECM data -- timestamp & all
%    1/3/06   Dan Denison
%    CTIII switch from timestamp to DLA_Timestamp
%    1/2/06   Dan Denison
%    Updated HEX conversion to handle 8-bit values
%    Replace [ and ] in ParameterNames with _
%    9/7/05   Dan Denison
%    Added Units and HEX to decimal conversion
%    7/27/05   Dan Denison
%    Added Timestamp, abs_time, & tod
%    7/26/05   Dan Denison
%    Version 1

%%
% REMINGTON - Temp so I don't have to pass in the file name every time I run this.
%[fname,pathname] = uigetfile('*.csv','Select Calterm III Log File');
%filename = fullfile(pathname, fname);

%%
NUMBEROFHEADERLINES = 0;
PARAMETERNAMELINE = 0;
FIRSTLINEOFDATA = 0;
UNITSLINE = 0;
HEADERPARAMETERS = 0;
HEADERPARAMETERSBEGIN = 0;
FindBearings = 1;
findBearingsFlag = 0;
readFailed = 0;
findThemDashes = 0;
%caller???
if ~(exist('headerChannelNames'))
     headerChannelNames = [];
end

disp(['Reading [' filename '] ...']);

% Grab the header and some sample data
fid = fopen(filename);
% REMINGTON change - read in 100 lines instead of only 60 lines
SampleBlock = textscan(fid,'%s',400,'delimiter','\r','whitespace','\b\n\t','bufsize',6000);
fclose(fid);

% Find landmarks in the header to set hooks for constants
try
     while findBearingsFlag == 0
          HeaderLine = SampleBlock{1,1}(FindBearings,1);
          % REMINGTON - This fails if Calterm decides to write the time in
          % 24 hour format, i.e. - 11/8/2011 19:23
          % This happened once, not sure why but it did.
          if (strcmp(HeaderLine{1,1}(1,end-2:end), ' PM')) || (strcmp(HeaderLine{1,1}(1,end-2:end), ' AM'))
               FileStart = HeaderLine{1,1}(1,1:end);
               FileStartNum = datenum(FileStart);
          end
          if (strcmp(HeaderLine{1,1}(1,1:2), '00'))
               if (HEADERPARAMETERS == 0)
                    HEADERPARAMETERSBEGIN = FindBearings;
               end
               HEADERPARAMETERS = HEADERPARAMETERS + 1;
          end
          if (strcmp(HeaderLine{1,1}(1,1:10), 'Parameter '))
               PARAMETERNAMELINE = FindBearings;
          end
          if (strcmp(HeaderLine{1,1}(1,1:5), 'Units'))
               UNITSLINE = FindBearings;
          end
          if (strcmp(HeaderLine{1,1}(1,1:6), '------'))
               findThemDashes = 1; 
          end
          if (findThemDashes == 1)
              if (strcmp(HeaderLine{1,1}(1,1:1), ','))
                   FIRSTLINEOFDATA = FindBearings;
                   NUMBEROFHEADERLINES = FindBearings-1;
                   findBearingsFlag = 1;
              end
          end
          FindBearings = FindBearings + 1;
     end
catch
     disp('*** READ FAILED ~ No Data in File ***')
     readFailed = 1;
     assignin('caller','readFailed',readFailed);
     return
end

if ((PARAMETERNAMELINE == 0) || (UNITSLINE == 0))
     disp('*** READ FAILED ~ Parameter Names or Units not found ***')
     readFailed = 1;
     assignin('caller','readFailed',readFailed);
     return
end

if (HEADERPARAMETERS > 0)
    counter = 1;
    for getHeaderParameters = HEADERPARAMETERSBEGIN:(HEADERPARAMETERSBEGIN + HEADERPARAMETERS-1)
          HeaderLine = char(SampleBlock{1,1}(getHeaderParameters,1));
          leftBracket = (HeaderLine == 91);
          HeaderLine(leftBracket) = '_';
          rightBracket = (HeaderLine == 93);
          HeaderLine(rightBracket) = '_';
          headerParameterLine = toklin(HeaderLine,',');
          if(length(headerParameterLine{1,3}) == 0)
               continue
          end
          headerChannelNames{counter,1} = headerParameterLine{1,2};
          if (strcmp(headerChannelNames{counter,1}(1:1), '_'))
               headerChannelNames{counter,1} = ['i', headerChannelNames{counter,1}];
          end
          if (strcmp(headerChannelNames{counter,1}(1:2), '0e'))
               headerChannelNames{counter,1} = ['hex_', headerChannelNames{counter,1}];
          end
          findNumericHPV = str2num(headerParameterLine{1,3});
          if (isempty(findNumericHPV))
               headerParameterValue = cellstr(headerParameterLine{1,3});
          else
               headerParameterValue = findNumericHPV;
          end
          try
               eval([headerChannelNames{counter} ' = headerParameterValue;']);
          catch
               disp('*** READ FAILED ~ Error in Header Parameter Value ***')
               readFailed = 1;
               assignin('caller','readFailed',readFailed);
               return
          end
          assignin('caller',headerChannelNames{counter}, headerParameterValue);
          counter = counter + 1;
     end
end
% REMINGTON change - comment out this entire section to keep data even when
% there are no header parameters written to the csv file
% if (HEADERPARAMETERS > 0) && (HEADERPARAMETERS >= counter+3)
% % if (HEADERPARAMETERS > 0) && (HEADERPARAMETERS >= counter+1)
%      disp('*** READ FAILED ~ No Header Parameter Values ***')
%      readFailed = 1;
%      assignin('caller','readFailed',readFailed);
%      return
% end
     
% Find the total number of lines of data

DimBlock = textread(filename,'%s','delimiter','\r','whitespace','\b\n\t','bufsize',15000);
NumbRows = length(DimBlock) - NUMBEROFHEADERLINES;
clear DimBlock

% Finds spaces in parameter names and replaces them with an underscore
ParameterNames = char(SampleBlock{1,1}(PARAMETERNAMELINE,1));
UnitNames = char(SampleBlock{1,1}(UNITSLINE,1));
MakeUnderscore = (ParameterNames == 32);
ParameterNames(MakeUnderscore) = '_';
leftBracket = (ParameterNames == 91);
ParameterNames(leftBracket) = '_';
rightBracket = (ParameterNames == 93);
ParameterNames(rightBracket) = '_';
minusSign = (ParameterNames == 45);
ParameterNames(minusSign) = '_';
equalsSign = (ParameterNames == 61);
ParameterNames(equalsSign) = '_';
period = (ParameterNames == 46);
ParameterNames(period) = '_';

% Creates list of Channel names
channelNames = toklin(ParameterNames,',');
channelNames = channelNames';
Units = toklin(UnitNames,',');
NumbChannels = length(channelNames);
for i = 1:NumbChannels
   if isempty(channelNames{i})
      channelNames{i} = ['x' num2str(i)];
   end
   if (strcmp(channelNames{i}(1:1), '_'))
      channelNames{i} = ['i', channelNames{i}];
   end
   if (strcmp(channelNames{i}(1:1), '0'))
      channelNames{i} = ['addr_', channelNames{i}];
   end
end

% Create a string of data formats based on the first line of data
FirstLine = char(SampleBlock{1,1}(FIRSTLINEOFDATA,1));
FindFormat = toklin(FirstLine,',');
FindStrings = isnan(str2double(FindFormat));
ChannelNameList = [];
DataFormat = [];
DataFormat = ['%*s '];   % ignore the empty Parameter Name field

for i = 2:NumbChannels
   ChannelNameList = [ChannelNameList channelNames{i} ','];
%    if FindStrings(i) | (strcmp(Units{1, i}, 'HEX')) | (strcmp(Units{1, i}, 'none'))
   if (strcmp(Units{1, i}, 'HEX')) || (strcmp(Units{1, i}, 'none'))
      DataFormat = [DataFormat '%s '];
   elseif (strcmp(Units{1, i}, 'UNITLESS')) && FindStrings(i)
      DataFormat = [DataFormat '%s '];
   elseif (strcmp(Units{1, i}, '')) && FindStrings(i)
      DataFormat = [DataFormat '%s '];   
   else
      DataFormat = [DataFormat '%f '];
   end
end
ChannelNameList = ['[' ChannelNameList(1:end-1) ']'];
 %'treatAsEmpty', 'Infinity',
% Read in the data
try
    fid = fopen(filename);
    BlockOfData = textscan(fid, DataFormat, NumbRows, 'delimiter',',', 'treatAsEmpty', 'Infinity', 'headerlines', NUMBEROFHEADERLINES);
    fclose(fid);
catch
    NumbRows = NumbRows-1;
    fid = fopen(filename);
    BlockOfData = textscan(fid, DataFormat, NumbRows, 'delimiter',',', 'treatAsEmpty', 'Infinity', 'headerlines', NUMBEROFHEADERLINES);
    fclose(fid);
end

firstOne = length(BlockOfData{1,1});
lastOne = length(BlockOfData{1,NumbChannels-1});
checkRows = min(firstOne, lastOne);
if (checkRows < NumbRows)
    NumbRows = checkRows;
end

% Assign data to Channel names and save them to the workspace
% try
    
for i = 2:NumbChannels     
     %  Identify Channels with HEX values and convert them to decimal
     thisIsAcell = 0;
     %DealWithCells = []; %REMINGTON Edit, comment out line, un-needed
     if (iscell(BlockOfData{1,i-1}))
          thisIsAcell = 1;
          if ~(strcmp(Units{1, i}, 'HEX'))
               DealWithCells = cell(NumbRows, 1);
          else %REMINGTON edit ZF - originally an end, I added else clause
              DealWithCells = cell(NumbRows, 1);
          end
     else
          DealWithCells = zeros(NumbRows, 1);
     end
     for v = 1:NumbRows
     %     disp(v)
          if (thisIsAcell == 1)
               if strcmp(Units{1, i}, 'HEX')
     %               if (strcmp(BlockOfData{1,i-1}{v,1}, 'NaN')) || (isempty(BlockOfData{1,i-1}{v,1}))
                     if (strcmp(BlockOfData{1,i-1}{v,1}(1:3), 'NaN')) || (isempty(BlockOfData{1,i-1}{v,1}))
                         %REMINGTON CHANGE - originally 9999
                         BlockOfData{1,i-1}{v,1} = 'NaN';
%                        BlockOfData{1,i-1}{v,1} = 9999;
                    end
                    try
                        % REMINGTON edit ZF = stop converting Hex to dec, leave 
                        % hex as is (but continue to trim the spaces out)
                        DealWithCells{v,1} = BlockOfData{1,i-1}{v,1}([1 2 4 5 7 8 10 11]);
%                       DealWithCells(v,1) = hex2dec(BlockOfData{1,i-1}{v,1}([1 2 4 5 7 8 10 11]));
%                       DealWithCells(v,1) = hex2dec(BlockOfData{1,i-1}{v,1});
                    catch
                        %REMINGTON CHANGE - originally 9999
                        %REMINGTON edit ZF, change to cell array
                        DealWithCells{v,1} = 'NaN';
%                       DealWithCells(v,1) = NaN;
%                       DealWithCells(v,1) = 9999;
                    end
%                     findZero = length(BlockOfData{1,i-1}{v,1});
%                     if findZero == 4
%                          DealWithCells(v,1) = hex2dec(BlockOfData{1,i-1}{v,1}(1,3:4));
%                     elseif findZero == 2
%                          DealWithCells(v,1) = 0;
%                     end
               else
                   DealWithCells{v,1} = char(BlockOfData{1,i-1}{v,1});
               end
          else
               DealWithCells(v) = BlockOfData{1,i-1}(v,1);
          end
     end
     
     % REMINGTON Change - completly redo the mess that was going on here
     % Acconut for MinMax and Event Driven data long names, change them
     % here so they aren't so long
     if strcmp(channelNames{i}, 'MinMax_PropB_Msg_MinMax_PropB_Msg_datavalue')
         % Set 'MinMax_PropB_Msg_MinMax_PropB_Msg_datavalue' to 'MinMax_Data'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller', 'MinMax_Data', DealWithCells);
         channelNames{i} = 'MinMax_Data';
         
     elseif strcmp(channelNames{i}, 'MinMax_PropB_Msg_MinMax_PropB_Msg_ParameterID')
         % Set 'MinMax_PropB_Msg_MinMax_PropB_Msg_ParameterID' to 'MinMax_PublicDataID'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller', 'MinMax_PublicDataID', DealWithCells);
         channelNames{i} = 'MinMax_PublicDataID';
         
     elseif strcmp(channelNames{i}, 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_ID')
         % Set 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_ID' to 'EventDriven_xSEID'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller','EventDriven_xSEID', DealWithCells);
         channelNames{i} = 'EventDriven_xSEID';
         
     elseif strcmp(channelNames{i}, 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_Data')
         % Set 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_Data' to 'EventDriven_Data'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller','EventDriven_Data', DealWithCells);
         channelNames{i} = 'EventDriven_Data';
         
     % These are the old versions of the .cbf file, automatically switch
     % the variable names to the correct values
     elseif strcmp(channelNames{i}, 'Even_Driven_PropB_Msg_Event_Driven_Diagnostic_ID')
         % Set 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_ID' to 'EventDriven_xSEID'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller','EventDriven_Data', DealWithCells);
         channelNames{i} = 'EventDriven_Data';
     
     elseif strcmp(channelNames{i}, 'Even_Driven_PropB_Msg_Event_Driven_Diagnostic_Data')
         % Set 'Event_Driven_PropB_Msg_Event_Driven_Diagnostic_Data' to 'EventDriven_Data'
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller','EventDriven_xSEID', DealWithCells);
         channelNames{i} = 'EventDriven_xSEID';
         
     else % This is a nornal parameter name, just do it the normal way
         eval([channelNames{i} ' = DealWithCells;']);
         assignin('caller',channelNames{i}, DealWithCells);
     end
    
     % disp(channelNames{i})
end

% catch
%      disp('*** READ FAILED ~ Data File Corrupt ***')
%      readFailed = 1;
%      assignin('caller','readFailed',readFailed);
%      return
% end


% Calculate absolute time -- 
% datenum time value that includes the date and time
if exist('timestamp')
     timeStamp_File = timestamp;
end
if exist('DLA_Timestamp')
     timeStamp_File = DLA_Timestamp;
end
if exist('PC_Timestamp')
     timeStamp_File = PC_Timestamp;
end

try
    % REMINGTON Modificaton, quick and dirty fix to deal with the last line
    % of the file being empty
    % Loop through, looking for blanks. Set blanks to the previous value.
    % Start at 2 b/c this relies on a valid time being in the first row
    for i = 2:length(timeStamp_File)
        if strcmp(timeStamp_File{i}, '')
            timeStamp_File(i) = timeStamp_File(i-1);
        end
    end
    % original code follows:
    DateAndTime = datenum(timeStamp_File);
catch
     disp('*** READ FAILED ~ No Timestamp ***')
     readFailed = 1;
     assignin('caller','readFailed',readFailed);
     return
end

% REMINGTON modification, add try/catch statement to notify on 24 hr time
% format glitch
try
    [y, m, d] = datevec(FileStartNum);
catch
    disp('Second line is in a 24 hour data format, fix that in the file.')
    readFailed = 1;
    assignin('caller','readFailed',readFailed);
    return
end
FirstDateValue = datenum(y, m, d);
[y, m, d] = datevec(DateAndTime);
DateValue = datenum(y, m, d);
TimeValue = DateAndTime - DateValue;
abs_time = FirstDateValue + TimeValue;

% Calculate time of day --
% number of seconds since midnight
[y, m, d] = datevec(abs_time);
absDateValue = datenum(y, m, d);
abs_timeValue = abs_time - absDateValue;
tod = abs_timeValue * 86400;

if (HEADERPARAMETERS > 0) && (counter > 1)
     % Add the parameters found in the header to the list of channels
     abs_time_Header = abs_time(1);
     tod_Header = tod(1);
     headerChannelNames = [headerChannelNames; {'abs_time_Header'}];
     headerChannelNames = [headerChannelNames; {'tod_Header'}];
     %channelNames = [channelNames; headerChannelNames];
     assignin('caller','abs_time_Header',abs_time_Header);
     assignin('caller','tod_Header',tod_Header);
end

% Save variables to the workspace
channelNames(1) = [];    % delete Parameter Name from the list -- it ain't a channel
assignin('caller','abs_time',abs_time);
assignin('caller','tod',tod);
assignin('caller','channelNames',channelNames);
assignin('caller','headerChannelNames',headerChannelNames);
assignin('caller','FileStartNum',FileStartNum);
assignin('caller','filename',filename);
assignin('caller','readFailed',readFailed);
