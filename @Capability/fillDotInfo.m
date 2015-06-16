function fillDotInfo(obj)
%Set the relevant field from the filt structure in the dot object
%   When called, this method will take the current settings of the filt structure
%   and fill them into the appropriate fields in the DotPlotGenerator object.
%   
%   Usage: fillDotInfo(obj)
%   
%   Inputs - None
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 2, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for FC and new vehcile filtering
%   Revised - Chris Remingotn - March 20, 2014
%     - Merged Sri's functions for the dot plot into the main code
%   Revised - Dingchao Zhang - May 15, 2015
%     - Modified the MonthFilter display
%   Revised - Dingchao Zhang - May 29, 2015
%     - Added lines to pass by excluding a period of dates
%   Revised - Dingchao Zhang - June 4, 2015
%       - Added properties Fltplot to store the user input to apply fitler or not

    % Plot name
    obj.dot.SystemErrorName = obj.filt.Name;
    % System Error ID
    obj.dot.SEID = obj.filt.SEID;
    % Fault Code
    obj.dot.FC = obj.filt.FC;
    % Program Name
    obj.dot.Program = obj.plotProgramName;
    % Parameter Name
    obj.dot.ParameterName = obj.filt.CriticalParam;
    % Parameter Units
    obj.dot.ParameterUnits = obj.filt.Units;
    % LSL Parameter Name
    obj.dot.LSLName = obj.filt.LSLName;
    % LSL Value
    obj.dot.LSL = obj.filt.LSL;
    % USL Parameter Name
    obj.dot.USLName = obj.filt.USLName;
    % USL Value
    obj.dot.USL = obj.filt.USL;
    % Software filtering
    obj.dot.SoftwareFilter = obj.filt.software;
    % Calculate the filtering strings that will get displayed
    obj.updateFilterStrings
    % Engine Family filter setting
    obj.dot.FamilyFilter = obj.filt.FamilyString;
    % Truck filter
    obj.dot.TruckFilter = obj.filt.TruckString;
    % Vehicle filter
    obj.dot.VehicleFilter = obj.filt.VehicleString;
    % Date filter
       % get the to datetime 
    to = datestr(obj.filt.date(:,2),' mmmm dd,yyyy,HH:MM:SS ');
    
    % if there is from datetime input
    if ~isnan(obj.filt.date(:,1))
      from = datestr(obj.filt.date(:,1),' mmmm dd,yyyy,HH:MM:SS ');  
      obj.dot.MonthFilter = strcat('From',from,' To',to);
      if isfield(obj.filt,'exFromDateString') & isfield(obj.filt,'exToDateString')
        obj.dot.Exdatesfrom = obj.filt.exFromDateString;
        obj.dot.Exdatesto = obj.filt.exToDateString;
      end
    % otherwise just use up to
    else
      obj.dot.MonthFilter = strcat('Up to:',to); 
      if isfield(obj.filt,'exFromDateString') & isfield(obj.filt,'exToDateString')
        obj.dot.Exdatesfrom = obj.filt.exFromDateString;
        obj.dot.Exdatesto = obj.filt.exToDateString;
      end
    %obj.box.MonthFilter = obj.filt.DateString;
    end
    %obj.dot.MonthFilter = obj.filt.DateString;
    
    if isfield(obj.filt,'exFromDateString')
    % Pass filter or not command from filt to obj.dot
      obj.dot.Fltplot = obj.filt.fltplot;
    end
    
end
