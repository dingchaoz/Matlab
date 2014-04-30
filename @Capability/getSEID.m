function id = getSEID(obj, SEName)
%Returns the System Error ID given the System Error name
%   Use to more easily connect the SEID and SE Name together
%   
%   Usage: id = getSEID(obj, SEName)
%   
%   Original Version - Chris Remington - March 28, 2012
%   Revised - N/A - N/A
    
    % Check that the input is a character string
    if ~ischar(SEName)
        error('Capability:getSEName:InputError', 'SEName must be a string.')
    end
    
    % Find a match for the specified SEID
    idx = strcmp(SEName, obj.seInfo.SEName);
    
    % If there was one match
    if sum(idx)==1
        % Return the match
        id = obj.seInfo.SEID(idx);
    else
        % Throw an error
        error('Capability:getSEName:MatchError', 'Either there was no match or too many matchs for system error "%s".', SEName);
    end
    
end
