function processData = getTruckProcessData(obj,truckID)
%Returns truck engine given a truckID as input
%   
%   Usage: processData = getTruckProcessData(obj,truckID)
%   
%   Input---  Numeric TruckID (same as stored in the database)
%   
%   Output--- 0 or 1 if the data should be processed for this vehicle
%   
%   Throws an error on failure to find truck in database
%   
%   Original Version - Chris Remington - January 16, 2011
%   Revised - Chris Remington - May 24, 2013
%     - Updated error names thrown
%     - Revised to use the newer tblTruck cache with software and truck definitions
%       combind together instead of the separaete software and truck name definitions
%   Adapted - Chris Remington - October 10, 2013
%     - Simply hacked to get this to work, doesn't function like it's sister funcitons
%       getTruck... functions
    
    if ~isnumeric(truckID) || length(truckID) ~= 1
        % Throw an error
        error('Capability:getTruckProcessData:InvalidInput','Input must be a scalar number.')
    else
        % Fetch data from the database
        data = fetch(obj.conn,sprintf('SELECT [ProcessData] FROM [dbo].[tblTrucks] WHERE [TruckID] = %.0f',truckID));
        
        % If nothing was returned, throw an error
        if isempty(data)
            % Throw an error
            error('Capability:getTruckProcessData:NoMatch','Couldn''t find a match for specified truckID: %.0f',truckID);
        else
            processData = data.ProcessData{1};
        end
    end
    
end
