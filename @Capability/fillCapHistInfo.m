function fillCapHistInfo(obj)
%Set the relevant field from the filt structure in the caphist object
%   When called, this method will take the current settings of the filt structure
%   and fill them into the appropriate fields in the CapHistPlotGenerator object.
%   
%   Usage: fillCapHistInfo(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 2, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for FC and new vehcile filtering
    
    % Plot name
    obj.caphist.SystemErrorName = obj.filt.Name;
    % System Error ID
    obj.caphist.SEID = obj.filt.SEID;
    % Fault Code
    obj.caphist.FC = obj.filt.FC;
    % Program Name
    obj.caphist.Program = obj.plotProgramName;
    % Parameter Name
    obj.caphist.ParameterName = obj.filt.CriticalParam;
    % Parameter Units
    obj.caphist.ParameterUnits = obj.filt.Units;
    % LSL Parameter Name
%     obj.caphist.LSLName = obj.filt.LSLName;
    % LSL Value
%     obj.caphist.LSL = obj.filt.LSL;
%     % USL Parameter Name
%     obj.caphist.USLName = obj.filt.USLName;
%     % USL Value
%     obj.caphist.USL = obj.filt.USL;
    % Calculate the filtering strings that will get displayed
    obj.updateFilterStrings
    % Engine Family filter setting
    obj.caphist.FamilyFilter = obj.filt.FamilyString;
    % Truck filter
    obj.caphist.TruckFilter = obj.filt.TruckString;
    % Vehicle filter
    obj.caphist.VehicleFilter = obj.filt.VehicleString;
    % Date filter
    obj.caphist.MonthFilter = obj.filt.DateString;
    % Software filtering
    obj.caphist.SoftwareFilter = obj.filt.software;
    
end
