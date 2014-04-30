function c = toklin(l,s)
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

if ~isstr(l), error('Not a string!'), end
if isempty(l), error('Empty string!'), end
if nargin~=2, error('Two inputs are required!'), end

dlm = [0 findstr(l,s) length(l)+1];
c = [];
for i = 2:length(dlm)
   str = l(dlm(i-1)+1:dlm(i)-1);  % extract string
   str = cellstr(str);
   c = [c str];
end
