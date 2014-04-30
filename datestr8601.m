function varargout = datestr8601(DVN,varargin)
% Convert a Date Vector/Serial Date Number to an ISO 8601 formatted Date String (timestamp).
%
% (c) 2013 Stephen Cobeldick
%
% ### Function ###
%
% Syntax:
%  String = datestr8601
%  String = datestr8601(DateVN)
%  String = datestr8601(DateVN,Token)
%  [String1,String2,...] = datestr8601(DateVN,Token1,Token2,...)
%
% Fast conversion of a Date Vector or Serial Date Number to a string, the
% style of which is controlled by (optional) input token/s. The string may
% be an ISO 8601 timestamp or a single date/time value: multiple tokens may
% be used to output multiple strings (faster than multiple function calls).
%
% By default the function uses the current time and returns the basic
% ISO 8601 calendar timestamp: this is very useful for naming files that
% sort alphabetically into chronological order!
%
% The ISO 8601 timestamp style options are:
%
% - Date in ordinal, calendar or week-numbering notation.
% - Basic or Extended format (without/with unit separation characters).
% - Any date-time separator character (with a few exceptions).
% - Full or lower precision (fewer trailing date/time units).
% - Decimal fraction of the trailing unit (decimal places).
%
% These style options are explained in the tables below (see "Timestamps").
%
% Note 1: Some Strings use the ISO 8601 week-numbering year, where the first
%  week of the year includes the first Thursday of the year: check the tables!
% Note 2: Out-of-range values are permitted in the Date Vector.
% Note 3: Calls undocumented MATLAB functions "datevecmx", "datenummx" & "ismembc".
%
% See also DATENUM8601 CLOCK NOW DATESTR DATENUM DATEVEC DATEROUND
%
% ### Examples ###
%
% Examples use the date+time described by the vector [1999,1,3,15,6,48.0568].
%
% datestr8601(datenum8601('19990103T150648'),'ymdHMS4')
%  ans = '19990103T150648.0568'
%
% datestr8601
%  ans = '19990103T150648'
%
% datestr8601([],'yn_HM')
%  ans = '1999003_1506'
%
% datestr8601(now-1,'DDDD')
%  ans = 'Saturday'
%
% datestr8601(clock,'*ymdHMS')
%  ans = '1999-01-03T15:06:48'
%
% [A,B,C,D] = datestr8601(clock,'ddd','mmmm','yyyy','*YWD')
% sprintf('The %s of %s %s has the ISO week-date "%s".',A,B,C,D)
%  ans = 'The 3rd of January 1999 has the ISO week-date "1998-W53-7".'
%
% ### Single Value Tokens ###
%
% For date values the case of the Token determines the output String's
% year-type: lowercase = calendar year, UPPERCASE = week-numbering year.
%
% 'W' = the standard ISO 8601 week number (this is probably what you want).
% 'w' = the weeks (rows) shown on an actual printed calendar (very esoteric).
%
% 'Q' = each quarter is 13 weeks (the last may be 14). Uses week-numbering year.
% 'q' = each quarter is three months long: Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec.
%
% 'N'+'R' = 7*52 or 7*53 (year dependent).
% 'n'+'r' = 365 (or 366 if a leap year).
%
% Input | Output                                      | Output
% Token | String Date/Time Representation             | Example
% ------|---------------------------------------------|---------
% Calendar year:                                      |
% 'yyyy'| year, four digit                            |'1999'
% 'n'   | day of the year, variable digits            |'3'
% 'nnn' | day of the year, three digit, zero padded   |'003'
% 'r'   | days remaining in year, variable digits     |'362'
% 'rrr' | days remaining in year, three digit, padded |'362'
% 'q'   | year quarter, 3-month                       |'1'
% 'qq'  | year quarter, 3-month, abbreviation         |'Q1'
% 'qqq' | year quarter, 3-month, ordinal and suffix   |'1st'
% 'w'   | week of the year, one or two digit          |'1'
% 'ww'  | week of the year, two digit, zero padded    |'01'
% 'www' | week of the year, ordinal and suffix        |'1st'
% 'm'   | month of the year, one or two digit         |'1'
% 'mm'  | month of the year, two digit, zero padded   |'01'
% 'mmm' | month name, three letter abbreviation       |'Jan'
% 'mmmm'| month name, in full                         |'January'
% 'd'   | day of the month, one or two digit          |'3'
% 'dd'  | day of the month, two digit, zero padded    |'03'
% 'ddd' | day of the month, ordinal and suffix        |'3rd'
% ------|---------------------------------------------|---------
% Week-numbering year:                                |
% 'YYYY'| year, four digit,                           |'1998'
% 'N'   | day of the year, variable digits            |'371'
% 'NNN' | day of the year, three digit, zero padded   |'371'
% 'R'   | days remaining in year, variable digits     |'0'
% 'RRR' | days remaining in year, three digit, padded |'000'
% 'Q'   | year quarter, 13-week                       |'4'
% 'QQ'  | year quarter, 13-week, abbreviation         |'Q4'
% 'QQQ' | year quarter, 13-week, ordinal and suffix   |'4th'
% 'W'   | week of the year, one or two digit          |'53'
% 'WW'  | week of the year, two digit, zero padded    |'53'
% 'WWW' | week of the year, ordinal and suffix        |'53rd'
% ------|---------------------------------------------|---------
% Weekday:                                            |
% 'D'   | weekday number (Monday=1)                   |'7'
% 'DD'  | weekday name, two letter abbreviation       |'Su'
% 'DDD' | weekday name, three letter abbreviation     |'Sun'
% 'DDDD'| weekday name, in full                       |'Sunday'
% ------|---------------------------------------------|---------
% Time of day:                                        |
% 'H'   | hour of the day, one or two digit           |'15'
% 'HH'  | hour of the day, two digit, zero padded     |'15'
% 'M'   | minute of the hour, one or two digit        |'6'
% 'MM'  | minute of the hour, two digit, zero padded  |'06'
% 'S'   | second of the minute, one or two digit      |'48'
% 'SS'  | second of the minute, two digit, zero padded|'48'
% 'F'   | deci-second of the second, zero padded      |'0'
% 'FF'  | centisecond of the second, zero padded      |'05'
% 'FFF' | millisecond of the second, zero padded      |'056'
% ------|---------------------------------------------|---------
% 'MANP'| Midnight/AM/Noon/PM (+-0.0005s)             |'PM'
% ------|---------------------------------------------|---------
%
% ### ISO 8601 Timestamps ###
%
% Output    | Basic Format             | Extended Format (token prefix '*')
% Date      | Input  | Output Timestamp| Input   | Output Timestamp
% Notation: | Token: | Example:        | Token:  | Example:
% ----------|--------|-----------------|---------|-------------------------
% Ordinal   |'ynHMS' |'1999003T150648' |'*ynHMS' |'1999-003T15:06:48'
% ----------|--------|-----------------|---------|-------------------------
% Calendar  |'ymdHMS'|'19990103T150648'|'*ymdHMS'|'1999-01-03T15:06:48'
% ----------|--------|-----------------|---------|-------------------------
% Week      |'YWDHMS'|'1998W537T150648'|'*YWDHMS'|'1998-W53-7T15:06:48'
% ----------|--------|-----------------|---------|-------------------------
%
% Timestamp can omit leading or trailing units (reduced precision), eg:
% ----------|--------|-----------------|---------|-------------------------
%           |'DHMS'  |'7T150648'       |'*DHMS'  |'7T15:06:48'
% ----------|--------|-----------------|---------|-------------------------
%           |'mdH'   |'0103T15'        |'*mdH'   |'01-03T15'
% ----------|--------|-----------------|---------|-------------------------
% Date-time separator character can be specified (default='T'), eg:
% ----------|--------|-----------------|---------|-------------------------
%           |'n_HMS' |'003_150648'     |'*n_HMS' |'003_15:06:48'
% ----------|--------|-----------------|---------|-------------------------
%           |'YWD@H' |'1998W537@15'    |'*YWD@H' |'1998-W53-7@15'
% ----------|--------|-----------------|---------|-------------------------
% Trailing date/time value can have decimal digits (fraction), eg:
% ----------|--------|-----------------|---------|-------------------------
%           |'HMS4'  |'150648.0568'    |'*HMS4'  |'15:06:48.0568'
% ----------|--------|-----------------|---------|-------------------------
%           |'YW7'   |'1998W53.9471032'|'*YW7'   |'1998-W53.9471032'
% ----------|--------|-----------------|---------|-------------------------
%           |'y10'   |'1999.0072047202'|'*y10'   |'1999.0072047202'
% ----------|--------|-----------------|---------|-------------------------
%
% Note 4: Token parsing matches Single Value Tokens before ISO 8601 Tokens.
% Note 5: Function does not check for ISO 8601 compliance: user beware!
% Note 6: Date-time separator must not be any of [+-./0123456789:DFHMPRSWYZdmny].
%
% ### Inputs & Outputs ###
%
% Inputs:
%  DateVN = Date Vector, [year,month,day,hour,minute,second.millisecond].
%         = Serial Date Number, where 1 = start of 1st January of the year 0000.
%         = []*, uses current time (default).
%  Token  = String token, chosen from the above tables (default is 'ymdHMS').
%
% Outputs:
%  String = String date-value, whose representation is controlled by Token.
%
% Inputs  = (DateVN,Token1,Token2,...)
% Outputs = [String1,String2,...]

