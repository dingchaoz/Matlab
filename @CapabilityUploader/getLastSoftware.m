function software = getLastSoftware(obj, truck)
%Returns the last known software version of a truck given the truck ID
%   Sometimes Calterm doesn't log the header parameters in a .csv file, resulting in the
%   software version of a given csv file being unknown.
%   If a software version isn't present in a .csv file, this will allow the AddCSVFile
%   method to pull the last known software version that truck had and use that instead
%   
%   Usage: software = getLastSoftware(obj, truck)
%   
%   Inputs ---
%   truck:    Either a string with a truck name or a truckID number from the database
%   
%   Outputs---
%   software: Numeric version of the software last seen on the truck
%   
%   Original Version - Chris Remington - ???
%   Revised - Chris Remington - May 24, 2013
%     - Changed to use the database table to cache software and truck version instead of
%       the .mat file
%     - Added ability to enter either truck name or truckID to input and still get a
%       result
    
    % Check the input format
    if ischar(truck)
        % Find out the truck id for this truck name
        truckID = obj.getTruckID(truck);
    elseif isnumeric(truck)
        % Capture truck as the truckID
        truckID = truck;
    else
        error('CapabilityUploader:getLastCalRev:InvalidInput','Input must either be a string with a singe truck name or a numeric truck ID number from the database.');
    end
    
    %%% MODIFY TO ALWAYS REFERENCE THE DATABASE FOR THE MOST UPDATED VALUES
    data = fetch(obj.conn, sprintf('SELECT [SoftwareCache] FROM [dbo].[tblTrucks] WHERE [TruckID] = %.0f',truckID));
    if isempty(data)
        error('You shouldn''t be able to get to this error.')
    else
        software = data.SoftwareCache(1);
    end
    
%     % Try to find this truck in the current list
%     idxThisTruck = find(obj.tblTrucks.TruckID==truckID);
%     
%     % If the truck isn't found (either the list is empty or the truck isn't there)
%     if isempty(idxThisTruck)
%         % Return a NaN because the truck wasn't found
%         software = NaN;
%         % This shouldn't ever happen with the new way to store last software in the trucks
%         % table, but will keep it for error handling sake
%     % Else if there is one match for this truck 
%     elseif length(idxThisTruck)==1
%         % Return the value of the truck
%         software = obj.tblTrucks.SoftwareCache(idxThisTruck);
%     else
%         % The truck was duplicated in the list, return the value of the newest one
%         software = obj.tblTrucks.SoftwareCache(idxThisTruck(end));
%         % Again, because this is now stored in the database, this is impossible, but will
%         % be left for error handling that may be needed
%     end
    
end
