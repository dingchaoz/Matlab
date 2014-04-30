function reset(obj)
%Reset all internal properties of this object to empty sets
%   This will reset all the properties back to empty so that a stray value
%   donesn't get kept and plotted with a new dataset. This can also be used
%   to save memory after a plot has been generated
%   
%   Usage: reset(obj)
%   
%   Inputs - None
%   Outputs - None
%   
%   Original Version - Chris Remington - April 11, 2012
%   Revised - N/A - N/A
    
    % Set these properties back to an empty set
    obj.SEID = [];
    obj.SystemErrorName = [];
    obj.ParameterName = [];
    obj.ParameterUnits = [];
    obj.DataType = [];
    obj.FC = [];
    obj.Program = [];
    obj.TruckFilter = [];
    obj.FamilyFilter = [];
    obj.MonthFilter = [];
    obj.SoftwareFilter = [];
    obj.VehicleFilter = [];
%     obj.LSL = [];
%     obj.LSLName = [];
%     obj.USL = [];
%     obj.USLName = [];
%     obj.Data = [];
%     obj.GroupData = [];
    obj.Labels = [];
%     obj.GroupOrder = [];
    obj.PpK = [];
    obj.TimePeriod = [];
    obj.DataPoints = [];
    obj.FailureDataPoints = [];
    obj.TruckName = [];
    obj.CalibrationVersion = [];
    obj.StartDateStr = [];
    obj.EndDateStr = [];
    
end
