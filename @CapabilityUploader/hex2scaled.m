function scaledData = hex2scaled(obj, hexString, dataType, varargin)
%Take in a hex string and return a properly scaled double version of that number
%   Take in a hex string representing the raw bits of a piece of data, and
%   given the data type, event driven data flag, and optional b-number, 
%   this function will calculate and return a double of the properly scaled
%   variable
%   
%   Input---
%   hexString:  the string of hexadecimal characters to be converted
%   dataType:   the dataType of the variable (handles int8, int16, int32,
%                   uint8, uint16, uint32, and float)
%   varargin:   B-number specifier. Need to specify for ALL integers. Error
%                   will be thrown if specified for a float.
%   
%   Output--- double of the properly interpreted and scaled value
    
    % TO BE HANDLED IN ANOTHER FUNCTION:
        %   The event driven data, for variables less than 32-bits, contains junk
        %   on the end, whereas the MinMax data properly interprets this
        %   difference and doesn't behave this way. This function assumes that the
        %   correct characters are going to be passed into it (e.g., 2
        %   characters for 8-bit parameters, 4 characters for 16-bit parameters,
        %   8 characters for 32-bit parameters.)
    
%   NOTE TO SELF - This should worry less about error-checking and leave
%   that to another function (this should focus on decoding, the other
%   function should focus on error checking so as to not use this fcn in an
%   incosistant manner.)
    
%   Original Version - Chris Remington - January 10, 2012
%   Revised - Chris Remington - January 25, 2012
%     - Commented out ishexchars
    
    % If there is a varargin input
    if ~isempty(varargin)
        % If only one was specified
        if length(varargin) == 1
            % If it's numeric and not empty
            if isnumeric(varargin{1}) && ~isempty(varargin{1})
                % Set the b-number to this parameter
                bNum = varargin{1};
            else
                % Bad b-number specified
                error('CapabilityUploader:hex2scaled:bnum', 'Bad b-number input specified');
            end
        else
            % Too many inputs specified
            % Throw an error, stop execution of the code
            error('CapabilityUploader:hex2scaled:inputArg', 'Too many input arguments specified');
        end
    end
    
    % Check the other inputs for empty sets
    if isempty(hexString) || isempty(dataType)
        % Throw an error (this breaks execution of the code)
        error('CapabilityUploader:hex2scaled:emptyInput', 'Empty data passed in.');
    end
    % Check the hexString is a string vector containing hexadecimal
    % characters
    % NOTE - Commented out ishexchars to imporve speed slightly, hex2dec()
    % function already does this exact same thing and throws an error, no
    % need to do it twice.
    if ~ischar(hexString) || (size(hexString,1) ~= 1) %|| ~ishexchars(hexString)
        % Throw an error
        error('CapabilityUploader:hex2scaled:InputArgErr', 'Non-character string or character array passed in');
    end
    % Check that dataType is a string vector 
    if ~ischar(dataType) || (size(dataType,1) ~= 1)
        % Throw an error
        error('CapabilityUploader:hex2scaled:InputArgErr', 'Non-character string or character array passed in');
    end
    
    % You can make it here if:
    % - b-number is valid
    % - hexString is a string vector of hexadecimal characters
    % - dataType is a string vector
    % - no empty values were passed in
    
    % Process the data based on the datatype passed in
    switch dataType
        case 'float'
            % Process it as floating point
            % If a b-number was specified, throw an error
            if exist('bNum', 'var')
                error('CapabilityUploader:hex2scaled:bnum', 'Cannot specify a b-number with a ''float'' datatype');
            end
            % Do the conversion
            scaledData = processFloat(hexString);
        case 'int8'
            % Process it as an int8 datatype
            scaledData = processInt8(hexString, bNum);
        case 'int16'
            % Process it as an int16 datatype
            scaledData = processInt16(hexString, bNum); 
        case 'int32'
            % Process it as an int32 datatype
            scaledData = processInt32(hexString, bNum);
        case {'uint8', 'bool', 'boolean'}
            % Process it as an uint8 datatype
            scaledData = processUint8(hexString, bNum);
        case 'uint16'
            % Process it as an uint16 datatype
            scaledData = processUint16(hexString, bNum);
        case 'uint32'
            % Process it as an uint32 datatype
            scaledData = processUint32(hexString, bNum);
        % Removed here because decodeMinMax will process structures as uint8 itself
        % case 'sync_states_t'
        %     % Process it as an uint8 datatype with a bNum of 8
        %     scaledData = processUint8(hexString, 8);
        otherwise
            % No matches, invalid datatype specified
            error('CapabilityUploader:hex2scaled:InvalidDatatype', 'No datatype match found for specified datatype.');
    end
end

%% Indiviaual Functions for each datatype

