function calRev = getLastCalRev(obj, truck)
%Returns the last known cal rev of the truck specified by truck id or name
%   Returns the last known cal rev of the truck specified by truck id or name.
%   Input can either be a string that is a truck name or a truckID number
%   
%   Usage: calRev = GetLastCalRev(obj, truck)
%   
%   Inputs---
%   truck:    Either a string with a truck name or a truckID number from the database
%   
%   Outputs---
%   calRev:   Revision of the last know cal in the truck
%   
%   Original Verison - Chris Remington - May 24, 2013
%   Revised - N/A - N/A
    
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
    
    data = fetch(obj.conn, sprintf('SELECT [RevisionCache] FROM [dbo].[tblTrucks] WHERE [TruckID] = %.0f',truckID));
    if isempty(data)
        error('You shouldn''t be able to get to this error.')
    else
        calRev = data.RevisionCache(1);
    end
    
%     % Try to find this truck in the current list
%     idxThisTruck = find(obj.tblTrucks.TruckID==truckID);
%     
%     % If the truck isn't found (either the list is empty or the truck isn't there)
%     if isempty(idxThisTruck)
%         % Return a NaN because the truck wasn't found
%         calRev = NaN;
%         % This shouldn't ever happen with the new way to store last software in the trucks
%         % table, but will keep it for error handling sake
%     % Else if there is one match for this truck 
%     elseif length(idxThisTruck)==1
%         % Return the value of the truck
%         calRev = obj.tblTrucks.RevisionCache(idxThisTruck);
%     else
%         % The truck was duplicated in the list, return the value of the newest one
%         calRev = obj.tblTrucks.RevisionCache(idxThisTruck(end));
%         % Again, because this is now stored in the database, this is impossible, but will
%         % be left for error handling that may be needed
%     end
    
end
