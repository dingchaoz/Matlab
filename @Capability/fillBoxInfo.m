function fillBoxInfo(obj)
%Set the relevant field from the filt structure in the box object
%   When called, this method will take the current settings of the filt structure
%   and fill them into the appropriate fields in the BoxPlotGenerator object.
%   
%   Usage: fillBoxInfo(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 2, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for FC and new vehcile filtering
%   Revised - Dingchao Zhang - May 15, 2015
%     - Modified the MonthFilter display
    
    
    
    % Plot name
    obj.box.SystemErrorName = obj.filt.Name;
    % System Error ID
    obj.box.SEID = obj.filt.SEID;
    % Fault Code
    obj.box.FC = obj.filt.FC;
    % Program Name
    obj.box.Program = obj.plotProgramName;
    % Parameter Name
    obj.box.ParameterName = obj.filt.CriticalParam;
    % Parameter Units
    obj.box.ParameterUnits = obj.filt.Units;
    % LSL Parameter Name
    obj.box.LSLName = obj.filt.LSLName;
    % LSL Value
    obj.box.LSL = obj.filt.LSL;
    % USL Parameter Name
    obj.box.USLName = obj.filt.USLName;
    % USL Value
    obj.box.USL = obj.filt.USL;
    % Software filtering
    obj.box.SoftwareFilter = obj.filt.software;
    % Calculate the filtering strings that will get displayed
    obj.updateFilterStrings
    % Engine Family filter setting
    obj.box.FamilyFilter = obj.filt.FamilyString;
    % Truck filter
    obj.box.TruckFilter = obj.filt.TruckString;
    % Vehicle filter
    obj.box.VehicleFilter = obj.filt.VehicleString;
    % Date filter
    
    % get the to datetime 
    to = datestr(obj.filt.date(:,2),' mmmm dd,yyyy,HH:MM:SS ');
    
    % if there is from datetime input
    if ~isnan(obj.filt.date(:,1))
      from = datestr(obj.filt.date(:,1),' mmmm dd,yyyy,HH:MM:SS ');  
      obj.box.MonthFilter = strcat('From',from,' To',to);
    % otherwise just use up to
    else
      obj.box.MonthFilter = strcat('Up to:',to); 
    %obj.box.MonthFilter = obj.filt.DateString;
    end
    
end
