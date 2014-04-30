function m2mat(exportFile,matFile,filter,program)
%Open a .m export file from Calterm III can convert to a .mat file.
%   Specify a path to an existing Calterm III export file and this function will read it
%   into Matlab and save the calibratibles into a .mat file
%   
%   Inputs - 
%   exportFile: Full file path and name of the Calterm III export file
%   matFile:    Full file path and name of the .mat file you want to create
%   filter:     Name of the filter file used to validate each parameter is present
%   program:    Name of the enging program being used
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 21, 2012
%   Revised - Chris Remington - May 9, 2012
%     - Added the code the read in the filter file and check that each
%       parameter in the filter file actually got export properly
%   Revised - Chris Remington - January 13, 2014
%     - Modified how special values get added to the .mat files to make it easier to
%       support multiple engine programs
    
    % Open the .m file for reading
    run(exportFile);
    
    % Capture a listing of all the variables in the export file
    vars = whos;
    
    % Reset the .mat file with the first parameter
    eval([vars(1).name ' = ' vars(1).name '.Value;']);
    % Create the file and save the variable (need to do this so -append works below)
    save(matFile, vars(1).name);
    
    % For each additional variable that was loaded into the workspace
    for i = 2:length(vars)
        % Skip the two input variables
        if strcmp(vars(i).name, 'exportFile') || strcmp(vars(i).name, 'matFile') ...
                 || strcmp(vars(i).name, 'filter') || strcmp(vars(i).name, 'program')
            continue
        end
        
        % Get rid of the structure and put it back to a normal value
        eval([vars(i).name ' = ' vars(i).name '.Value;']);
        
        % Append because the file already exists
        save(matFile, vars(i).name,  '-append');
        
    end
    
    % Run the function to define the additional special values to put in the .mat file
    manualCalValues(program,matFile)
    
    %% Check Calterm Export File
    % Because of a strange bug in the calterm CLI on 3.5.1, check that each parameter 
    % specified in the filter file is actually present in the workspace
    
    % Blank line before
    fprintf('\n')
    
    % Read in the filter file with Matlab
    params = readFilter(filter);
    % For each each parameter present in the filter file
    for i = 1:length(params)
        % Does it exist in the workspace
        if ~exist(params{i},'var')
            % If not, display a warning message
            fprintf('%s is not present after processing the export file.\n',params{i})
        end
    end
    
    % Blank line after
    fprintf('\n')
    
end

function params = readFilter(filter)
% Read in a filter file and return a cell array of strings of the parameters present
    % Open the file
    fid = fopen(filter);
    % Read in the data
    data = textscan(fid, '%s');
    % Pull out the parameter
    params = data{1}(2:end);
    % Close the file
    fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This should be kept up-to-date and match any special thresholds values used %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function manualCalValues(program,matFile)
% Contain the manually defined threshold parameters and values by engine program
    % Depending on engine program
    switch program
        case {'HDPacific','Atlantic','Mamba','Pacific'};
            % Declare these additional manually specified value
            zero = 0;
            V_SFD_tmh_TooFreqRegen_Thd_static = 10;
            V_SFD_gpl_DiagMBSLE_DPSLE_Thd_static = 3;
            Sensor_Supply_USL = 5.36;
            Sensor_Supply_LSL = 4.64;
            EGTS_Temperature_Limit = 150;
            % Save them to the .mat file
            save(matFile,'zero','V_SFD_tmh_TooFreqRegen_Thd_static',...
                'V_SFD_gpl_DiagMBSLE_DPSLE_Thd_static',...
                'Sensor_Supply_USL','Sensor_Supply_LSL',...
                'EGTS_Temperature_Limit','-append');
        otherwise
            % Declare these additional manually specified value
            zero = 0;
            V_SFD_tmh_TooFreqRegen_Thd_static = 10;
            V_SFD_gpl_DiagMBSLE_DPSLE_Thd_static = 3;
            Sensor_Supply_USL = 5.36;
            Sensor_Supply_LSL = 4.64;
            EGTS_Temperature_Limit = 150;
            % Save them to the .mat file
            save(matFile,'zero','V_SFD_tmh_TooFreqRegen_Thd_static',...
                'V_SFD_gpl_DiagMBSLE_DPSLE_Thd_static',...
                'Sensor_Supply_USL','Sensor_Supply_LSL',...
                'EGTS_Temperature_Limit','-append');
    end
end
