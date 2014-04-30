function d = fitDist(obj, X, dist)
%Function to automatically find a distribution type and capability results
%   This function will fit the specified distribution to the data-set that is passed in 
%   and return a cdf, pdf, and p-value of the goodness-of-fit for the distribution
%   
%   Usage: d = fitDist(obj, X, dist)
%   
%   INPUTS ---
%   x:           The sample set of data points (numeric vector)
%   dist:        Distribution to fit to the data
%   
%   OUTPUTS ---
%   d:           Structurs of the distribution results---
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
%   
%   Original Version - Chris Remington - February 13, 2012
%   Modified - Chris Remington - October 23, 2012
%       - Adapted to the @StatCalculator object
%       - This funciton now will only do the calculations for one specified distribution
%         at a time (thus the output structure format was modified)
%       - To get capability statistics for multiple distributions, this will need to be
%         called for each desired distribution
%   Modified - Chris Remington - November 2, 2012
%        - Change the cdf and pdf scales for non-normal distribution to run from -10% of
%          the minimum to 10% above the maximum just like the normal distribution
    
    %% Analyze the Data passed in
    % Call an external data analysis routine
    [X, changeCode] = analyzeData(obj, X);
    
    %% Run Individual Distribution Identification Scripts
    % Fit different distribution based on the changeCode
    switch changeCode
        case 0 % flag.AllZero
            % Only allow the normal distribution to be fit in this case
            if strcmp('norm',dist)
                % Fit the normal distribution
                d = fitNorm(X, obj.alpha);
            else
                % Can't fit distributions to all zero, throw an error
                error('StatCalculator:fitDist:AllZero','Cannot fit a distribution to a dataset of all zero values with non-normal districutions.');
            end
            
        case 3 % flag.PositiveNegative
            % Only allow the normal distribution to be fit to the data at it is
            % the only distributions that can handle positive and negative data
            if strcmp('norm',dist)
                % Fit the normal distribution
                d = fitNorm(X, obj.alpha);
            else
                % Throw an error
                error('StatCalculator:fitDist:NegativeData','The ''%s'' distribution requires that all data values be positive',dist);
            end
            
        otherwise % flag.AllPositive, flag.AllNegative
            % Fit the specified distribution
            switch dist
                case 'norm'
                    d = fitNorm(X, obj.alpha);
                case 'logn'
                    d = fitLogn(X, obj.alpha);
                case 'exp'
                    d = fitExp(X, obj.alpha);
                case 'wbl'
                    d = fitWbl(X, obj.alpha);
                case 'gam'
                    d = fitGam(X, obj.alpha);
                otherwise
                    error('StatCalculator:fitDist:InvalidDist','Input to ''dist'' can either be ''best'', ''norm'', ''logn'', ''exp'', ''wbl'', or ''gam''');
            end
    end
    
    % Tack on the filtered values of data and the changeCode to the output
    d.X = X;
    d.changeCode = changeCode;
    
end

%% Distribution Fitting Functions

% Function that fits a normal distribution to the dataset
function norm = fitNorm(X, alpha)
    % Initalize the return structure
    norm = struct('mu', [], 'sigma', [], 'dfScale', [], 'cdf', [], 'pdf', [], ...
                  'p', [], 'ppm', [], 'Ppk', [], 'PpkIso', [], 'PpkNorm', []);
    
    % Find mu and sigma
    [norm.mu, norm.sigma] = normfit(X);
    % Generate the fixed intervals over which to calculate the cdf and pdf
    % 500 evenly spaced values 10% below and 10% above the range of values seen
    range = max(X) - min(X);
    norm.dfScale = linspace(min(X)-0.1*range, max(X)+0.1*range, 500)';
    % Calculate the predicted pdf and cdf with the calcualted fit
    norm.pdf = normpdf(norm.dfScale, norm.mu, norm.sigma);
    norm.cdf = normcdf(norm.dfScale, norm.mu, norm.sigma);
    % Use the kstest to estimate the Goodness-of-Fit p-value statistic of
    % the fit distribution
    % If sigma is larger than zero (i.e., there is more than one data-point)
    if norm.sigma>0
        [~, norm.p] = kstest(X, [norm.dfScale norm.cdf], alpha);
    else
        norm.p = -1;
    end
        % [H_normal,P_normal] = lillietest(X,0.05,'norm',1e-4); % With last input,
        % actually preforms the Monte-Carlo simulation
end

