classdef DotPlotGenerator < handle
%Use this class to generate box plots of OBD Capability Data
%   Reusable code that will generate box plots for both Event Driven and Min/Max OBD
%   capability data
%   
%   Original Version - Chris Remington - April 11, 2012
%   Revised - Chris Remington - October 23, 2012
%       - Broke out all functions to be defined in files external to this classdef file
%   Revised - Dingchao Zhang - March 20th, 2015
%       - Added Fault Code matching information
%   Revised - Dingchao Zhang - June 1st, 2015
%       - Added properties to store exclude dates
        
    
    properties
        % General information for the title / axis labels
        SEID
        SystemErrorName
        ParameterName
        ParameterUnits
        DataType
        FC
        Program
         % Added Fault Code matching information
        FaultCode
        % Information about how the data is sliced
        TruckFilter
        FamilyFilter
        MonthFilter
        Exdatesfrom
        Exdatesto
        SoftwareFilter
        VehicleFilter
        % Information on the LSL and USL, if applicable
        LSL
        LSLName
        USL
        USLName
        % The data vs. group data that will get plotted
        Data
        GroupData
        Group2Data
        % Added to allow control over how the labels are plotted outside of this function
        Labels
        GroupOrder
        Labels2
        Group2Order
       
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
        % Make the actual plot
        separationLines = dotplot(obj,data,group,groupOrder,groupLabels,group2,group2Order,group2Labels,varargin)
    end
    
end
