function dname = getDistName(obj, dcode)
%Returns full distribution name from distribution code
%   This little function will return the full name of a distribution 
%   from it's distribution code
%   
%   Usage: dname = getDistName(obj, dcode)
%   
%   Inputs - 
%   dcode:    Distribution code, either 'norm', 'logn', 'exp', 'wbl', or 'gam'
%   
%   Outputs - 
%   dname:    Name of the distribution
%   
%   Original Version - Chris Remington - October 23, 2012
%   Revised - N/A - N/A
    
    % Switch based on input string
    switch dcode
        case 'norm'
            dname = 'Normal';
        case 'logn'
            dname = 'Log-Normal';
        case 'exp'
            dname = 'Exponential';
        case 'wbl'
            dname = 'Weibull';
        case 'gam'
            dname = 'Gamma';
        otherwise
            % Invalid input, throw the following error
            error('HistogramGenerator:getDistName:InvalidDist','Invalid distrabution name input.')
    end
end
