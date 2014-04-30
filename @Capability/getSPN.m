function spn = getSPN(obj, SEID)
% Finds the J1939 SPN of the specified system error id
%   Use this to return the SPN of the specified system error id in the newest 
%   error_table
%   
%   Usage: spn = getSPN(obj, SEID)
%   
%   Original Version - Chris Remington - October 16, 2012
%   Revised - Chris Remington - April 14, 2014
%     - Adopted from getFC to instead get the SPN of the system error id
%   Revised - Chris Remington - April 14, 2014
%     - Return an empty set if the SPN is not mapped
    
    % Check the input
    if ~isnumeric(SEID) || length(SEID)~=1
        % Throw an error
        error('Capability:getSPN:InvalidInput','Input must be a 1x1 numeric system error id as listed in the error_table.')
    end
    
    % Find a match for the specified SEID
    idx = obj.seInfo.SEID==SEID;
    
    % If there was one match
    if sum(idx)==1
        % Return the match
        spn = obj.seInfo.J1939SPN(idx);
    else
        % Throw an error
        error('Capability:getSPN:MatchError', 'Either there was no match or too many matchs for SEID %.0f.', SEID);
    end
    
    % If the SPN was null
    if isnan(spn)
        % Set it to an empty set
        spn = [];
    end
    
end
