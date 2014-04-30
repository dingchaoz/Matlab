classdef StatCalculator < handle
%Holds to methods to do various statistical calculations on data-sets
%   This will encapsulte the methods that will calculate the capability statistics for the
%   OBD Capability data process
%   
%   Started - Chris Remington - October 22, 2012
%   Revised - N/A - N/A
    
    properties
        % Define the alpha to use and pass into KS-test when calculating p-value
        alpha = 0.05;
        
        % What should the other properties be?
        %varA
        
    end
    
    methods % implemented here
        
        % Constructor
        function obj = StatCalculator(alpha)
            % Optional input, allows alpha to be defined in the constructor
            if exist('alpha','var')
                obj.alpha = alpha;
            end 
        end
        
        % Destructor (unused as of now)
        function delete(obj)
            
        end
        
    end
    
    methods % implemented externally
        
        % Main function that will calculate the capablity of a data-set
        c = calcCapability(obj, X, LSL, USL, dist)
        
        % Analizes the input data-set for various characteristics
        [X, changeCode] = analyzeData(obj, X)
        % Fits a specified distribution and returns the distribution fit information
        d = fitDist(obj, X, dist)
        % Fist all distributions possible with fitDist and returns the results from best one
        [d, dist] = fitBestDist(obj, X, fitExp)
        
    end
    
end
