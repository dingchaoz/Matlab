function truckID = getTruckID(obj,truckName)
%Returns truck id given a truck name as an input
%   
%   Usage: truckID = getTruckID(obj,truckName)
%   
%   Input -
%   truckName: Truck Name
%   
%   Output -
%   truckID:   Truck ID number
%   
%   Original Version - Chris Remington - January 10, 2011
%   Revised - Chris Remington - May 24, 2013
%     - Updated error names thrown
%     - Revised to use the newer tblTruck cache with software and truck definitions
%       combind together instead of the separaete software and truck name definitions
%   Revised - Chris Remington - February 21, 2014
%     - Added better error handling for when there are initally no vehicles in the trucks
%       table
    
    if ~isempty(obj.tblTrucks)
        % Compare the input string to the string of all trucks with
        % known truck IDs
        idxTruck = strcmp(truckName, obj.tblTrucks.TruckName);
    else
        % Throw an error because the truck wasn't found
        error('Capability:getTruckID:NoMatch', 'Couldn''t find the truckID for truck: %s',truckName);
    end
    
    % If the supplied string matches one and only one string in the database
    if sum(idxTruck) == 1
        % Set the return value to the proper TruckID for that truck
        truckID = obj.tblTrucks.TruckID(idxTruck);
    else % There was no match or there were too many matches
        % Get a fresh copy of the truck listing from the database
        obj.assignTruckData
        % Compare the input string to the string of all trucks with known truck IDs
        idxTruck = strcmp(truckName, obj.tblTrucks.TruckName);
        % If the supplied string matches one and only one string in the database
        if sum(idxTruck) == 1
            % Set the return value to the proper TruckID for that truck
            truckID = obj.tblTrucks.TruckID(idxTruck);
        elseif sum(idxTruck) > 1
            % Throw an error because too many trucks were found
            error('Capability:getTruckID:TooManyMatches', 'Database error. Truck %s was found more than once.',truckName);
        else
            % Throw an error because the truck wasn't found in the original
            % cache or the updated cache
            error('Capability:getTruckID:NoMatch', 'Couldn''t find the truckID for truck: %s',truckName);
        end
    end
end