DfAr = {'ymdHMS'}; % {Token}
DfAr(1:numel(varargin)) = varargin;
%
% Calculate date-vector:
if nargin==0||isempty(DVN) % Default = now
    DtV = clock;
elseif isscalar(DVN)       % Serial Date Number
    DtV = datevecmx(DVN);
elseif isrow(DVN)          % Date Vector
    DtV = datevecmx(datenummx(DVN));
else
    error('Invalid Date Vector or Date Number. Check array dimensions.');
end
% Calculate serial date-number:
DtN = datenummx(DtV);
% Weekday index (Mon=0):
DtD = mod(floor(DtN(1))-3,7);
% Adjust date to suit week-numbering:
DtN(2,1) = DtN(1)+3-DtD;
DtV(2,:) = datevecmx(floor(DtN(2)));
DtV(2,4:6) = DtV(1,4:6);
% Separate milliseconds from seconds:
DtV(:,7) = round(rem(DtV(1,6),1)*10000);
DtV(:,6) = floor(DtV(1,6));
% Date at the end of the year [last,this]:
DtE(1,:) = datenummx([DtV(1)-1,12,31;DtV(1),12,31]);
DtE(2,:) = datenummx([DtV(2)-1,12,31;DtV(2),12,31]);
DtO = 3-mod(DtE(2,:)+1,7);
DtE(2,:) = DtE(2,:)+DtO;
%
varargout = DfAr;
%
ChO = ['00000000001111111111222222222233333333334444444444555555555566';...
       '01234567890123456789012345678901234567890123456789012345678901';...
       'tsnrtttttttttttttttttsnrtttttttsnrtttttttsnrtttttttsnrttttttts';...
       'htddhhhhhhhhhhhhhhhhhtddhhhhhhhtddhhhhhhhtddhhhhhhhtddhhhhhhht'].';
