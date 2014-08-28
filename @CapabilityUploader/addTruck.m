function truckID = addTruck(obj, truckName)
%Add a vehicle to the trucks table if it doesn't exist already
%   If a new folder is present for a new truck, this function can be used to add that 
%   vehicle name to the database so that the automated process can continue.
%   
%   If trucks are added erroneously (due to a mis-placed folder) they shouldn't have any
%   data to process so they should be able to be removed easily.
%   
%   Usage: truckID = addTruck(obj, truckName)
%   
%   Original Version - Chris Remington - December 5, 2013
%   Revised - Chris Remington - January 20, 2014
%     - Moved from the @IUPRUploader object to the @CapabilityUploader object and modified as
%       appropriate
%   Revised - Chris Remington - February 21, 2014
%     - Correctly handle situation where a truck is added for the first time to the table
%   Revised - Chris Remington - March 26, 2014
%     - Default the value of TruckType to Default from the previous behavior of null
%   Revised - Chris Remington - April 30, 2014
%     - Changed so this calculates the next largest truck id instead of relying on the 
%       identity column to calculate one for me
    
    % Check for valid input
    if ~ischar(truckName) || size(truckName,1) > 1
        % Throw an error
        error('CapabilityUploader:addTruck:InvalidInput','Invalid input, truckName must be a 1D character array.')
    end
    
    % Get the current largest truck id value
    fetchData = fetch(obj.conn, 'SELECT Max([TruckID]) As TruckID FROM [dbo].[tblTrucks]');
    
    % If no data was returned and this is the first data-set upload to the database
    if isempty(fetchData) || isnan(fetchData.TruckID)
        % Start the id number at 1
        truckID = 1;
    else
        % Add 1 to the existing largest truck id
        truckID = fetchData.TruckID + 1;
    end
    
    try
        % Insert the new vehicle into the tblTrucks table
        fastinsert(obj.conn, '[dbo].[tblTrucks]', ...
            {'TruckID','TruckName','Family','TruckType'}, ...
            {truckID,truckName,obj.program,'Default'})
    catch ex
        % If it was a duplicate truck error
        if ~isempty(strfind(ex.message,'Cannot insert duplicate key row in object'))
            % Catch the exception for index violation and send a more meaningful error
            error('CapabilityUploader:addTruck:Duplicate','The truck %s is already present in tblTrucks.',truckName)
        else
            % Rethrow the original exception
            rethrow(ex)
        end
    end
    
    % Update the truck id cache in the object
    obj.assignTruckData
    
end
