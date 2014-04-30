function fc = getFC(obj, SEID)
% Finds the FC of the specified system error id
%   Use this to return the fault code of the specified system error id in the newest 
%   error_table
%   
%   Usage: fc = getFC(obj, SEID)
%   
%   Original Version - Chris Remington - October 16, 2012
%   Revised - Chris Remington - April 14, 2014
%     - If no fault code is mapped to the system error (i.e. the fault code column is NaN)
%       then return an empty set
    
    % Check the input
    if ~isnumeric(SEID) || length(SEID)~=1
        % Throw an error
        error('Capability:getFC:InvalidInput','Input must be a 1x1 numeric system error id as listed in the error_table.')
    end
    
    % Find a match for the specified SEID
    idx = obj.seInfo.SEID==SEID;
    
    % If there was one match
    if sum(idx)==1
        % Return the match
        fc = obj.seInfo.FaultCode(idx);
    else
        % Throw an error
        error('Capability:getFC:MatchError', 'Either there was no match or too many matchs for SEID %.0f.', SEID);
    end
    
    % If the FC returned was a NaN (i.e. null)
    if isnan(fc)
        % Set it to an empty set
        fc = [];
    end
    
end