%
for m = 1:numel(DfAr)
    tok = DfAr{m};
    tkl = numel(tok);
    tkw = strcmp(upper(tok),tok);
    switch tok
        case {'S','SS','M','MM','H','HH','d','dd','ddd','m','mm'}
            % seconds, minutes, hours, day of the month, month
            val = DtV(1,strfind('ymdHMS',tok(1)));
            varargout{m} = ChO(1+val,1+(tkl~=2&&val<10):max(2,2*(tkl-1))); % (also week)
        case {'D','DD','DDD','DDDD'}
            % weekday
            varargout{m} = d8601Day(tkl,DtD);
        case {'mmm','mmmm'}
            % month of the year
            varargout{m} = d8601Mon(tkl,DtV(1,2));
        case {'F','FF','FFF'}
            % deci/centi/milliseconds
            str = sprintf('%04.0f',DtV(1,7));
            varargout{m} = str(1:tkl);
        case {'n','nnn','r','rrr','N','NNN','R','RRR'}
            % day of the year, days remaining in the year
            varargout{m} = sprintf('%0*.0f',tkl,abs(floor(DtN(1))-...
                DtE(1+tkw,1+strncmpi('r',tok,1))));
        case {'y','yyyy','Y','YYYY'}
            % year
            varargout{m} = sprintf('%04.0f',DtV(1+tkw));
        case {'w','ww','www','W','WW','WWW'}
            % week of the year
            val = floor(max(0,(DtN(1+tkw)-DtE(1+tkw)+DtO(1)*~tkw))/7);
            varargout{m} = ChO(2+val,1+(tkl~=2&&val<10):max(2,2*(tkl-1))); % (also S/M/H/d/m)
        case {'q','qq','qqq','Q','QQ','QQQ'}
            % year quarter
            val = [ceil(DtV(1,2)/3),min(4,1+floor((DtN(2)-DtE(2))/91))];
            varargout{m} = d8601Qtr(tkl,val(1+tkw));
        case 'MANP'
            % midnight/am/noon/pm
            apc = {'Midnight','AM','Noon','PM'};
            ind = 2+2*(DtV(1,4)>=12)-(all(DtV(1,5:7)==0)&&any(DtV(1,4)==[0,12]));
            varargout{m} = apc{ind};