% Convert 8 hex characters into a floating point number
function returnDbl = processFloat(hexString)
    % Check that 4 bytes of hex were passed in
    if length(hexString)==8
        % String is of the proper input format, go about converting it
        % * First, run hex2dec on the string to get the integer
        %   representation of the hexadecimal characters
        % * Second, run uint32 to convert the 'double' output of hex2dec
        %   back into it's native integer format
        % * Third, instruct Matlab to now interpret that uint32 'string of
        %   bits' as a single without actually changing the data
        % * Fourth, convert the single to a double
        returnDbl = double(typecast(uint32(hex2dec2(hexString)),'single'));
    else % too many bytes specified, throw an error
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 8 characters in length.')
    end
end

% Convert 2 hex characters into a properly scaled int8 value
function returnDbl = processInt8(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==2
        % Convert hex to decimal, cast to uint8, then interperate as int8
        % Scale given the b number (this assumes the bNum will be between 0
        % and 7)
        returnDbl = double(typecast(uint8(hex2dec2(hexString)),'int8')) / 2^(7-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 2 characters in length.');
    end
end

% Convert 4 hex characters into a properly scaled int16 value
function returnDbl = processInt16(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==4
        % Convert hex to decimal, cast to uint8, then interperate as int8
        % Scale given the b number (this assumes the bNum will be between 0
        % and 15)
        returnDbl = double(typecast(uint16(hex2dec2(hexString)),'int16')) / 2^(15-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 4 characters in length.');
    end
end

% Convert 8 hex characters into a properly scaled int32 value
function returnDbl = processInt32(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==8
        % Convert hex to decimal, cast to uint8, then interperate as int8
        % Scale given the b number (this assumes the bNum will be between 0
        % and 31)
        returnDbl = double(typecast(uint32(hex2dec2(hexString)),'int32')) / 2^(31-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 8 characters in length.');
    end
end

% Convert 2 hex characters into a properly scaled uint8 value
function returnDbl = processUint8(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==2
        % Convert hex to decimal (only this is needed for uint* data types
        % Scale given the b number (this assumes the bNum will be between 0
        % and 8)
        returnDbl = hex2dec2(hexString) / 2^(8-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 2 characters in length.');
    end
end

% Convert 4 hex characters into a properly scaled uint16 value
function returnDbl = processUint16(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==4
        % Convert hex to decimal (only this is needed for uint* data types
        % Scale given the b number (this assumes the bNum will be between 0
        % and 16)
        returnDbl = hex2dec2(hexString) / 2^(16-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 4 characters in length.');
    end
end

% Convert 8 hex characters into a properly scaled uint32 value
function returnDbl = processUint32(hexString, bNum)
    % Check that the correct number of hex characters were passed in
    if length(hexString)==8
        % Convert hex to decimal (only this is needed for uint* data types
        % Scale given the b number (this assumes the bNum will be between 0
        % and 8)
        returnDbl = hex2dec2(hexString) / 2^(32-bNum);
    else % Throw an exception
        error('CapabilityUploader:hex2scaled:invalidDataLength', 'Hex String was not 8 characters in length.');
    end
end

%% Untilities

% Function to check if the individual characters of the input string are
% 0-9, a-f, or A-F only.
function result = ishexchars(hexString)
    % Pre-set result to true, innocent until proven guilty
    result = true;
    % Look through every character to ensure that it's a hex value
    for i = 1:length(hexString)
        % If a wrong character is found, set result to false and exit the loop
        if sum(hexString(i)=='abcdefABCDEF0123456789')~=1
            % Proven guilty
            % Return false
            result = false;
            % Break out of the loop
            break
        end
    end
end

%% Antiquated Code - Saved for Later

% Old revision of this fcn that has too much error checking
function returnDbl = processInt8Old(hexString, flag, varargin)
    % Check the input data values
    % If this is event driven data, chop the last characters
    if flag
        goodData = hexString(1:2);
    else % This is MinMax data, make sure the first six characters are 0
        for i = 1:6
            if hexString(i)~='0'
                error('CapabilityUploader:hex2scaled - MinMax data - more signifigant bits have been passed in than datatype specifies.')
            end
        end
        % No errors, set digits
        goodData = hexString(7:8);
    end
    
    % Take the stripped out hex characters and scale them properly
    % If a bNum was specified
    if nargin == 3
        bNum = varargin{1};
        % If the bNum is valid
        if bNum <= 7 && bNum >= 0
            % Convert
            returnDbl = double(typecast(uint8(hex2dec(goodData)),'int8')) / 2^(7-bNum);
        else % Throw an error
            error('CapabilityUploader:hex2scaled - B Number of must be between 0 and 7 for datatype int8.')
        end
    else
        % There is no bNum, just do a raw conversion
        returnDbl = double(typecast(uint8(hex2dec(goodData)),'int8'));
    end
end
