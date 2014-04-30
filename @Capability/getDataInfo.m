function returnData = getDataInfo(obj, publicDataID, cal, fieldName)
%Returns a variable name given a Public Data ID and cal version
%   Use this to get the name of a variable given its public data id and the
%   version of software it is in.
%   
%   Inputs---
%   publicDataID: The Public Data ID of the parameter
%   cal:          The calibration version (in numeric format only)
%   fieldName:    Name of the field to return. Valid values are:
%                  'Data'                   - Returns the name of the parameter
%                  'DataType'               - Returns the data type of the parameter
%                  'Unit'                   - String of the unit value
%                  'Min'                    - String of min specified in the datainbuild.csv file
%                  'Max'                    - String of max specified in the datainbuild.csv file
%                  'BNumber'                - BNumber of the spedified parameter
%                  'ScalarToolUnitConv'     - ScalarToolUnitConv field in datainbuld.csv
%                  'ScalarOverrideToolUnit' - ScalarOverrideToolUnit in datainbuild.csv
%   
%   Outputs---    Value of 'fieldName' for the parameter specified
%   
%   Original Version - Chris Remington - January 11, 2012
%   Revised - Chris Remington - January 14, 2014
%     - Added ability to cache the ScalarToolUnitConv and ScalarOverrideToolUnit fields
    
    % If the parameter cache isn't empty
    if ~isempty(obj.paramInfoCache.PublicDataID)
        % Find the index of this parameter (if it is present for multiple
        % calibration versions, it will find more than one match)
        idxID = obj.paramInfoCache.PublicDataID==publicDataID;
        
        % Find the index of the specified calibration (this will filter
        % everything out what is only for the desired calibration)
        idxCal = obj.paramInfoCache.Calibration==cal;
        
        % If there was only one matching parameter meeting both criteria
        if sum(idxID & idxCal)==1
            % Return the name of the match
            % If the field is a cell array
            if iscell(obj.paramInfoCache.(fieldName))
                % Take the string out of the cell
                returnData = obj.paramInfoCache.(fieldName){idxID & idxCal};
            else
                % Just return the double
                returnData = obj.paramInfoCache.(fieldName)(idxID & idxCal);
            end
        elseif sum(idxID & idxCal) > 1
            % There were too many matches, throw an error
            error(['Capability:getDataInfo:MultipleEntires', ...
                'Multiple versions of parameter id ''' num2str(publicDataID) ...
                ''' for cal ''' num2str(cal) ''' were found in the parameter info cache']);
        else
            % There was no match, look in the database for a match
            returnData = updateParamInfoCache(obj, publicDataID, cal, fieldName);
        end
    else % Truck cache is empty, do it the hard way first
        returnData = updateParamInfoCache(obj, publicDataID, cal, fieldName);
    end
end
