function [d, dist] = fitBestDist(obj, X, fitExp)
%Similar to fitDist, but returns the results of the best fit distribution
%   This function will find the best-fit distribution for the data-set that is passed in
%   and return a cdf, pdf, and p-value of the goodness-of-fit for that distribution
%   
%   Usage: d = fitBestDist(obj, X)
%          d = fitBestDist(obj, X, dist)
%   
%   INPUTS ---
%   X:           The sample set of data points (numeric vector)
%   fitExp:      Optional, true if the 'exp' dist should be included in the test dist list
%   
%   OUTPUTS ---
%   d:           Structurs of the distribution results (same as fitDist)---
%   .X:          Filtered dataset used in distribution fitting
%   .mu, .sigma: Distribution parameters for normal distribution        
%   .param:      Distribution parameters for non-normal distributions
%   .dfScale:    Data values at which the cdf and pdf were calculated
%   .cdf:        Values of the cdf at the points in the dfScale
%   .pdf:        Values of the pdf at the points in the dfScale
%   .p:          P-value returned from KStest   (blank, calculated in calcCapability)
%   .ppm:        Predicted PPM value to failure (blank, calculated in calcCapability)
%   .Ppk:        Minitab method Ppk calculation (blank, calculated in calcCapability)
%   .PpkIso:     ISO method Ppk calculation     (blank, calculated in calcCapability)
%   .PpkNorm:    Ppk using standard calculation (blank, calculated in calcCapability)
%   .changeFlag: The flag output from analyzeData function
%   dist:        Text string identifying the selected distribution
%   
%   Original Version - Chris Remington - October 23, 2012
%       - Created after modifying fitDist to only do one distribution, this will now call
%         fitDist for each desired distribution and return the results from the best fit
%   Revised - N/A - N/A
    
    % Define the distribution list to try
    if ~exist('fitExp','var') || fitExp
        % If fitting the exponential is desired (there is no LSL specified)
        di = {'norm','logn','exp','wbl','gam'};
        % Define a place to store the output of each
        data = cell(5,1);
        % Define a place to store each p-value
        pVal(1:5) = -1;
    else
        % If fitting the exponential is not desired (there is a LSL specified)
        di = {'norm','logn','wbl','gam'};
        % Define a place to store the output of each
        data = cell(4,1);
        % Define a place to store each p-value
        pVal(1:4) = -1;
    end
    
    % For each distribution in the list
    for i = 1:length(di)
        try
            % Try to fit the distribution
            data{i} = obj.fitDist(X,di{i});
            % Pull out the p value
            pVal(i) = data{i}.p;
        catch ex
            % If error was all zero, throw the original error
            if strcmp('StatCalculator:fitDist:AllZero',ex.identifier)
                rethrow(ex)
            end
            % Else skip this distribution and move on to the next one
        end
    end
    
    % Find the largest p-value (distributions skipped will still be -1 and ignored)
    [~, idx] = max(pVal);
    
    % Return the results from the best distribution
    d = data{idx};
    dist = di{idx};
    
end
