function RunCapabilityGUI
%% Information
% This is a small script intended to check the user's Matlab configuration,
% alert to any problems that may arise before running the GUI tool, then
% change the working directory of Matlab to the location of the tool and
% running the proper code.
% Modified- Add lines to check for statistics and machine learning toolbox
% by Dingchao Zhang 07/14/2015
    
    %% Check for the Matlab version needed
    % If Matlab is older than R2010a
    if verLessThan('matlab','7.10')
        msgbox('You need to be using at least Matlab version R2010a or newer to use this tool.');
        % Stop execuation of the code
        return
    end
    
    %% Check for the toolboxes needed
    
    % Get toolbox information
    v = ver;
    % Strip off the toolbox names
    toolbox = {v(:).Name};
    
    % If Matlab is older than 2015a, the matlab version will be smaller
    % than 8.5.0
    if verLessThan('matlab','8.5.0')
        % Check for the Statistics Toolbox and the Database Toolbox
        if ~any(strcmp('Statistics Toolbox',toolbox)|strcmp('Database Toolbox',toolbox))
            msgbox('You need to have the Statistics Toolbox and Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    
        % Check for the Statistics Toolbox
        if ~any(strcmp('Statistics Toolbox',toolbox))
            msgbox('You need to have the Statistics Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    else
    % Else if using Matlab 2015a or newer version
        % Check for the Statistics and Machine learning Toolbox which is the name for statitics toolbox in Matlab 2015 and the Database Toolbox
        if ~any(strcmp('Statistics and Machine Learning Toolbox',toolbox)|strcmp('Database Toolbox',toolbox))
            msgbox('You need to have the Statistics and Machine Learning Toolbox and Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    
        % Check for the Statistics and Machine Learning Toolbox
        if ~any(strcmp('Statistics and Machine Learning Toolbox',toolbox))
            msgbox('You need to have the Statistics and Machine Learning Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    end
    
    % Check for the Database Toolbox
    if  ~any(strcmp('Database Toolbox',toolbox))
        msgbox('You need to have the Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
        return
    end
    
    %% CD to Network Location
    
    % Hold onto the old working directory
    oldDirectory = pwd;
    
    % Define location of newest GUI code
    guiLocation = '\\CIDCSDFS01\EBU_Data01$\NACTGx\common\DL_Diag\Data Analysis\OBD Capability GUI\CapabilityGUI';
    
    try
        % CD to network location with newest code
        cd(guiLocation)
    catch ex
        % Error handling
        if strcmp('MATLAB:cd:NonExistentDirectory',ex.identifier)
            % Display a warning
            fprintf('Failure to change working directory to the newtork location in DL_Diag because of a connection error or you don''t have access to the DL_Diag folder.\r%s',guiLocation);
            % CD back to the old directory
            cd(oldDirectory);
            % Stop code execuation
            return
        else
            disp('Unknown error occoured.')
            % Display the matlab error message
            disp(ex.getReport)
            % CD back to the old directory
            cd(oldDirectory);
            % Stop execuation of the code
            return
        end
    end
    
    %% Check for the sql drivers
    % Look for the sqldriver folder the installer creates
    if ~exist(fullfile(matlabroot,'sqldriver'),'dir')
        % Ask the user if they want to install the software
        button = questdlg('You don''t appear to have the Microsoft SQL Server driver added to your matlab installation. You need that for the tool to function correctly. Would you like to add that now? (You will be required to re-start Matlab when it''s finished)','Install SQL Driver','Yes','No','Yes');
        % If No was selected
        if strcmp('No',button)
            % CD back to the old directory
            cd(oldDirectory);
            % Stop execuation of the code
            return
        end
        
        % Intsall the SQL Drivers
        InstallSQLDriver
        
        % Ask user to exit Matlab
        button = questdlg('In order for the changes to take effect, you will need to restart Matlab. Would you like to exit Matlab now (will will need to manually open it again)?','Restart Matlab?','Yes','No','Yes');
        if strcmp('Yes',button)
            % Exit Matlab
            exit
        else
            % CD back to the old directory
            cd(oldDirectory);
            % Stop execuation of the rest of the function
            return
        end
    end
    
    %% Open the tool
    path(path,guiLocation);
    CapabilityGUI
    
end
