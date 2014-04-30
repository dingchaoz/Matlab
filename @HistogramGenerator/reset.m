function reset(obj)
%Resets all value of HistogramGenerator back to their default value
%   This is used to both save memory after a plot has been generated and makes sure that
%   values won't become stale if they haven't been updated between calls to makePlot
%   
%   Usage: reset(obj)
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - N/A - N/A
    
%   Set each of these properties back to an empty set
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
    obj.LSL = [];
    obj.LSLName = [];
    obj.USL = [];
    obj.USLName = [];
    obj.Data = [];
    obj.Dist = [];
    obj.c = [];
    
end
