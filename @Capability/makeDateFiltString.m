function s = makeDateFiltString(obj, d)
%Makes a string of the date filtering being used
%   This will generate a string from two matalb serial date numbers passed in that
%   represent the date filtering. d is a vector of length 2 with the from and to date
%   
%   Usage: s = makeDateFiltString(obj, d)
%   
%   Inputs -
%   d:       Numerical vector of length 2
%            [NaN NaN]       - indicates no filtering
%            [736432 NaN]    - indicated filtering from the first date only
%            [NaN 736432]    - indicates filtering up to the second date only
%            [736432 736435] - indicates filtering between the two dates specified
%   Outputs -
%   s:       String represnting the date filitering
%   
%   Original Version - Chris Remington - October 2, 2012
%   Revised - N/A - N/A
    
    % Error checking
    if length(d)~=2 || ~isnumeric(d)
        error('Capability:InvalidInput', 'Invalid input into makeDateFiltString');
    end
    
    % Define the date format string
    %dfs = 'mmmm dd, yyyy';
    dfs = 'mm/dd/yy';
    % If both are NaNs, then there is no date filtering
    if sum(isnan(d)) == 2
        s = 'None';
    % Elseif d(1)~=NaN and d(2)==NaN
    elseif ~isnan(d(1)) && isnan(d(2))
        % There is filtering from a date to the present
        s = sprintf('%s and later', datestr(d(1),dfs));
    elseif isnan(d(1)) && ~isnan(d(2))
        % There is filtering up to a certain date
        s = sprintf('Up to %s', datestr(d(2),dfs));
    else
        % There is filtering from and to a certain date
        s = sprintf('From %s to %s', datestr(d(1),dfs), datestr(d(2),dfs));
    end
end
