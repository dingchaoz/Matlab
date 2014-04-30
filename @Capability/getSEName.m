function name = getSEName(obj, SEID)
%Returns the System Error name given the System Error ID number
%   Use to more easily connect the SEID and SE Name together
%   
%   Usage: name = getSEName(obj, SEID)
%   
%   Original Version - Chris Remington - March 28, 2012
%   Revised - N/A - N/A
    
    % Check the input argument
    if ~isnumeric(SEID) || length(SEID)~=1
        % Throw an error when they are invalid
        error('Capability:getSEName:InputError', 'SEID must be a 1x1 double.')
    end
    
    % Find a match for the specified SEID
    idx = obj.seInfo.SEID==SEID;
    
    % If there was one match
    if sum(idx)==1
        % Return the match
        name = obj.seInfo.SEName{idx};
    else
        % Throw an error
        error('Capability:getSEName:MatchError', 'Either there was no match or too many matchs for SEID %.0f.', SEID);
    end
    
end
