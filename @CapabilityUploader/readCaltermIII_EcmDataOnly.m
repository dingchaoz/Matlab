function readCaltermIII_EcmDataOnly(obj, filename)
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
%    04/07/2014  Chris Remington
%    - Account for if the header parameters are preceeded by 0, instead of 00,
%    - Account for if there is a blank entry in the header parameters (',,' line in .csv file)
%    
%    07/12/2013  Chris Remington
%    - Read in 400 lines for header because Atlantic has an obscenely long header list
%    
%    05/24/2013  Chris Remington
%    - Added functionality to capture CaltermVersion, ScreenMonitorType, 
%        Log Mode, and Initial Monitor Rate from the log file so these can be
%        monitored more easily
%    
%    11/15/12  Chris Remington
%    - Hacked the error section for header parameters so this won't hard fail
%        on some log files from Calterm 3.6.1.002 Garnet where the header 
%        parameters are doubled and this script would error out
%    - Hacked the main data reading line in a wried way to limp this along and 
%        get the existing code to read the data properly
%    
%    01/31/12  Chris Remington
%    - When a log file is recorded when crossing midnight UTC, this script
%        messes up the timestamp, need to fix that
%    
%    01/25/12  Chirs Remington
%    - Half of this function's time is spend on this line:
%      - DateAndTime = datenum(timeStamp_File);
%        * The problem is that it internally calls str2double for each of
%        the hours, minutes, and seconds on each line. If sscanf is used
%        properly, sscanf works about 5 times faster, reducing the time of
%        this script from about 2.5 seconds to around 1.5 seconds.
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
if ~exist('headerChannelNames','var')
     headerChannelNames = [];
end

disp(['Reading [' filename '] ...']);

% Grab the header and some sample data
fid = fopen(filename);
% REMINGTON change - read in 150 lines instead of only 60 lines, there was a case of 112
% REMINGTON change - keep bumping because older calterms I've seen write hundreds of
% header lines
% REMINGTON change - bump to 400 because of Atlantic
SampleBlock = textscan(fid,'%s',400,'delimiter','\r','whitespace','\b\n\t','bufsize',6000);
fclose(fid);

