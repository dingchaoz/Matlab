classdef CapHistGenerator < handle
%Use this class to generate box plots of OBD Capability Data
%   Reusable code that will generate box plots for both Event Driven and Min/Max OBD
%   capability data
%   
%   Original Version - Chris Remington - April 11, 2012
%   Revised - Chris Remington - October 23, 2012
%       - Broke out all functions to be defined in files external to this classdef file
    
    properties
        % General information for the title / axis labels
        SEID
        SystemErrorName
        ParameterName
        ParameterUnits
        DataType
        FC
        Program
        % Information about how the data is sliced
        TruckFilter
        FamilyFilter
        MonthFilter
        SoftwareFilter
        VehicleFilter
        % Information on the LSL and USL, if applicable
%         LSL
%         LSLName
%         USL
%         USLName
%         % The data vs. group data that will get plotted
%         Data
%         GroupData
        % Added to allow control over how the labels are plotted outside of this function
        Labels
        PpK
        TimePeriod
        DataPoints
        FailureDataPoints
        TruckName
        CalibrationVersion
        StartDateStr
        EndDateStr
%         GroupOrder
    end
    
    methods % Implemented externally
        % Make the Box Plot
        makePlot(obj, visible)
        % Save the Box Plot
        savePlot(obj, fileName)
        % Reset all object properties
        reset(obj)
        % Convert a calibration number to a calibration string
        calString = num2dot(obj, calNumber)
    end
    
    properties (Dependent)
%         Data
    end
    
    methods
%         % Set method controller for the data-set data
%         % This will be called when Data is changed by the user
%         function obj = set.Data(obj, x)
%             
%         end
    end
    
end
