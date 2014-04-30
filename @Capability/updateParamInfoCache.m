function dbData = updateParamInfoCache(obj, publicDataID, cal, returnFieldName)
%Looks for a row in tblDataInBuild matching data id and cal, returns desired data
%   This function will look in the database for parameter information, add it
%   to the paramInfoCache, then return the originally sought-after piece of
%   information specified.
%   This is ment to only be called by internal functions ONLY.
%   
%   Input---
%   publicDataID:    Public Data ID of the parameter
%   cal:             Six digit numberic representation of the cal version
%   returnFieldName: Name of the column in tblDataInBuild that shuld be returned
%   
%   Output--- Entry in tblDataInBuild for column returnFieldName that matches the given id and cal
    
%   Original Version - Chris Remington - January 11, 2011
%   Revised - Chris Remington - January 14, 2014
%     - Added ability to cache the ScalarToolUnitConv and ScalarOverrideToolUnit fields
%   Revised - Chris Remington - April 7, 2014
%     - Moved the standardize using tryfetch in instance where we want to try to reconnect
%       to the database once if there was an error connecting
    
    % Query the database using tryfetch to reconnect if the connection was closed
    dbPull = obj.tryfetch(['SELECT [Data],[DataType],[Unit],[Min],[Max],[BNumber],[PublicDataID],[Calibration],[ScalarToolUnitConv],[ScalarOverrideToolUnit] '...
                                      'FROM [dbo].[tblDataInBuild] WHERE [PublicDataID] = ' num2str(publicDataID,'%.0f') ' And [Calibration] = ' num2str(cal,'%.0f')]);
    % Examine the result
    if isempty(dbPull)
        % Result was empty, throw an error because the parameter was not
        % found for the specified calibration version
        error('Capability:updateParamInfoCache:ParameterDoesNotExist', ['Could not find parameter with Public Data ID of ' num2str(publicDataID, '%.0f') ' for calibration ' num2str(cal, '%.0f')]);%%%%%%%%%%%%%%%
        
    elseif length(dbPull.Data)==1
        % If the pull resulted in only one parameter being found, add it to the cache
        obj.paramInfoCache.Data = [obj.paramInfoCache.Data dbPull.Data];
        obj.paramInfoCache.DataType = [obj.paramInfoCache.DataType dbPull.DataType];
        obj.paramInfoCache.Unit = [obj.paramInfoCache.Unit dbPull.Unit];
        obj.paramInfoCache.Min = [obj.paramInfoCache.Min dbPull.Min];
        obj.paramInfoCache.Max = [obj.paramInfoCache.Max dbPull.Max];
        obj.paramInfoCache.BNumber = [obj.paramInfoCache.BNumber dbPull.BNumber];
        obj.paramInfoCache.PublicDataID = [obj.paramInfoCache.PublicDataID dbPull.PublicDataID];
        obj.paramInfoCache.Calibration = [obj.paramInfoCache.Calibration dbPull.Calibration];
        obj.paramInfoCache.ScalarToolUnitConv = [obj.paramInfoCache.ScalarToolUnitConv dbPull.ScalarToolUnitConv];
        obj.paramInfoCache.ScalarOverrideToolUnit = [obj.paramInfoCache.ScalarOverrideToolUnit dbPull.ScalarOverrideToolUnit];
        % Return the specified column of data (this uses dynamic field
        % names to access the fields in the structure)
        dbData = dbPull.(returnFieldName);
        % If a string is in a cell, return a string only
        if iscell(dbData)
            dbData = dbData{1};
        end
        
    elseif length(dbPull.Data) > 1
        % Too many mayches were found
        error(['Capability:updateParamInfoCache:multipleParametersFound', 'More than one parameter found with Public Data ID of ' num2str(publicDataID, '%.0f') ' for calibration ' num2str(cal, '%.0f')]);
        
    else % HOW DID I GET HERE? -- good to keep
        % Throw an error because no matches were found
        error(['Capability:updateParamInfoCache:ParameterDoesNotExist2', 'Could not find parameter with Public Data ID of ' num2str(publicDataID, '%.0f') ' for calibration ' num2str(cal, '%.0f')]);
    end
end
