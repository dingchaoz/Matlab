function c = calcCapability(obj, X, LSL, USL, dist)
%Calculate the capability of a given data set and thresholds
%   Usage: c = calcCapability(obj, X, LSL, USL, dist)
%   
%   This should strictly take in a data set and be given the threshold values.
%   In order to expand capability by engine family (where X and LSL/USL can be different),
%   it is more prudent to call this function to do the calculations multiple times on
%   multiple different data-sets, then have that higher-lever function worry about how to
%   handle the results from multiple different data sets.
%   
%   INPUTS --- 
%   X:          Vector of the dataset to be processed
%   LSL:        upper spec limit (should be NaN if it does not exist)
%   USL:        lower spec limit (should be NaN if it does not exist)
%   dist:       Distribution to fit to the data and return the results
%               Valid inputs are: 'norm', 'logn', 'exp', 'wbl', 'gam', or 'best'
%   
%   OUTPUTS ---
%   c:           structure of various capability parameters
%   .mu, .sigma: Distribution parameters for normal distribution        
%   .param:      Distribution parameters for non-normal distributions
%   .dfScale:    Data values at which the cdf and pdf were calculated
%   .cdf:        Values of the cdf at the points in the dfScale
%   .pdf:        Values of the pdf at the points in the dfScale
%   .p:          P-value returned from KStest
%   .ppm:        Predicted PPM value to failure
%   .Ppk:        Minitab method Ppk calculation
%   .PpkIso:     ISO method Ppk calculation
%   .PpkNorm:    Ppk using standard calculation
%   .X:          Filtered dataset used in distribution fitting
%   .changeCode: The flag output from analyzeData function
%   .dist:       Holds the manually specified or automatically selected distribution
%   .min:        Min value of the data points
%   .max:        Max value of the data points
%   .mean:       Mean value of the data points
%   .numDataPts: Number of data points used in calculations
%   .numFail:    Number of data points outside of the failure thresholds
%   .numZeros:   Number of zero data points that were filtered from the input data-set
%   .LSL:        Corrected value of the LSL used (sign flipped if all data was negative)
%   .USL:        Corrected value of the USL used (sign flipped if all data was negative)
%   
%   Original Version - Chris Remington - February 17, 2012
%   Revised - Chris Remington - May 10, 2012
%       - Many changes to better handle where and when data is passed around to different
%         functions
%   Adapted - Chris Remington - October 22, 2012
%       - Adapted the function to be part of a separate object from @ProcessEvent
%       - Changed to either only do a specified distribution or the best distribution
    
    %% Fit Distributions
    
    % If the best fit distribution is desired
    if strcmp('best', dist)
        % Fit all distributions and find the best one (don't try an exp dist if there is a
        % LSL specified)
        [d, d.dist] = obj.fitBestDist(X, isnan(LSL));
    else
        % Fit desired distribution and calculate p values
        d = obj.fitDist(X,dist);
        % Note the distribution in the output
        d.dist = dist;
    end
    
    % If the data-set was all negative and flipped
    if d.changeCode == 2 % flag.AllNegative
        % Flip signs on the USL and LSL also
        LSL = -LSL;
        USL = -USL;
    end
    
    %% Calculate cdf to LSL and/or USL for each distribution
    
    % Calculate the cdf to LSL for the specified distribution
    if ~isnan(LSL)
        switch d.dist
            case 'norm' % Normal
                cdf_LSL = normcdf(LSL, d.mu, d.sigma);
            case 'logn' % Log-normal
                cdf_LSL = logncdf(LSL, d.param(1), d.param(2));
            case 'wbl'  % Weibull
                cdf_LSL = wblcdf(LSL, d.param(1), d.param(2));
            case 'gam'  % Gamma
                cdf_LSL = gamcdf(LSL, d.param(1), d.param(2));
            case 'exp'  % Exponential
                error('StatCalculator:calcCapability:LSLwithExp','Cannot calculate capability for an exponential distribution with a LSL specified.');
            otherwise
                error('StatCalculator:calcCapability:InvalidDist','Input to ''dist'' can either be ''best'', ''norm'', ''logn'', ''exp'', ''wbl'', or ''gam''');
        end
    end
    
    % Calculate the cdf to USL for the specified distribution
    if ~isnan(USL)
        switch d.dist
            case 'norm' % Normal
                cdf_USL = normcdf(USL, d.mu, d.sigma);
            case 'logn' % Log-normal
                cdf_USL = logncdf(USL, d.param(1), d.param(2));
            case 'wbl'  % Weibull
                cdf_USL = wblcdf(USL, d.param(1), d.param(2));
            case 'gam'  % Gamma
                cdf_USL = gamcdf(USL, d.param(1), d.param(2));
            case 'exp'  % Exponential
                % This only executes is the LSL is a NaN as the error above breaks
                % execution of this funciton
                cdf_USL = expcdf(USL, d.param);
            otherwise
                error('StatCalculator:calcCapability:InvalidDist','Input to ''dist'' can either be ''best'', ''norm'', ''logn'', ''exp'', ''wbl'', or ''gam''');
        end
    end
    
    %% Use cdf Results to calculate ppm and Ppk for the specified distribution
    % If its 1-sided w/ LSL only
    if ~isnan(LSL) && isnan(USL)
        % Calculate ppm
        d.ppm = cdf_LSL*1e6;
        % Calculate Ppk using the Minitab method for non-normal distributions
        d.Ppk = calcMinitabPpk(cdf_LSL,NaN);
        % Calculate Ppk for a normal distribution (above and below give same result
        % for a normal distribution, so this is unneeded)
        try
            d.PpkNorm = (d.mu-LSL)/(3*d.sigma);
        catch ex % In case this code is ever run again with dist not set to 'norm'
            d.PpkNorm = NaN;
        end
        % Calculate Ppk using the ISO method for non-normal distributions
        d.PpkIso = calcIsoPPL(d.dist, d, LSL);
        
    elseif isnan(LSL) && ~isnan(USL) % If its 1-sided w/ USL only
        % Calculate ppm
        d.ppm = (1-cdf_USL)*1e6;
        % Calculate Ppk using the Minitab method for non-normal distributions
        d.Ppk = calcMinitabPpk(NaN,cdf_USL);
        % Calculate Ppk for a normal distribution (above and below give same result
        % for a normal distribution, so this is unneeded)
        try
            d.PpkNorm = (USL-d.mu)/(3*d.sigma);
        catch ex % In case this code is ever run again with dist not set to 'norm'
            d.PpkNorm = NaN;
        end
        % Calculate Ppk using the ISO method for non-normal distributions
        d.PpkIso = calcIsoPPU(d.dist, d, USL);
        
    elseif ~isnan(LSL) && ~isnan(USL) % If its 2-sided w/ LSL and USL
        % Calculate ppm
        d.ppm = (cdf_LSL + (1-cdf_USL))*1e6;
        % Calculate Ppk using the Minitab method for non-normal distributions
        d.Ppk = calcMinitabPpk(cdf_LSL,cdf_USL);
        % Calculate Ppk for a normal distribution (above and below give same result
        % for a normal distribution, so this is unneeded)
        try
            d.PpkNorm = min([USL-d.mu, d.mu-LSL])/(3*d.sigma);
        catch ex % In case this code is ever run again with dist not set to 'norm'
            d.PpkNorm = NaN;
        end
        % Calculate Ppk using the ISO method for non-normal distributions
        d.PpkIso = min(calcIsoPPL(d.dist, d, LSL), calcIsoPPU(d.dist, d, USL));
        
    else % If LSL = NaN and USL = NaN
        % Throw an error
        error('StatProcessor:calcCapability:invalidLimits', 'Both LSL and USL cannot be NaNs');
    end
    
    %% Finish up
    % Assign the distribution data and capability numbers to the output structure
    c = d;
    % Min, Max, and Mean (use d.X as this will be the inverted data-set if analyze data
    % does so for all negative values)
    c.min = min(d.X);
    c.max = max(d.X);
    c.mean = mean(d.X);
    % Calculate the number of data points and the number outside the spec limits
    c.numDataPts = length(d.X);
    c.numFail = calcNumFail(d.X, LSL, USL);
    c.numZeros = length(X) - c.numDataPts;
    % Values of the LSL and USL
    c.LSL = LSL;
    c.USL = USL;
    