%        case 'test'
%            varargout{m} = d8601Test(DtN(1));
        otherwise % All ISO 8601 timestamps
            % Check if extended or basic format, identify any decimal digits:
            Ext = strncmp('*',tok,1);
            DcP = find(~isstrprop(tok,'digit'),1,'last');
            Dgt = sscanf(tok(DcP+1:end),'%d');
            tok = tok(1+Ext:DcP);
            % Identify date-time separator and start of timestamp:
            IsT = ismembc(tok,'+-./0123456789:DFHMPRSWYZdmny'); % (presorted)
            tkl = sum(IsT);
            BeI = strfind('YWDHMSymdHMSynHMS',tok(IsT));
            assert(any(BeI)&&tkl<(7-rem(BeI(1)-1,6)),'Input token is not recognized.')
            switch sum(~IsT)
                case 0 % Standard 'T' separator.
                    varargout{m} = d8601ISO(tkl,BeI(1),DtV,DtN,DtE,DtD,ChO,Ext,Dgt,'T');
                case 1 % User supplied separator.
                    nxt = strcmp('H',tok([false,~IsT(1:end-1)]));
                    assert(nxt,'Input token date-time separator position incorrect.')
                    varargout{m} = d8601ISO(tkl,BeI(1),DtV,DtN,DtE,DtD,ChO,Ext,Dgt,tok(~IsT));
                otherwise
                    error('Input token is not recognized: too many separator chars.')
            end
    end
end
%
end
%--------------------------------------------------------------------------
function DtS = d8601Day(tkl,ind)
% weekday
%
if tkl==1
    StT = '1234567';
    DtS = StT(1+ind);
else
    ind = 1+ind;
    StT = ['Monday   ';'Tuesday  ';'Wednesday';...
           'Thursday ';'Friday   ';'Saturday ';'Sunday   '];
    StE = [6,7,9,8,6,8,6]; % Weekday name lengths
    DtS = StT(ind,1:max(tkl,StE(ind)*(tkl-3))); % (also month)
end
%
end
%--------------------------------------------------------------------------
function DtS = d8601Mon(tkl,ind)
% month
%
StT = ['January  ';'February ';'March    ';'April    ';...
       'May      ';'June     ';'July     ';'August   ';...
       'September';'October  ';'November ';'December '];
StE = [7,8,5,5,3,4,4,6,9,7,8,8]; % Month name lengths
DtS = StT(ind,1:max(tkl,StE(ind)*(tkl-3))); % (also weekday)
%
end
%--------------------------------------------------------------------------
function DtS = d8601Qtr(tkl,ind)
% year quarter
%
QT = ['Q1st';'Q2nd';'Q3rd';'Q4th'];
QI = 1+abs(tkl-2):max(2,2*(tkl-1));
DtS = QT(ind,QI);
%
end
%--------------------------------------------------------------------------
function DtS = d8601ISO(tkl,ind,DtV,DtN,DtE,DtD,ChO,Ext,Dgt,sep)
% ISO 8601 timestamp
%
% Determine value indices within the token:
BeM = [1,2,3,4,5,6,1,2,3,4,5,6,1,3,4,5,6];
BeR = BeM(ind:ind+tkl-1);
% For calculating decimal fraction of date/time values:
BeE = BeR(end);
DtK = 1;
DtW = DtV(1,:);
DtZ = [0,1,1,0,0,0,0];
%
% {separators;values}:
if Ext % Extended-format
    DtC = {'','-','-',sep,':',':';'','','','','',''};
