function decodedData = decodeEvent(obj, xSEID, data, cal)
%Given xSEID and hex string, return the scaled value as a double
%   This function is designed to be used to decode event driven data. It
%   will take in the raw hex string and xSEID that comes home in the .csv
%   files, will look-up what specific parameter is broadcast and how to
%   decode it, and will then send it to hex2scaled to decode and scale it.
%   
%   Usage: decodedData = decodeEvent(obj, xSEID, data, cal)
%   
%   Inputs ---
%   xSEID: This is the extended SEID broadcast which is SEID + ExtID * 2^16
%   data:  Hex string of the raw data as broadcast or an unsigned 
%          numerical representation of the hexadecimal data
%   cal:   Numeric value of the calibration version
%   
%   Outputs--- Properly decoded and scaled value
%   
%   Cal is currently unused due to the fact that I've simplified the event
%   driven parameter list to assume it will remain constant over calibrations
%   
%   Original Version - Chris Remington - January 23, 2012
%   Revised - Chris Remington - January 31, 2012
%       - Revised errors thrown slightly to align with newer version of
%         other files
%   Revised - Chris Remington - August 29, 2012
%       - Change to allow a numerical value to be placed in place of hex 
%         string in order to more easily support decoding CANape data that
%         arrives already converted from hexadecimal to decimal
%   Revised - Chris Remington - April 3, 2014
%       - Added byte-swapping for little-endian ECMs
%   Revised - Yiyuan Chen - 2014/07/28
%     - Added 4 array datatypes to process (array parameters with only 1 element)
    
    % If the input was a single number
    if isnumeric(data) && length(data)==1
        % Convert the data value back into hex for legacy purposes of the decoding code
        hexString = dec2hex(data);
        % Force it to be 8 characters long (pad front with zeros)
        hexString = [repmat('0',1,8-length(hexString)) hexString];
    % Elseif the input was a 8 character array
    elseif ischar(data) && length(data)==8
        % Just use this data as-is
        hexString = data;
    else
        % There was invalid input
        error('CapabilityUploader:decodeEvent:WrongStringLength', ...
            'data must be a character array that is 8 characters long or a 1x1 double representation of the data');
    end
    
    %% Get information on the Parameter for Specified xSEID
    % NOTE: This small section is analogous to the getDataInfo for MinMax data
    % First, check if this is one of the special event drvien parameters
    index = find(obj.evdd.xSEID==xSEID); % Is it faster to not use find here and just use the logical array?
    % Lookup the datatype of this parameter
    dataType = obj.evdd.DataType{index};
    % Lookup the bNumber of this parameter
    bNumber = obj.evdd.BNumber(index);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Manual scaling factor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % In the future, if an event driven parameter needs a manual scaling factor it would %
    % be best to add that as a column to the evdd and then have this function take that  %
    % into account                                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Manual scaling factor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Check that there was eactly one match, otherwise throw an error
    if length(bNumber)~=1
        error('CapabilityUploader:decodeEvent:MissingxSEID', ...
            ['Event Parameter List Problem - Found ' sprintf('%.0f',length(bNumber)) ...
            ' matches for xSEID ' sprintf('%.0f',xSEID) ' - Cal was ' sprintf('%.0f',cal) ...
            ' with a datastring of ' hexString]);
    end
    
    %% Send the data into the decoder depending on the datatype and ECM type
    % This will pick of the proper number of characters to feed into the
    % hex2scaled function (because we get 32-bits whether they're junk or not)
    % These are ordered in order of popularity to speed-up pace through the switch
    
    % If it was a little-endian ECM
    if obj.littleendian
        switch dataType
            case 'float'
                % Do it as a float (use all 8 characters)
                decodedData = obj.hex2scaled(hexString([7 8 5 6 3 4 1 2]), dataType);
            case {'int16', 'uint16', 'int16[]', 'uint16[]'}
                % 16-bit parameter (use fisrt 4 characters)
                decodedData = obj.hex2scaled(hexString([3 4 1 2]), dataType, bNumber);
            case {'int8', 'uint8', 'bool', 'boolean', 'int8[]', 'uint8[]'}
                % 8-bit parameter or boolean (use fisrt 2 characters)
                decodedData = obj.hex2scaled(hexString([1 2]), dataType, bNumber);
            case {'int32', 'uint32', 'int32[]', 'uint32[]'}
                % 32-bit parameter (use all 8 characters)
                decodedData = obj.hex2scaled(hexString([7 8 5 6 3 4 1 2]), dataType, bNumber);
            otherwise
                % Unknown datatype - throw an error
                error('CapabilityUploader:decodeEvent:UnknownDataType', ...
                    'Unknown data type ''%s'' encountered in decodeEvent for xSEID %.0f and cal %.0f',...
                    dataType,xSEID,cal);
        end
    else % Do it for a big-endian ECM
        switch dataType
            case 'float'
                % Do it as a float (use all 8 characters)
                decodedData = obj.hex2scaled(hexString(1:8), dataType);
            case {'int16', 'uint16', 'int16[]', 'uint16[]'}
                % 16-bit parameter (use fisrt 4 characters)
                decodedData = obj.hex2scaled(hexString(1:4), dataType, bNumber);
            case {'int8', 'uint8', 'bool', 'boolean', 'int8[]', 'uint8[]'}
                % 8-bit parameter or boolean (use fisrt 2 characters)
                decodedData = obj.hex2scaled(hexString(1:2), dataType, bNumber);
            case {'int32', 'uint32', 'int32[]', 'uint32[]'}
                % 32-bit parameter (use all 8 characters)
                decodedData = obj.hex2scaled(hexString(1:8), dataType, bNumber);
            otherwise
                % Unknown datatype - throw an error
                error('CapabilityUploader:decodeEvent:UnknownDataType', ...
                    'Unknown data type ''%s'' encountered in decodeEvent for xSEID %.0f and cal %.0f',...
                    dataType,xSEID,cal);
        end
    end
end
