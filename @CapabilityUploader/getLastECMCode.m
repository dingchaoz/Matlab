function ECMCode = getLastECMCode(obj, truck)
%Returns the last known _ECM_Code of the truck specified by truck id or name
%   Returns the last known _ECM_Code of the truck specified by truck id or name.
%   Input can either be a string that is a truck name or a truckID number
%   
%   Usage: calRev = GetLastECMCode(obj, truck)
%   
%   Inputs---
%   truck:    Either a string with a truck name or a truckID number from the database
%   
%   Outputs---
%   ECMCode:  Revision of the last know cal in the truck
%   
%   Original Verison - Chris Remington - June 7, 2013
%   Revised - N/A - N/A
    
    % Check the input format
    if ischar(truck)
        % Find out the truck id for this truck name
        truckID = obj.getTruckID(truck);
    elseif isnumeric(truck)
        % Capture truck as the truckID
        truckID = truck;
    else
        error('CapabilityUploader:getLastECMCode:InvalidInput','Input must either be a string with a singe truck name or a numeric truck ID number from the database.');
    end
    
    % Always reference the database for the most up to date information
    data = fetch(obj.conn, sprintf('SELECT [ECMCode] FROM [dbo].[tblTrucks] WHERE [TruckID] = %.0f',truckID));
    % If no data was returned
    if isempty(data)
        % Throw an error, if you got a truck id, data should be returned
        error('You shouldn''t be able to get to this error.')
    else
        % Set the output to the ECMCode in the database
        ECMCode = data.ECMCode{1};
    end
    
end
