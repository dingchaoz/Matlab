function numRows = getNumDIBParameters(obj, cal)
%Returns the number of parameters present for a given calibration version
%   Counts the number of rows in table tblDataInBuild and returns
%   the result. This can also be used to check if an error_table for a
%   specified software version already exists in the database.
%   
%   Input---  Calibration version (either number, string-number, or dot string)
%   
%   Output--- Numeric row count
%   
%   Original Version - Chris Remington - January 10, 2012
%   Revised - Chris Remington - July 12, 2013
%     - Modified to remove the check for a 6 digit calibration version as this was only
%       applicable to Pacific is and is not really needed
    
    % If the input is a string, exaluate it
    if ischar(cal)
        % Look for dots (if it's dot notation or pure numeric)
        if sum(cal=='.') > 0
            % It's dot version, convert to cal number
            calNum = obj.dot2num(cal);
            % Reprint it in string format
            calString = sprintf('%.0f', calNum);
        % elseif It's a cal number in string format
        elseif length(cal) >= 6 && length(cal) <= 8 % Modified for 8 digit cal versions
            % Use the string like it is
            calString = cal;
        else
            % Throw an error, the string wasn't proper
            error('Capability:getNumDIBParameters - Bad calibration string specified.')
        end
    % otherwise, if a number was dropped in
    elseif isnumeric(cal)
        % It's a number, print the spring representation
        calString = sprintf('%.0f', cal);
    else
        % No valid input was specified, throw an error.
        error('Capability:getNumDIBParameters - Invalid calibration number specified.');
    end
    
    % With the input sorted, do the real work
    SQLStatement = ['SELECT Count([Data]) AS [RowCount] FROM tblDataInBuild WHERE Calibration = ', calString];
    % Execute the query and grab the data
    queryData = fetch(obj.conn, SQLStatement);
    % Set the return data
    numRows = queryData.RowCount;
    
end