else % Basic-format
    DtC = {'', '', '',sep, '', '';'','','','','',''};
end
%
% hours, minutes, seconds:
for m = 4:max(BeR)
    DtC{2,m} = ChO(1+DtW(m),1:2);
end
%
ind = ceil(ind/6);
switch ind
    case 1 % Week-numbering
        DtW = DtV(2,:);
        % Decimal fraction of weeks, not days:
        if BeR(end)==2
            BeE = 3;
            DtK = 7;
            DtZ(3) = DtW(3)-DtD;
        end
        % weekday:
        if any(BeR==3)
            DtC{2,3} = ChO(2+DtD,2);
        end
        % week of the year:
        if any(BeR==2)
            DtC{2,2} = ['W',ChO(2+floor((DtN(2)-DtE(2))/7),1:2)];
        end
    case 2 % Calendar.
        % month, day of the month:
        for m = max(2,min(BeR)):3
            DtC{2,m} = ChO(1+DtW(m),1:2);
        end
    case 3 % Ordinal.
        % day of the year:
        DtC{2,3} = sprintf('%03.0f',floor(DtN(1))-DtE(1));
end
%
if BeR(1)==1
    % year:
    DtC{2,1} = sprintf('%04.0f',DtW(1));
end
%
% Concatenate separator and value strings:
BeN = [BeR*2-1;BeR*2];
DtS = [DtC{BeN(2:end)}];
%
% Decimal fraction (decimal places):
if 0<Dgt
    prc = 0;
    if BeR(end)==6
        % second
        prc = 4;
        str = sprintf('%0*.0f',prc,DtW(7));
    elseif BeR(end)==3
        % day
        prc = 10;
        str = sprintf('%.*f',prc,rem(DtN(1),1));
        str(1:2) = [];
    elseif any(DtW(BeR(end)+1:7)>DtZ(BeR(end)+1:7));
        % year/month/week/hour/minute
        prc = 16;
        % Floor all trailing units:
        DtW(7) = [];
        DtW(BeR(end)+1:6) = DtZ(BeR(end)+1:6);
        DtF = datenummx(DtW);
        % Increment the chosen unit:
        DtW(BeE) = DtW(BeE)+DtK;
        % Decimal fraction of the chosen unit:
        dcf = (DtN(1+(ind==1))-DtF)/(datenummx(DtW)-DtF);
        str = sprintf('%.*f',prc,dcf);
        str(1:2) = [];
    end
    str(1+prc:Dgt) = '0';
    DtS = [DtS,'.',str(1:Dgt)];
end
%
end
%--------------------------------------------------------------------------
%{
function s = d8601Test(DtN)
% Compare runtimes of this function and "datestr".
%
MN = 10000;
%
MS = mfilename;
DS = 'datestr';
MF = str2func(MS);
DF = str2func(DS);
%
profile on
tic
for m = 1:MN
    %B1 = DF(DtN,'yyyy-mm-dd_HH:MM:SS');   % Test 1
    B1 = DF(DtN,'yyyy-mm-dddd');          % Test 2
end
T1 = toc;
%
tic
for m = 1:MN
    %B2 = MF(DtN,'*ymd_HMS');              % Test 1
    [A,B,C] = MF(DtN,'yyyy','mm','DDDD'); % Test 2
    B2 = [A,'-',B,'-',C];                 % Test 2
end
T2 = toc;
profile viewer
%
XS = char(['"',DS,'"'],['"',MS,'"']);
s = sprintf('%s (%05.2fs): ''%s''\n%s (%05.2fs): ''%s''',XS(1,:),T1,B1,XS(2,:),T2,B2);
%
end
%}
%----------------------------------------------------------------------End!
