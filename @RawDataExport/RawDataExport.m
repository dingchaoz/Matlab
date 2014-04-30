classdef RawDataExport < Capability
%Object that will handle exporting the raw Event Driven and MinMax data
%   This will contain the methods needed to export all of the raw event driven and
%   MinMax data into both excel spreadsheets and raw .mat files.
%   
%   For event driven data, the spreadsheets should only have the "TOP 1000" largest
%   and smallest values if there are more than 2000 data points.
%   
%   For MinMax data, the spreadsheet should contain all of the data present in the
%   database.
    
    properties
        
    end
    
    methods % Implemented elsewhere
        
        % Export Event Driven data by system error id with all parameters time-gridded
        % together
        EventData(obj, dir)
        
        % Modification of above to only export a single Event Driven system error
        SingleEventData(obj, seid, dir)
        
        % Export the MinMax data present for all parameters in both .mat files and in
        % excel spreadsheets
        MinMaxData(obj, dir)
        
        % Export the MinMax data present for a specified parameter in both .mat files and
        % in excel spreadsheets
        SingleMinMaxData(obj, pdid, dir)
        
        % Run throught the custom request list to make time-gridded spreadsheets of MinMax
        % data
        % ----
        
    end
    
end