end

function ppk = calcMinitabPpk(p1,p2)
% Use the cdf to the LSL and USL to calculate the PPL and PPU using the Minitab method
% Then return the smallest one as the Ppk
    % If there is a p1 (cdf to LSL)
    if ~isnan(p1)
        PPL = -norminv(p1,0,1)/3;
    else
        PPL = NaN;
    end
    % If there is a p2 (cdf to USL)
    if ~isnan(p2)
        PPU = norminv(p2,0,1)/3;
    else
        PPU = NaN;
    end
    % Return the smaller of PPL and PPU for the Ppk result
    ppk = min([PPL PPU]);
end

function ppk = calcNormPpk(p1,p2)
% Use the cdf to the LSL and USL to calculate the PPL and PPU using the Minitab method
% Then return the smallest one as the Ppk
    % If there is a p1 (cdf to LSL)
    if ~isnan(p1)
        PPL = -norminv(p1,0,1)/3;
    else
        PPL = NaN;
    end
    % If there is a p2 (cdf to USL)
    if ~isnan(p2)
        PPU = norminv(p2,0,1)/3;
    else
        PPU = NaN;
    end
    % Return the smaller of PPL and PPU for the Ppk result
    ppk = min([PPL PPU]);
end

function PPL = calcIsoPPL(code, di, LSL)
% Based on the distribution, calculate the values of the 50th percentile 
% (like the mean) and the 0.135th precentile (like the value at -3 sigmas)
    % Based on the distribution type
    switch code
        case 'norm'
            % Use the dedicated norminv funciton
            X5 = norminv(0.5,di.mu,di.sigma);
            X135 = norminv(0.00135,di.mu,di.sigma);
        case 'exp'
            % There is only one distribution parameter
            X5 = icdf('exp',0.5,di.param);
            X135 = icdf('exp',0.00135,di.param);
        otherwise
            % There are two generic parameters, use an abstracted icdf function call
            X5 = icdf(code,0.5,di.param(1),di.param(2));
            X135 = icdf(code,0.00135,di.param(1),di.param(2));
    end
    % Last, use the values to calculate the ISO Method Ppk for non-normal distributions
    PPL = (X5-LSL)/(X5-X135);
end

function PPU = calcIsoPPU(code, di, USL)
% Based on the distribution, calculate the values of the 50th percentile 
% (like the mean) and the 99.865th precentile (like the value at -3 sigmas)
    % Based on the distribution type
    switch code
        case 'norm'
            % Use the dedicated norminv funciton
            X5 = norminv(0.5,di.mu,di.sigma);
            X99865 = norminv(0.99865,di.mu,di.sigma);
        case 'exp'
            % There is only one distribution parameter
            X5 = icdf('exp',0.5,di.param);
            X99865 = icdf('exp',0.99865,di.param);
        otherwise
            % There are two generic parameters, use an abstracted icdf function call
            X5 = icdf(code,0.5,di.param(1),di.param(2));
            X99865 = icdf(code,0.99865,di.param(1),di.param(2));
    end
    % Last, use the values to calculate the ISO Method Ppk for non-normal distributions
    PPU = (USL-X5)/(X99865-X5);
end

function a = calcNumFail(X, LSL, USL)
% Calculate the number of data points outside the LSL and USL for the given data set
    % Calculate number below the LSL
    below = sum(X<=LSL); % This will be zero if the LSL is a NaN
    above = sum(X>=USL); % This will be zero is the USL is a NaN
    a = below + above;
end
