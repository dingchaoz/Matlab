function calNumber = dot2num(obj, calDotStr)
%Return a 6 or 8 digit cal number given a dot separated string
%   Convert a calibration from this format: 4.13.0.6 or 31.2.0.26
%   To this format:                           413006 or 31020026
%   
%   This returns a 6 or 8 digit format, without decimals, that follows this convetion:
%       X.XX.X.XX of version control, but with the dots removed
%     XX.XX.XX.XX of version control, but with the dots removed
%   
%   Examples (HDE Style):    5.0.0.5  --> 500005
%                           4.10.0.18 --> 410018
%   
%   Examples (CMI Style): 31.42.99.32 --> 41429932
%                           31.2.0.26 --> 31020026
%   
%   Usage: calNumber = dot2num(obj, calDotStr)
%   
%   Inputs -
%   calDotStr: Input string of a software version in Calterm dot notation (e.g., 9.20.0.4)
%   
%   Outputs -
%   calNumber: Numeric version of the software in 6 or 8 digit format (e.g., 920004)
%   
%   Original Version - Chris Remington - January 10, 2011
%   Revised - Chris Remington - May 7, 2013
%     - Modified to automatically pick either 6 digit format or 8 digit format based on
%       the major version ( <10 = HDE style 6 digit version control, otherwise 8 digit)
%   Adapted - Chris Remington - May 14, 2013
%     - Modified to be included in the IUPRtool object
%   Adapted - Chris Remington - June 20, 2013
%     - Modified to be included in the database IUPR object
%   Revised - Chris Remington - September 23, 2013
%     - Changed to use the new isLDD flag in the IUPR object so that
%       programs with 7-digit software version have the correct numeric
%       software version ouput
%     - If the first number is > 9, then this will ignor the isLDD flag
%       and output it as an 8-digit software version
%   Revised - Chris Remington - January 31, 2013
%     - Switched to only do something special for HD 6-digit software
%     - LDD 7 digit software just has the leading zero fall off so can be done normally
    
    % If a string was supplied as input
    if ischar(calDotStr)
        % Find the '.' in the string
        IdxDot = strfind(calDotStr, '.');
        % If three '.' were found, continue
        if length(IdxDot) == 3
            % Pull out the four version numbers
            % X.0.0.0
            num1 = calDotStr(1:(IdxDot(1)-1));
            % 0.X.0.0
            num2 = calDotStr((IdxDot(1)+1):(IdxDot(2)-1));
            % 0.0.X.0
            num3 = calDotStr((IdxDot(2)+1):(IdxDot(3)-1));
            % 0.0.0.X
            num4 = calDotStr((IdxDot(3)+1):end);
            
            % If this is a HD program using 6-digit software
            if obj.is6Dig
                % Pad position 2 and 4 if necessary
                if length(num2) == 1
                    % Add leading zero
                    num2 = ['0', num2];
                end
                if length(num4) == 1
                    % Add leading zero
                    num4 = ['0', num4];
                end
                % Continue if each part turned out to be the correct length
%                 if length(num1)==1 && length(num2)==2 && length(num3)==1 && length(num4)==2
                    % Concatinate the four parts together
                    formattedCalString = [num1 num2 num3 num4];
                    % Convert to a double and return that value
                    calNumber = str2double(formattedCalString);
                    % Check if str2double failed to convert the data
                    if isnan(calNumber)
                        % Throw an error
                        error('Capability:dot2num:str2doubleError','There was a problem with str2double converting the interpreted calibration number %s to a number',formattedCalString)
                    end
%                 else
%                     % Individual pieces weren't the right length, return an error
%                     error('Capability:dot2num:Error6Digit','There was an problem with the expected number of digits when processing %s',calDotStr);
%                 end
            else % This is a 7 or 8 digit format calibration number
                % Pad position 2, 3, and 4 if necessary with a leading zero
                if length(num2) == 1
                    % Add leading zero
                    num2 = ['0', num2];
                end
                if length(num3) == 1
                    % Add leading zero
                    num3 = ['0', num3];
                end
                if length(num4) == 1
                    % Add leading zero
                    num4 = ['0', num4];
                end
                % Continue if each part turned out to be the correct length
                if length(num2)==2 && length(num3)==2 && length(num4)==2 % length(num1)==2 && 
                    % Concatinate the four parts together
                    formattedCalString = [num1 num2 num3 num4];
                    % Convert to a double and return that value
                    calNumber = str2double(formattedCalString);
                    % Check if str2double failed to convert the data
                    if isnan(calNumber)
                        % Throw an error
                        error('Capability:dot2num:str2doubleError','There was a problem with str2double converting the interpreted calibration number %s to a number',formattedCalString)
                    end
                else
                    % Individual pieces weren't the right length, return an error
                    error('Capability:dot2num:Error8Digit','There was an problem with the expected number of digits when processing %s',calDotStr);
                end
            end
        else
            % Couldn't find three dots, throw an error
            error('Capability:dot2num:InvalidStringInput','Couldn''t find three dots in the string %s',calDotStr);
        end
    else
        % Input wasn't a string, throw an error
        error('Capability:dot2num:InvalidInput','Input must be a string or a software version is dot notation (e.g., 31.2.0.26)');
    end
end