% Find landmarks in the header to set hooks for constants
try
     while findBearingsFlag == 0
          HeaderLine = SampleBlock{1,1}(FindBearings,1);
          % REMINGTON - This fails if Calterm decides to write the time in
          % 24 hour format, i.e. - 11/8/2011 19:23
          % This happened once, not sure why but it did.
          if (strcmp(HeaderLine{1,1}(1,end-1:end), 'PM')) || (strcmp(HeaderLine{1,1}(1,end-1:end), 'AM'))
               FileStart = HeaderLine{1,1}(1,1:end);
               FileStartNum = datenum(FileStart);
          end
          if strcmp(HeaderLine{1,1}(1,1:2), '00') || strcmp(HeaderLine{1,1}(1,1:2), '0,')
               if (HEADERPARAMETERS == 0)
                    HEADERPARAMETERSBEGIN = FindBearings;
               end
               HEADERPARAMETERS = HEADERPARAMETERS + 1;
          end
          if length(HeaderLine{1,1})>=10 && strcmp(HeaderLine{1,1}(1,1:10), 'Parameter ')
               PARAMETERNAMELINE = FindBearings;
          end
          if length(HeaderLine{1,1})>=5 && strcmp(HeaderLine{1,1}(1,1:5), 'Units')
               UNITSLINE = FindBearings;
          end
          if length(HeaderLine{1,1})>=6 && strcmp(HeaderLine{1,1}(1,1:6), '------')
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
catch ex
     % REMINGTON addition - line to write to a log file
     %obj.error.write('*** READ FAILED ~ No Data in File ***');
     obj.event.write('*** READ FAILED ~ No Data in File ***');
     % Original code below
     disp('*** READ FAILED ~ No Data in File ***')
     % Remington change - made this 2 so I can distinguish "no data in file" errors from
     % other read errors (and thus ignore only the no data in file errors.
     readFailed = 2;
     assignin('caller','readFailed',readFailed);
     return
end

if ((PARAMETERNAMELINE == 0) || (UNITSLINE == 0))
     % REMINGTON additon - line to write to a log file
     obj.error.write('*** READ FAILED ~ Parameter Names or Units not found ***');
     obj.event.write('*** READ FAILED ~ Parameter Names or Units not found ***');
     % Original code below
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
               % REMINGTON Step 3 fix for Calterm Garnet v3.6.1.004 log file header
               % problems
               % If this is one of the goofy lines with two with two extra things on the
               % line
               if strcmp(headerParameterLine{1,2},'CaltermVersion') || strcmp(headerParameterLine{1,2},'ScreenMonitorType') || strcmp(headerParameterLine{1,2},'Initial Monitor Rate')
                   % Just ignore this line for now, don't throw an error
                   % There will still be an entry in headerParameterChannels but since
                   % I don't use it I don't care for now
                   continue
               end
               % REMINGTON additon - line to write to a log file
               obj.error.write('*** READ FAILED ~ Error in Header Parameter Value ***');
               obj.event.write('*** READ FAILED ~ Error in Header Parameter Value ***');
               % Original code below
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

% Remington Added, try to pull out some other header information in the easiest fashion
% Log Mode
logMode = toklin(DimBlock{3},','); assignin('caller','LogMode',logMode{2});
% Calterm Version
caltermVer = toklin(DimBlock{NUMBEROFHEADERLINES-6},','); assignin('caller','CaltermVersion',caltermVer{3});
% Screen Monitor Type
monType = toklin(DimBlock{NUMBEROFHEADERLINES-5},','); assignin('caller','ScreenMonitorType',monType{3});
% Initial Monitor Rate
monRate = toklin(DimBlock{NUMBEROFHEADERLINES-4},','); assignin('caller','InitialMonitorRate',monRate{3});

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
% REMINGTON Change - deal with periods, too
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
    % REMINGTON addition - hack to fix for Calterm 3.6.0 with the extra line termination
    if isempty(BlockOfData{1,1}{1})
        % Reset the position and use fgetl to advance one line through the file
        frewind(fid);fgetl(fid);
        % Try to read the data again with the new file starting location
        BlockOfData = textscan(fid, DataFormat, NumbRows, 'delimiter',',', 'treatAsEmpty', 'Infinity', 'headerlines', NUMBEROFHEADERLINES);
        % Don't know why on earth this works, but it does
    end
    fclose(fid);
catch ex
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
catch ex
     % REMINGTON additon - line to write to a log file
     obj.error.write('*** READ FAILED ~ No Timestamp ***');
     obj.event.write('*** READ FAILED ~ No Timestamp ***');
     % Original code below
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
    % REMINGTON additon - line to write to a log file
    obj.error.write('Second line is in a 24 hour data format, fix that in the file.');
    obj.event.write('Second line is in a 24 hour data format, fix that in the file.');
    % Original code below (although this catch block was writen by me)
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

% Check for abs_time backing up when the .csv file crosses midnight UTC
% compensate for this
% If there was a reversal of more than 0.95 days
if min(diff(abs_time)) < -0.95
    % There was a reverse of over .95 days
    % Find the offending location
    idxReverse = find(diff(abs_time) < -0.95);
    % If there was only one reversal location (there should be able to be two)
    if length(idxReverse)==1
        % Add the missing day onto the affected values of abs_time
        abs_time(idxReverse+1:end) = abs_time(idxReverse+1:end) + 1;
    else
        % Note this in the warning log, look for it later
        % There should be now way to have two full day reversals in one .csv file
        obj.warning.write('Failed to fix a day reversal in a file that crosses midnight UTC');
    end
end

% Calculate time of day --
% number of seconds since midnight
% [y, m, d] = datevec(abs_time);
% absDateValue = datenum(y, m, d);
% abs_timeValue = abs_time - absDateValue;

% REMINGTON CHANGE - This is a more reliable and faster way to do it.
tod = (abs_time - floor(abs_time(1))) * 86400;

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

end

function n = datenum2(arg1,arg2,arg3,h,min,s)
%DATENUM Serial date number.
%	N = DATENUM(V) converts one or more date vectors V into serial date 
%	numbers N. Input V can be an M-by-6 or M-by-3 matrix containing M full 
%	or partial date vectors respectively.  DATENUM returns a column vector
%	of M date numbers.
%
%	A date vector contains six elements, specifying year, month, day, hour, 
%	minute, and second. A partial date vector has three elements, specifying 
%	year, month, and day.  Each element of V must be a positive double 
%	precision number.  A serial date number of 1 corresponds to Jan-1-0000.  
%	The year 0000 is merely a reference point and is not intended to be 
%	interpreted as a real year.
%
%	N = DATENUM(S,F) converts one or more date strings S to serial date 
%	numbers N using format string F. S can be a character array where each
%	row corresponds to one date string, or one dimensional cell array of 
%	strings.  DATENUM returns a column vector of M date numbers, where M is 
%	the number of strings in S. 
%
%	All of the date strings in S must have the same format F, which must be
%	composed of date format symbols according to Table 2 in DATESTR help.
%	Formats with 'Q' are not accepted by DATENUM.  
%
%	Certain formats may not contain enough information to compute a date
%	number.  In those cases, hours, minutes, and seconds default to 0, days
%	default to 1, months default to January, and years default to the
%	current year. Date strings with two character years are interpreted to
%	be within the 100 years centered around the current year.
%
%	N = DATENUM(S,F,P) or N = DATENUM(S,P,F) uses the specified format F
%	and the pivot year P to determine the date number N, given the date
%	string S.  The pivot year is the starting year of the 100-year range in 
%	which a two-character year resides.  The default pivot year is the 
%	current year minus 50 years.
%
%	N = DATENUM(Y,MO,D) and N = DATENUM([Y,MO,D]) return the serial date
%	numbers for corresponding elements of the Y,MO,D (year,month,day)
%	arrays. Y, MO, and D must be arrays of the same size (or any can be a
%	scalar).
%
%	N = DATENUM(Y,MO,D,H,MI,S) and N = DATENUM([Y,MO,D,H,MI,S]) return the
%	serial date numbers for corresponding elements of the Y,MO,D,H,MI,S
%	(year,month,day,hour,minute,second) arrays.  The six arguments must be
%	arrays of the same size (or any can be a scalar).
%
%	N = DATENUM(S) converts the string or date vector (as defined by 
%	DATEVEC) S into a serial date number.  If S is a string, it must be in 
%	one of the date formats 0,1,2,6,13,14,15,16,23 as defined by DATESTR.
%	This calling syntax is provided for backward compatibility, and is
%	significantly slower than the syntax which specifies the format string.
%	If the format is known, the N = DATENUM(S,F) syntax should be used.
%
%	N = DATENUM(S,P) converts the date string S, using pivot year P. If the 
%	format is known, the N = DATENUM(S,F,P) or N = DATENUM(S,P,F) syntax 
%	should be used.
%
%	Note:  The vectorized calling syntax can offer significant performance
%	improvement for large arrays.
%
%	Examples:
%		n = datenum('19-May-2000') returns n = 730625. 
%		n = datenum(2001,12,19) returns n = 731204. 
%		n = datenum(2001,12,19,18,0,0) returns n = 731204.75. 
%		n = datenum('19.05.2000','dd.mm.yyyy') returns n = 730625.
%
%	See also NOW, DATESTR, DATEVEC, DATETICK.

%   Copyright 1984-2007 The MathWorks, Inc.
%   $Revision: 1.24.4.13 $  $Date: 2007/12/06 13:30:58 $

if (nargin<1) || (nargin>6)
    error('MATLAB:datenumr:Nargin',nargchk(1,6,nargin));
end

% parse input arguments
isdatestr = ~isnumeric(arg1);
isdateformat = false;
if nargin == 2
    isdateformat = ischar(arg2);
elseif nargin == 3
    isdateformat = [ischar(arg2), ischar(arg3)];
end
% try to convert date string or date vector to a date number
try
    switch nargin
        case 1 
            if isdatestr
                n = datenummx(datevec2(arg1));
            elseif ((size(arg1,2)==3) || (size(arg1,2)==6)) && ...
                    any(abs(arg1(:,1) - 2000) < 10000)
                n = datenummx(arg1);
            else
                n = arg1;
            end
        case 2
            if isdateformat
                if ischar(arg1)
					arg1 = cellstr(arg1);
                end
                if ~iscellstr(arg1)
                    %At this point we should have a cell array.  Otherwise error.
                    error('MATLAB:datenum:NotAStringArray', ...
                        'The input to DATENUM was not an array of strings.');
                end
                if isempty(arg2)
                    n = datenummx(datevec(arg1));
                else
                    n = dtstr2dtnummx(arg1,cnv2icudf(arg2));
                end
            else
                n = datenummx(datevec(arg1,arg2));
            end
        case 3
			if any(isdateformat)
				if isdateformat(1) 
					format = arg2;
					pivot = arg3;
				elseif isdateformat(2)
					format = arg3;
					pivot = arg2;
				end
				if ischar(arg1)
					arg1 = cellstr(arg1);
				end
                if ~iscellstr(arg1)
                    %At this point we should have a cell array.  Otherwise error.
                    error('MATLAB:datenum:NotAStringArray', ...
                        'The input to DATENUM was not an array of strings.');
                end
				icu_dtformat = cnv2icudf(format);
				showyr =  strfind(icu_dtformat,'y'); 
                if ~isempty(showyr)
                    wrtYr =  numel(showyr);
                    checkYr = diff(showyr);
                    if any(checkYr~=1)
                        error('MATLAB:datenum:YearFormat','Unrecognized year format');
                    end
                    switch wrtYr
                        case 4,
                            icu_dtformat = strrep(icu_dtformat,'yyyy','yy');
                        case 3,
                            icu_dtformat = strrep(icu_dtformat,'yyy','yy');
                    end
                end
                if (isempty(format))
                    n = datenummx(datevec(arg1,pivot));
                else
                    if (isempty(pivot))
                        n = dtstr2dtnummx(arg1,icu_dtformat);
                    else
                        n = dtstr2dtnummx(arg1,icu_dtformat,pivot);
                    end
                end
			else
                n = datenummx(arg1,arg2,arg3);
			end
        case 6, n = datenummx(arg1,arg2,arg3,h,min,s);
        otherwise, error('MATLAB:datenum:Nargin',...
                         'Incorrect number of arguments');
    end
catch exception   
    if (nargin == 1 && ~isdatestr)
        identifier = 'MATLAB:datenum:ConvertDateNumber';
    elseif (nargin == 1 && isdatestr) || (isdatestr && any(isdateformat))
        identifier = 'MATLAB:datenum:ConvertDateString';
    elseif (nargin > 1) && ~isdatestr && ~any(isdateformat)
        identifier = 'MATLAB:datenum:ConvertDateVector';
    else
        identifier = exception.identifier;
    end
    newExc = MException( identifier,'DATENUM failed.');
    newExc = newExc.addCause(exception);
    throw(newExc);
end

end