% Function that fits a log-normal distribution to the dataset
function logn = fitLogn(X, alpha)
    % Initalize the return structure
    logn = struct('param', [], 'dfScale', [], 'cdf', [], 'pdf', [], ...
                  'p', [], 'ppm', [], 'Ppk', [], 'PpkIso', []);
    
    % Find the log-normal distribution parameters
    logn.param = lognfit(X);
    % Generate the fixed intervals over which to calculate the cdf and pdf
    % 500 evenly spaced values 10% below and 10% above the range of values seen
    range = max(X) - min(X);
    logn.dfScale = linspace(min(X)-0.1*range, max(X)+0.1*range, 500)';
    % Calculate the predicted pdf and cdf with the calcualted fit
    logn.pdf = lognpdf(logn.dfScale, logn.param(1), logn.param(2));
    logn.cdf = logncdf(logn.dfScale, logn.param(1), logn.param(2));
    % If sigma is larger than zero (means there is more than one data point)
    if logn.param(2) > 0
        % Use kstest to extimate the goodness of fit
        [~, logn.p] = kstest(X, [logn.dfScale logn.cdf], alpha);
        % [H_logn,P_logn] = lillietest(log(X_logn_filtered),0.05,'norm',1e-4);
    else % there was only one data point
        logn.p = -1;
    end
end

% Function that fits an exponential distribution to the dataset
function exp = fitExp(X, alpha)
    % Initalize the return structure
    exp = struct('param', [], 'dfScale', [], 'cdf', [], 'pdf', [], ...
                 'p', [], 'ppm', [], 'Ppk', [], 'PpkIso', []);
    
    % Fit the distribution
    exp.param = expfit(X);
    % Generate the fixed intervals over which to calculate the cdf and pdf
    % 500 evenly spaced values 10% below and 10% above the range of values seen
    range = max(X) - min(X);
    exp.dfScale = linspace(min(X)-0.1*range, max(X)+0.1*range, 500)';
    % Calculate the predicted pdf and cdf with the calcualted fit
    exp.pdf = exppdf(exp.dfScale, exp.param);
    exp.cdf = expcdf(exp.dfScale, exp.param);
    %if ~any(isnan(exp_pdf))
    %kstest_exp = [X_exp_filtered,exp_cdf];
    % Use kstest to extimate the goodness of fit using test values and a cdf profile
    [~, exp.p] = kstest(X, [exp.dfScale exp.cdf], alpha);
    % [H_exp,P_exp] = lillietest(X_exp_filtered,0.05,'exp',1e-4);
                            %end
end

% Function that fits a weibull distribution to the dataset
function wbl = fitWbl(X, alpha)
    % Initalize the return structure
    wbl = struct('param', [], 'dfScale', [], 'cdf', [], 'pdf', [], ...
                 'p', [], 'ppm', [], 'Ppk', [], 'PpkIso', []);
    
    % Fit the distribution
    wbl.param = wblfit(X);
    % If none of the wbl parameters are Inf of NaN
    if ~any(isinf(wbl.param)|isnan(wbl.param))
        % Generate the fixed intervals over which to calculate the cdf and pdf
        % 500 evenly spaced values 10% below and 10% above the range of values seen
        range = max(X) - min(X);
        wbl.dfScale = linspace(min(X)-0.1*range, max(X)+0.1*range, 500)';
        % Calculate the predicted pdf and cdf with the calcualted fit
        wbl.pdf = wblpdf(wbl.dfScale, wbl.param(1), wbl.param(2));
        wbl.cdf = wblcdf(wbl.dfScale, wbl.param(1), wbl.param(2));
        % Use kstest to extimate the goodness of fit using test values and a cdf
        % profile
        [~, wbl.p] = kstest(X, [wbl.dfScale, wbl.cdf], alpha); % inf problem wheer pdf at 0 in Inf
    else
        wbl.p = -1;
    end
end

% Function that fits a gamma distribution to the dataset
function gam = fitGam(X, alpha)
    % Initalize the return structure
    gam = struct('param', [], 'dfScale', [], 'cdf', [], 'pdf', [], ...
                 'p', [], 'ppm', [], 'Ppk', [], 'PpkIso', []);
    
    % Fit the distribution
    gam.param = gamfit(X);
    % Generate the fixed intervals over which to calculate the cdf and pdf
    % 500 evenly spaced values 10% below and 10% above the range of values seen
    range = max(X) - min(X);
    gam.dfScale = linspace(min(X)-0.1*range, max(X)+0.1*range, 500)';
    % Calculate the predicted pdf and cdf with the calcualted fit
    gam.pdf = gampdf(gam.dfScale, gam.param(1), gam.param(2));
    gam.cdf = gamcdf(gam.dfScale, gam.param(1), gam.param(2));
    % If there are no NaNs
    if ~any(isnan(gam.pdf))
        % Use kstest to extimate the goodness of fit using test values and a cdf
        % profile
        [~, gam.p] = kstest(X, [gam.dfScale, gam.cdf], alpha);
    else
        gam.p = -1;
    end
end
