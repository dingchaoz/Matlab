function pcode = getPcode(obj, SEID)
% Finds the P-code of the specified system error id
%   Use this to return the p-code of the specified system error id in the newest 
%   error_table
%   
%   Usage: pcode = getPcode(obj, SEID)
%   
%   Original Version - Chris Remington - October 16, 2012
%   Revised - Chris Remington - March 25, 2014
%     - Adopted from getFC to instead get the P-code of the system error id
%   Revised - Chris Remington - April 14, 2014
%     - Return an empty string if the P-code is not mapped
    
    % Check the input
    if ~isnumeric(SEID) || length(SEID)~=1
        % Throw an error
        error('Capability:getPcode:InvalidInput','Input must be a 1x1 numeric system error id as listed in the error_table.')
    end
    
    % Find a match for the specified SEID
    idx = obj.seInfo.SEID==SEID;
    
    % If there was one match
    if sum(idx)==1
        % Return the match
        pcode = obj.seInfo.PCode{idx};
    else
        % Throw an error
        error('Capability:getPcode:MatchError', 'Either there was no match or too many matchs for SEID %.0f.', SEID);
    end
    
    % If the P-code was null
    if strcmp('null',pcode)
        % Set it to an empty string
        pcode = '';
    end
    
end
