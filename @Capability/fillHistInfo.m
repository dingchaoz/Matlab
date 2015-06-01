function fillHistInfo(obj)
%Set the relevant field from the filt structure in the hist object
%   When called, this method will take the current settings of the filt structure
%   and fill them into the appropriate fields in the HistogramGenerator object.
%   
%   Usage: fillHistInfo(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for FC and new vehcile filtering
%   Revised - Dingchao Zhang - May 15, 2015
%     - Modified the MonthFilter display
    
    
    
    % Plot name
    obj.hist.SystemErrorName = obj.filt.Name;
    % System Error ID
    obj.hist.SEID = obj.filt.SEID;
    % Fault Code
    obj.hist.FC = obj.filt.FC;
    % Program Name
    obj.hist.Program = obj.plotProgramName;
    % Parameter Name
    obj.hist.ParameterName = obj.filt.CriticalParam;
    % Parameter Units
    obj.hist.ParameterUnits = obj.filt.Units;
    % LSL Parameter Name
    obj.hist.LSLName = obj.filt.LSLName;
    % LSL Value
    obj.hist.LSL = obj.filt.LSL;
    % USL Parameter Name
    obj.hist.USLName = obj.filt.USLName;
    % USL Value
    obj.hist.USL = obj.filt.USL;
    % Software filtering
    obj.hist.SoftwareFilter = obj.filt.software;
    % Calculate the filtering strings that will get displayed
    obj.updateFilterStrings
    % Engine Family filter setting
    obj.hist.FamilyFilter = obj.filt.FamilyString;
    % Truck filter
    obj.hist.TruckFilter = obj.filt.TruckString;
    % Vehicle filter
    obj.hist.VehicleFilter = obj.filt.VehicleString;
    % Date filter
        % get the to datetime 
    to = datestr(obj.filt.date(:,2),' mmmm dd,yyyy,HH:MM:SS ');
    
    % if there is from datetime input
    if ~isnan(obj.filt.date(:,1))
      from = datestr(obj.filt.date(:,1),' mmmm dd,yyyy,HH:MM:SS ');  
      obj.hist.MonthFilter = strcat('From',from,' To',to);
    % otherwise just use up to
    else
      obj.hist.MonthFilter = strcat('Up to:',to); 
    %obj.box.MonthFilter = obj.filt.DateString;
    end
    %obj.hist.MonthFilter = obj.filt.DateString;
    
end
