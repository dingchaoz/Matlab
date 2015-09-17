% This program finds the latest mat file that was either processed or moved
% to the error folder

function date = LastFileProcessed(path)
% Look for the files waiting to be processed first and get the latest file
foldercontents = dir(fullfile(path,'*.mat'));
if ~isempty(foldercontents)
    
end % if ~isempty(foldercontents)

end % function date = LastFileProcessed(path)