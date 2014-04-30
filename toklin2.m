function c = toklin2(l,s)
%   toklin      - tokenize a string, called from readcsv
%
%  Given a line (string) and a separator character, tokenize
%  and return a cell array of tokens.
%
%  Usage:  c = toklin(l,s)
%  
%          l:  line to analyze
%          s:  separator character
%          c:  returned cell array
%  
%  Jerry Song
%  Mar 29, 2001
%  Cummins Inc. 
%  
%   Revamped - Chris Remington - April 13, 2013
%   - Increase speed 3x with prallocation and smarter memory manegement
    
    % Check for invalid input
    if ~isschar(l), error('Not a string!'), end
    if isempty(l), error('Empty string!'), end
    if nargin~=2, error('Two inputs are required!'), end
    
    % Find the locations of the specified deliniation character
    dlm = [0 findstr(l,s) length(l)+1];
    % Initalize a cell array to hold each 
    c = cell(length(dlm)-1,1);
    % Loop through each section
    for i = 2:length(dlm)
        % Extract the target section from between the deliniation character
       c{i-1} = l(dlm(i-1)+1:dlm(i)-1);
    end
end
