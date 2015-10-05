% This program finds the latest mat file that was either processed or moved
% to the error folder
function filename = LastFileProcessed(directory)
lastfile = [];
if exist(fullfile(directory,'Matfiles'),'dir')
    lastfile = LatestFileinDirectory(fullfile(directory,'Matfiles'));
else
    mkdir(fullfile(directory,'Matfiles'));
end
if exist(fullfile(directory,'Matfiles','processed'),'dir')
    lastfile = [lastfile;LatestFileinDirectory(fullfile(directory,'Matfiles','processed'))];
else
    mkdir(fullfile(directory,'Matfiles','processed'));
end %  lastfile_processed = LatestFileinDirectory(fullfile(directory,'processed'));
if exist(fullfile(directory,'Matfiles','error'),'dir')
    lastfile = [lastfile;LatestFileinDirectory(fullfile(directory,'error'))];
else
    mkdir(fullfile(directory,'Matfiles','error'));
end % if exist(fullfile(directory,'error'),'dir')
[files id] = sort(lastfile,'descend');
if ~isempty(files)
    filename = files(1,:);
else
    filename = [];
end % if ~isempty(files)
end %function LastFileProcessed(directory)


function File = LatestFileinDirectory(path)
File = [];
% Look for the files waiting to be processed first and get the latest file
foldercontents = dir(fullfile(path,'*.mat'));
if ~isempty(foldercontents)
    [sorted idx] = sort(cell2mat({foldercontents(:).datenum}),'descend');
    filepart_1 = toklin(foldercontents(idx(1)).name,'_');
    filepart_1 = toklin(char(filepart_1(end)),'.mat');
    namedate = datenum(char(filepart_1(1)),'yymmdd');
    if namedate == sorted(1)
        File = foldercontents(idx(1)).name;
    elseif length({foldercontents(:).name}) > 1
        [sortname idx] = sort(char({foldercontents(:).name}),'descend');
        File = sortname(1,:);
    else
        File = char({foldercontents(:).name});
    end % if namedate == sorted(1)
    
    
end % if ~isempty(foldercontents)

end % function date = LastFileProcessed(path)