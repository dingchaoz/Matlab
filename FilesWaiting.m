function FilesWaiting(varargin)
% Files Waiting for All Programs
    
    if nargin < 1
        % Define program list
        progList = {'HDPacific','Atlantic','Mamba','Pele',...
                    'DragonCC','DragonMR','Seahawk','Yukon',...
                    'Blazer','Bronco','Clydesdale','Shadowfax',...
                    'Vanguard','Ventura'};
        %progList = {'HDPacific','Atlantic','Mamba','Pele'};
        %progList = {'DragonCC','DragonMR','Seahawk','Yukon'};
        %progList = {'DragonCC'};
    else
        % Use the user specified engine programs
        progList = varargin;
    end
    
    % Loop through list, count
    for i = 1:length(progList)
        % Initalize the Capability object
        cap = Capability(progList{i});
        % Display program name
        disp(progList{i});
        % Count the files
        cap.filesWaiting;
        % Blank line
        disp(' ')
    end
    
end
