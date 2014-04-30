function truckName = getTruckName(obj,truckID)
%Returns truck name given a truckID as input
%   
%   Usage: truckRating = getTruckName(obj,truckID)
%   
%   Input -
%   truckID:   Numeric TruckID (same as stored in the database)
%   
%   Output -
%   truckName: String of the truck's name
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
        % Look up the truck internally
        % Find the index of the matching truck
        idxTruck = (obj.tblTrucks.TruckID == truckID);
    else
        % Throw an error because the truck wasn't found
        error('Capability:getTruckName:NotFound','TruckID %.0f was not found in the database',truckID)
    end
    
    % If there was one and only one match
    if sum(idxTruck) == 1
        % Return that match
        truckName = obj.tblTrucks.TruckName{idxTruck};
    else % There was no match or too many matches
        % Get a fresh copy of the truck listing from the database
        obj.assignTruckData
        % Find the index of the matching truck
        idxTruck = (obj.tblTrucks.TruckID == truckID);
        % If there was one and only one match
        if sum(idxTruck) == 1
            % Return that match
            truckName = obj.tblTrucks.TruckName{idxTruck};
        elseif sum(idxTruck) > 1
            % The truckID was found more than once, there is an error in the database
            error('Capability:getTruckName:TooManyMatches', 'More than one truck found with specified truckID: %.0f',truckID)
        else
            % Throw an error because the truck wasn't found in the original
            % cache or the updated cache
            error('Capability:getTruckName:NotFound','TruckID %.0f was not found in the database',truckID)
        end
    end
end
