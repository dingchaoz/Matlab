function updateFilterStrings(obj)
%Calculate the display strings on the plots for truck, family, truck type, and date
%   Moved this code from the GUI so the network plot generation code could use it
%   
%   Original Version - Chris Remington - March 28, 2014
%   Revised - N/A - N/A
    
    % Generate the date filtering string
    obj.filt.DateString = obj.makeDateFiltString([obj.filt.date(1) obj.filt.date(2)-1]);
    
    % Suck out the vehicle filtering selection
    vehicle = obj.filt.vehicle;
    % If the user chose individual vehicles
    if obj.filt.byVehicle
        % Set the vehicle filtering string
        if length(vehicle) > 1
            % For multiple selection just note multiple
            obj.filt.VehicleString = 'Multiple';
        else
            % Keep the user selected engine family only
            obj.filt.VehicleString = vehicle{1};
        end
    else
        % Set the vehicle filtering string
        obj.filt.VehicleString = 'All';
    end
    
    % Suck out the engine family filtering
    engfam = obj.filt.engfam;
    % Set the filter string values for the family
    if any(strcmp('All',engfam))
        % If any were all note this
        obj.filt.FamilyString = 'All';
    elseif length(engfam) > 1
        % For multiple selection just note multiple
        obj.filt.FamilyString = 'Multiple';
    else
        % Keep the user selected engine family only
        obj.filt.FamilyString = engfam{1};
    end
    
    % Suck of the vehicle type filtering
    vehtype = obj.filt.vehtype;
    % Set the filter string values for the vehicle type
    if any(strcmp('All',vehtype))
        % If any were all note this
        obj.filt.TruckString = 'All';
    elseif length(vehtype) > 1
        % For multiple selection just note multiple
        obj.filt.TruckString = 'Multiple';
    else
        % Keep the user selected engine family only
        obj.filt.TruckString = vehtype{1};
    end
    
end
