function [X, changeCode] = analyzeData(obj, X)
%Evaluate X to determine if the data needs to be modified
%   Usage: [X, changeCode] = analyzeData(obj, X)
%   
%   Will look for such things as: all data is zero, all data is negative (will filp the
%   sign), there is positive and negative data (can only fit a normal distribution), and
%   will always trim out values of zero.
%   
%   Inupts ---
%   X:          Data-set to be analyzed
%   
%   Outputs ---
%   X:          Revised data-set that is trimed and possilble had the sign filpped
%   changeCode: An enumeration indicating the results of what was found
%   
%   Original Version - Chris Remington - February 13, 2012
%   Revised - Chris Remington - February 3, 2014
%     - Removed the usage of an enumeration because of compatibility with R2008a. Old
%       enumeration was a follows:
%         AllZero (0)
%         AllPositive (1)
%         AllNegative (2)
%         PositiveNegative (3)
    
    %% Analyze data
    
    % Trim the zeros from the input data
    %X = X(X~=0);
    % Skip this for now as the GUI is only doing the normal Ppk
    
    % If all the data is zeros, X will be empty
    if sum(X) == 0 %isempty(X)
        % Return an empty set, you can't fit a distribution to all zeros
        %X = [];
        % Set the changeCode
        changeCode = 0; % flag.AllZero
        
    % Elseif all the data is negative
    elseif sum(X<0)==length(X)
        % Flip the sign to make the data all positive
        X = -X;
        % Set the changeCode
        changeCode = 2; % flag.AllNegative
        
    % Elseif there is both positive and negative data
    elseif sum(X<0)~=0 && sum(X>0)~=0
        % Set the changeCode
        changeCode = 3; % flag.PositiveNegative
        
    % The data is all positive with (at least one) useful non-zero values
    else
        % Set the changeCode
        changeCode = 1; % flag.AllPositive
    end
    
end
