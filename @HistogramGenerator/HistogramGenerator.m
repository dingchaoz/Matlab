classdef HistogramGenerator < StatCalculator
%Generates a histogram of OBD Capabililty Data
%   This will contain the logic used to create the capability histograms
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - N/A - N/A
    
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
        LSL
        LSLName
        USL
        USLName
        % The data and distribution that will get plotted
        Data
        Dist
    end
    
    % Read-only properties
    properties (SetAccess = protected)
        % Holds the output of calcCapability
        c
    end
    
    methods % implemented externally
        % Method that will make the histogram and calculate any required statistics
        makePlot(obj, visible)
        % Method that will save the plot generated
        savePlot(obj, fileName)
        % Simple function to return a human-readable name from a dist code
        dname = getDistName(obj, dcode)
        % The method that converts calibration numbers to calibration strings
        calString = num2dot(obj, calNumber)
    end
end
