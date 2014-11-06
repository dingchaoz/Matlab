function decodedData = decodeMinMax(obj, publicDataID, data, cal)
%Given a Public Data ID and hex string, return the scaled value as a double
%   This function is designed to be used to decode MinMax data. It will
%   take in the raw hex string and Public Data ID that comes home in the
%   .csv files, will look-up what specific parameter is broadcast and how
%   to decode it, and then sends it to hex2scaled to decode and scale it.
%   
%   Usage: decodedData = decodeMinMax(obj, publicDataID, data, cal)
%   
%   Inputs ---
%   publicDataID: This is the Public Data ID broadcast
%   data:         The hex string of the raw data as broadcast or an unsigned
%                 numerical representation of the hexadecimal data
%   cal:          Numeric value of the calibration version
%   
%   Outputs--- 
%   dacodedData:  Properly decoded and scaled value
%   
%   Original Version - Chris Remington - January 23, 2012
%   Revised - Chris Remington - January 31, 2012
%     - Added error handeling for when the data is 'AAAAAAAA' and the
%       public data id was not found for a given cal version, return a NaN
%       so that a null will be inserted into the database
%     - Also added some checking logic to ensure there wasn't either a
%       missing datainbuild for this software of possibly missing
%       information from a datainbuild that is present
%   Revised - Chris Remington - March 19, 2012
%     - Added support for B10 data type (int16 with b-number of 10)
%   Revised - Chris Remington - May 4, 2012
%     - Added manual specifications for scalar decoding units to several parameters
%   Revised - Chris Remington - August 29, 2012
%     - Change to allow a numerical value to be placed in place of hex 
%       string in order to more easily support decoding CANape data that
%       arrives already converted from hexadecimal to decimal
%   Revised - Chris Remington - January 10, 2014
%     - Added support for B7 data type (int16 with b-number of 8)
%   Revised - Chris Remington - January 14, 2014
%     - Added support for the [ScalarOverrideToolUnit] and [ScalarToolUnitConv] fields in
%       [dbo].[tblDataInBuild] so that all manual scaling factors are accounted for in an
%       easier to maintain and less failure prone method using datainbuild.csv from C2ST
%   Revised - Chris Remington - February 13, 2014
%     - Added support for EB16
%     - Should really add ability to support all Bxx and EBxx data type as they keep
%       poping up
%   Revsied - Chris Remingotn - April 3, 2014
%     - Added byte swapping for little-endian ECMs
%   Revised - Chris Remington - April 14, 2014
%     - Revised to add proper handling of scaling all B- and EB- data types
%       (B0 through B15 and EB0 through EB31)
%     - PRCR 235072 filed for 'V_USM_pc_PwrCtrlPWM_Val' which is the only known parameter
%       that the new B- and EB- data type decoding won't work for (but it will decode the
%       data exactly like Calterm would so this is acceptable until the PRCR is completed)
%   Revised - Yiyuan Chen - 2014/07/28
%     - Added 4 array datatypes to process (array parameters with only 1 element)
    
    %% Input Checking
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
        error('CapabilityUploader:decodeMinMax:WrongStringLength', ...
            'data must be a character array that is 8 characters long or an unsigned numerical representation of the data');
    end
    
    %% Little Endian Check Goes Here
    % Need to consider how to account for if the CANape data is done using a .dbc defined
    % as big vs. little endian which could effect if that is converted back into a HEX
    % number
    
    % If this is a little-endian ECM
    if obj.littleendian
        % Byte swap the whole data field, then the output is equivalent to a big-endian ECM
        hexString = hexString([7 8 5 6 3 4 1 2]);
    end
    
    %% Get Information on Parameter
    try 
        % Get the data type for the parameter
        dataType = obj.getDataInfo(publicDataID, cal, 'DataType');
        % Get the b-number for the parameter
        bNumber = obj.getDataInfo(publicDataID, cal, 'BNumber');
        % Get the Scalar_Override_Tool_Unit for the parameter
        unitConv = obj.getDataInfo(publicDataID, cal, 'ScalarToolUnitConv');
        % Get the Scalar_Tool_Unit_Conv for the parameter
        convOvr = obj.getDataInfo(publicDataID, cal, 'ScalarOverrideToolUnit');
    catch ex % Error handling
        % If the exception is a 'Parameter does not exist exception'
        % handle it
        if strcmp(ex.identifier, 'Capability:updateParamInfoCache:ParameterDoesNotExist')
            % If the datainbuild for this calibration exists
            if obj.getNumDIBParameters(cal) > 0
                if strcmp(hexString, 'AAAAAAAA')
                    % Set the decoded data to a NaN
                    decodedData = NaN;
                    % Write a line to the log file
                    %obj.error.write(['Encountered an AAAAAAAA parameter with PublicDataID ' ...
                    %    sprintf('%.0f',publicDataID) ' for cal ' sprintf('%.0f',cal) ' - setting to NaN']);
                    %obj.warning.write(['Encountered an AAAAAAAA parameter with PublicDataID ' ...
                    %    sprintf('%.0f',publicDataID) ' for cal ' sprintf('%.0f',cal) ' - setting to NaN']);
                    obj.event.write(['Encountered an AAAAAAAA parameter with PublicDataID ' ...
                        sprintf('%.0f',publicDataID) ' for cal ' sprintf('%.0f',cal) ' - setting to NaN']);
                    % Exit the function, don't call hex2scaled
                    return
                else
                    % Parameter can't be found in datainbuild but
                    % actually broadcast a real value, possible corrupt
                    % datainbuild of wrong cal version specified
                    % Set the decoded data to a NaN
                    decodedData = NaN;
                    obj.event.write(['CapabilityUploader:decodeMinMax:PossibleCorruptDataInBuild', ...
                        'Parameter of Public Data ID ' sprintf('%.0f ', publicDataID) ...
                        'with cal version specified of ' sprintf('%.0f ', cal) ...
                        'had non-AAAAAAAA data but could still not be located '...
                        'in the database - Possiblly the datainbuild table is missing information '...
                        'or the wrong calibration version was specified. - setting to NaN']);
                    return
                end
            else % Otherwise there is not a datainbuild for this cal
                % Throw an error notifying of this condition
                error('CapabilityUploader:decodeMinMax:DataInBuildMissing', ...
                    ['The datainbuild table for calibration ' sprintf('%.0f',cal) ' is missing from the database']);
            end
        else
            % Exception can't be handled, retorw the original
            rethrow(ex)
        end
    end
    
    %% B- and EB- Datatypes
    % If this is a B- data type that starts with an upper-case 'B'
    if strncmp('B',dataType,1)
        % Set the datatype to be int16
        dataType = 'int16';
    % Elseif this is an EB- data type that starts with an upper-case 'EB'
    elseif strncmp('EB',dataType,1)
        % Set the datatype to be int32
        dataType = 'int32';
    end
    
    %% Calculate Manual Scaling Factor Beyond the B-Number
    % Logic summary:
    % -- If ScalarOverrideToolUnit is not a NaN / null, it will be the ruling force in
    % scaling the data and over-ride the b-number and ScalarToolUnitConv field
    % -- If a ScalarToolUnitConv field is present without ScalarOverrideToolUnit, it will 
    % be used in addition to the b-number to scale the data
    % -- Otherwise f will just simply be 1 so it doesn't effect anything
    
    % If the override value is not null / NaN
    if ~isnan(convOvr)
        % Set the scaling factor
        f = convOvr;
        % Set the b-number back to something benign so it doesn't effect scaling
        % This is a little wonkey but was easiest to do in the existing code
        switch dataType
            case {'int8', 'int8[ ]'},    bNumber = 7; % Also process array parameters with only 1 element
            case {'uint8', 'uint8[ ]'},   bNumber = 8; % Also process array parameters with only 1 element
            case 'bool',    bNumber = 8;
            case 'boolean', bNumber = 8;
            case {'int16', 'int16[ ]'},   bNumber = 15; % Also process array parameters with only 1 element
            case {'uint16', 'uint16[ ]'},  bNumber = 16; % Also process array parameters with only 1 element
            case {'int32', 'int32[ ]'},   bNumber = 31; % Also process array parameters with only 1 element
            case {'uint32', 'uint32[ ]'},  bNumber = 32; % Also process array parameters with only 1 element
            case 'float',   bNumber = 16; % Doesn't matter but prevent the error below
            otherwise
                % Unknown datatype - throw an error
                error('CapabilityUploader:decodeMinMax:UnknownDataType', ...
                    ['Unknown data type encountered in decodeMinMax for PublicDataID ' ...
                    sprintf('%.0f',publicDataID) ' and cal ' sprintf('%.0f', cal) ...
                    ' when trying to account for an override scaling factor.']);
        end
    % Elseif the unit conversion is not null / NaN
    elseif ~isnan(unitConv) % and convOvr must be a NaN
        % Use the value specified in datainbuild.csv (which may be a 1)
        f = unitConv;
    else % otherwise both must be values of NaN
        % Just set it to 1 so it will have no effect below
        f = 1;
    end
    
    %% Send the data into the decoder depending on the datatype / b-number
    % This will pick of the proper number of characters to feed into the
    % hex2scaled function. For MinMax, this is the last X characters of the
    % string. These are put in order of frequance to speed time through
    % switch
    switch dataType
        case 'float'
            % Do it as a float (use all 8 characters)
            decodedData = obj.hex2scaled(hexString, dataType)*f;
        case {'int16', 'uint16', 'int16[ ]', 'uint16[ ]'}
            % 16-bit parameter (use last 4 characters)
            decodedData = obj.hex2scaled(hexString(5:8), dataType, bNumber)*f;
        case {'int32', 'uint32', 'int32[ ]', 'uint32[ ]'}
            % 32-bit parameter (use all 8 characters)
            decodedData = obj.hex2scaled(hexString(1:8), dataType, bNumber)*f;
        case {'int8', 'uint8', 'bool', 'boolean', 'int8[ ]', 'uint8[ ]'}
            % 8-bit parameter or boolean (use last 2 characters)
            decodedData = obj.hex2scaled(hexString(7:8), dataType, bNumber)*f;
        case {'sync_states_t', 'es_health_t'}
            % Process is as a unit8 with a bNum of 8 (use last 2 characters)
            decodedData = obj.hex2scaled(hexString(7:8), 'uint8', 8)*f;
        otherwise
            % Unknown datatype - throw an error
            error('CapabilityUploader:decodeMinMax:UnknownDataType',...
                'Unknown data type ''%s'' encountered in decodeMinMax for PublicDataID %.0f and cal %.0f',...
                dataType,publicDataID,cal);
    end
end
