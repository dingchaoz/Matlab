function [datenumber, datestring] = getDateInfo(obj, s)
% Returns a long format date string and a datenum
%   Takes in a 6 digit string of the format yymmdd and will return both a Matlab
%   serial date number
%   
%   Usage: [datenum, datestring] = getDateInfo(s)
%   
%   Inputs ---
%   s:          6 character string representing a data in yymmdd format
%   
%   Outputs ---
%   datenumber: Matlab serial date number representing the date input
%   datestring: Long string version of the specified date
%   
%   Original Version - Chris Remington - September 28, 2012
%   Revised - Dingchao Zhang --May 15th, 2015 --Added to take 8,10,12 digit string
    
    % If no characters were passed in
    if isempty(s)
        % Set the datenum to a NaN
        datenumber = NaN;
        % Set the datestring to an empty string
        datestring = '';
    % Elseif 6 characters were passed in
    elseif length(s) == 6
        try
            % Try to convert to a date number
            datenumber = datenum(s,'yymmdd');
            % Get a formatted date string
            datestring = datestr(datenumber,'mmmm dd, yyyy HH:MM:SS');
        catch ex
            % Set the datenumber to a NaN as there was an error
            datenumber = NaN;
            % Set the datestring to a '' as there was an error
            datestring = '';
        end
    % Elseif 8 characters were passed in
    elseif length(s) == 8
        try
            % Try to convert to a date number
            datenumber = datenum(s,'yymmddHH');
            % Get a formatted date string
            datestring = datestr(datenumber,'mmmm dd, yyyy  HH:MM:SS');
        catch ex
            % Set the datenumber to a NaN as there was an error
            datenumber = NaN;
            % Set the datestring to a '' as there was an error
            datestring = '';
        end
    % Elseif 10 characters were passed in
    elseif length(s) == 10
        try
            % Try to convert to a date number
            datenumber = datenum(s,'yymmddHHMM');
            % Get a formatted date string
            datestring = datestr(datenumber,'mmmm dd, yyyy  HH:MM:SS');
        catch ex
            % Set the datenumber to a NaN as there was an error
            datenumber = NaN;
            % Set the datestring to a '' as there was an error
            datestring = '';
        end
    % Elseif 12 characters were passed in
    elseif length(s) == 12
        try
            % Try to convert to a date number
            datenumber = datenum(s,'yymmddHHMMSS');
            % Get a formatted date string
            datestring = datestr(datenumber,'mmmm dd, yyyy  HH:MM:SS');
        catch ex
            % Set the datenumber to a NaN as there was an error
            datenumber = NaN;
            % Set the datestring to a '' as there was an error
            datestring = '';
        end
    else % incorrect number of characters passed in
        % Set the datenumber to a NaN as there was an error
        datenumber = NaN;
        % Set the datestring to a ''
        datestring = '';
    end
end
