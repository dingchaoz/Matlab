function pdid = getPublicDataID(obj, paramName)
%Utility to find the newest public data id of a specified parameter
%   This function should be used to connect a parameter name to it's newest public data id
%   This function returns the public data id of the parameter in the newest software
%   version where the parameter was present.
%   
%   Usage: pdid = getPublicDataID(obj, paramName)
%   
%   Inputs ---
%   paramName: A string of the parameter name
%   
%   Outputs ---
%   pdid:      Value of the newest Public Data ID for the specified parameter
%   
%   Originial Version - Chris Remington - April 12, 2012
%   Revised - Chris Remington - April 7, 2014
%     - Moved to the use of tryfetch from just fetch to commonize error handling
%   Revised - Yiyuan Chen 2014/11/21
%     - Avoid the error of no data due to a different PublicID in 50997001 for some parameters 
%   Revised - Yiyuan Chen 2015/02/04
%     - Set the fake PublicDataID direcly to 999999 if the parameter is
%     the number of failed cylinders, for EQUALLY_FAILED_INJECTORS_ERROR
%   Revised - Deepika S Namboothiri, Yiyuan Chen 2015/10/02
%      Modified to extract all public data IDs for the same critical parameter

    % Check the input to the function
    if ~ischar(paramName)
        error('Capability:getPublicDataID:InvalidInput','Input to paramName must be a string');
    end
     
    if strcmp(paramName, 'EFI_Inj_Fail_Count')
        % Create a fake PublicDataID if the parameter is for EQUALLY_FAILED_INJECTORS_ERROR
        pdid = 999999;
        return
    else
        % For other normal parameters, look in the paramInfoCache first for a value if there is data present in it
        if ~isempty(obj.paramInfoCache.Data)
            % Find any values matching this parameter name
            % Do a non-case sensitive search in case the input is capitalized wrong
            % Additionally, the database doesn't do a case-sensitive match, so you can get
            % into an infinite loop where the paramInfoCache keeps growing because this misses
            % it and the database catches it and adds it to the cache
            idx = strcmpi(paramName, obj.paramInfoCache.Data);
            % If there were any matches
            if any(idx)
                % Return the largest Public Data ID match found
                pdid = obj.paramInfoCache.PublicDataID(idx);
                % Exit the function as there is no need to look in the database
                return
            end
        end
    end
    
    % There was no info in the paramInfoCache, look in the databse and update the cache 
    % accordingly

    % Formulate the sql query
    sql = ['SELECT [Data], [DataType], [Unit], [Min], [Max], [BNumber], [PublicDataID], ' ...
           '[Calibration] FROM [dbo].[tblDataInBuild] WHERE [Data] = ''' paramName ''''];
       
    % Use the common tryfetch method to handle re-connecting to the data-base upon error
    d = obj.tryfetch(sql);
    
    % If there was any data returned
    if ~isempty(d)
        % fetch the unique publicDataIDs only
        [pdid, idx, ~] = unique(d.PublicDataID);
        % Update all fields of the paramInfoCache
        obj.paramInfoCache.Data = [obj.paramInfoCache.Data d.Data(idx)'];
        obj.paramInfoCache.DataType = [obj.paramInfoCache.DataType d.DataType(idx)'];
        obj.paramInfoCache.Unit = [obj.paramInfoCache.Unit d.Unit(idx)'];
        obj.paramInfoCache.Min = [obj.paramInfoCache.Min d.Min(idx)'];
        obj.paramInfoCache.Max = [obj.paramInfoCache.Max d.Max(idx)'];
        obj.paramInfoCache.BNumber = [obj.paramInfoCache.BNumber d.BNumber(idx)'];
        obj.paramInfoCache.PublicDataID = [obj.paramInfoCache.PublicDataID d.PublicDataID(idx)'];
        obj.paramInfoCache.Calibration = [obj.paramInfoCache.Calibration d.Calibration(idx)'];
    else
        % There was no match, throw an error
        error('Capability:getPublicDataID:NoMatch', 'The parameter %s was not found in the database', paramName);
    end
end
