function data = getEvddInfo(obj, SEID, ExtID, field)
%Looks up an xSEID or SEID and ExtID combination and returns the specified information
%   Use as a utility function to look-up information about event driven parameters
%   
%   Usage:  .getEvddInfo(SEID, ExtID, field) - Use to specify individual SEID and ExtID
%           .getEvddInfo(xSEID, field)       - Use to specify a single xSEID
%   
%   Inputs -
%   SEID:   Either an SEID when specified with an ExtID, or an xSEID by itself
%   ExtID:  Optional, specify when putting the SEID into the SEID field
%   field:  Integer representing the desired information
%           0: Parameter Name
%           1: Parameter PublicDataID (if it exists)
%           2: Paramerer BNumber
%           3: Parameter data type
%           4: Parameter units
%   
%   Outputs -
%   data:   The requested data based on the field input (either a string or a double)
%   
%   Original Version - Chris Remington - March 27, 2012
%   Revised - Chris Remington - April 24, 2012
%       - Fixed the usage case when only specifying an xSEID and field
    
    % If ExtID wasn't specified (there are only two inputs, meaning that the ExtID is the
    % 'field' variable)
    if ~exist('field', 'var')
        % Assume that SEID is an xSEID
        xSEID = SEID;
        field = ExtID;
    else
        % Otherwise, calculate the xSEID
        xSEID = SEID + ExtID*65536;
    end
    
    % Try to look-up the value in the evdd
    idx = find(obj.evdd.xSEID==xSEID);
    
    if isempty(idx)
        % If there were no matches, throw an error
        error('Capability:getEvddInfo:NoMatch', 'No matches found for the calculated xSEID %0.f.', xSEID);
    elseif length(idx)>1
        % If there were too many matches, throw an error
        error('Capability:getEvddInfo:Duplicates', 'Too many matches found in the evdd database for xSEID %.0f.', xSEID);
    else
        % There was only one match, process based on field requested
        switch field
            case 0 % Return Parameter Name
                data = obj.evdd.Parameter{idx};
            case 1 % Return PablicDataID (stored as a NaN if it doesn't exist)
                data = obj.evdd.PublicDataID(idx);
            case 2 % Return parameter's b-number
                data = obj.evdd.BNumber(idx);
            case 3 % Return the Parameter's Data Type
                data = obj.evdd.DataType{idx};
            case 4 % Return the Parameter's units
                data = obj.evdd.Units{idx};
            otherwise % An unsupported field was passed in
                % Throw an error
                error('Capability:getEvddInfo:InvalidInput', 'Invalid input to "field" input; must be an integer between 0 and 4.');
        end
    end
end
