function calDotStr = num2dot(obj, calNumber)
%Convert a cal number to a dot notation string
%   Convert a calibration from this format:  413006 or 31020026
%   To this format:                          4.13.0.6 or 31.2.0.26
%   
%   Examples (HDE Style): 500005   --> 5.0.0.5
%                         410018   --> 4.10.0.18
%   
%   Examples (CMI Style): 41429932 --> 31.42.99.32
%                         31020026 --> 31.2.0.26
%   
%   Usage: calDotStr = num2dot(obj, calNumber)
%   
%   Inputs -
%   calNumber:  Numeric version of the software in 6 or 8 digit format (e.g., 920004)
%   
%   Outputs -
%   calDotStr:  String of a software version in Calterm dot notation (e.g., 9.20.0.4)
%   
%   Original Version - Chris Remington - June 20, 2013
%   Revised - Chris Remington - July 17, 2013
%     - Fixed the error checking in the beginning and added functionality where a
%       character array is attempted to be converted to a number first to use before
%       erroring out
%   Revised - Chris Remington - September 23, 2013
%     - Revised dot2num to use the isLDD flag to account for 7-digit
%       software versions but num2dot doesn't need to be revised because it
%       can use the value of the numeric software to decide 7-digit format
%   Revised - Chris Remington - January 31, 2013
%     - Changed the isLDD flag in dot2num but as stated above no action is needed here
    
    % If a character array was passed in
    if ischar(calNumber)
        % Try to convert it to a number
        calNumber = str2double(calNumber);
        % If a NaN was returned
        if isnan(calNumber)
            % Throw an error as the input was invalud
            error('BoxPlotGenerator:num2dot:InvalidInput','Input to calNumber must be a numeric value or single character array that could represent a number');
        end
    end
    
    if ~isnumeric(calNumber) || length(calNumber)~=1
        % Throw an error
        error('BoxPlotGenerator:num2dot:InvalidInput','Input to calNumber must be a numeric value');
    end
    
    % If this is an HD-style 6 digit software version (X.XX.X.XX)
    if calNumber >= 100000 && calNumber <= 999999
        
        % Pull off the first number
        part1 = floor(calNumber/1e5);
        % Pull off the second two numbers
        part2 = floor(calNumber/1e3) - part1*1e2;
        % Pull off the third number
        part3 = floor(calNumber/1e2) - part1*1e3 - part2*1e1;
        % Pull off the fourth two numbers
        part4 = calNumber - part1*1e5 - part2*1e3 - part3*1e2;
        
        % Format a string output
        calDotStr = sprintf('%.0f.%.0f.%.0f.%.0f', part1, part2, part3, part4);
        
    % Elseif this is an 8 digit software version (XX.XX.XX.XX)
    % 7-digit numbers will just assume the leading number is a single digit
    elseif calNumber >= 1000000 && calNumber <= 99999999
        
        % Pull off the first number
        part1 = floor(calNumber/1e6);
        % Pull off the second number
        part2 = floor(calNumber/1e4) - part1*1e2;
        % Pull off the third number
        part3 = floor(calNumber/1e2) - part1*1e4 - part2*1e2;
        % Pull off the fourth number
        part4 = calNumber - part1*1e6 - part2*1e4 - part3*1e2;
        
        % Format a string output
        calDotStr = sprintf('%.0f.%.0f.%.0f.%.0f', part1, part2, part3, part4);
        
    else % there was no match
        % Throw an error
        error('BoxPlotGenerator:num2dot:InvalidInput','The number input of %f couldn''t be interpreted into a software dot notation string as it must be between 6 and 8 digits long.',calNumber)
    end
    
end
