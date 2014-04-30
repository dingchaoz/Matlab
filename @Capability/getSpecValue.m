function val = getSpecValue(obj, specStr, family)
%Takes in a string that can contain multiple calibratible values and returns the correct value
%   Usage: val = getSpecValue(obj, specStr, family)
%   
%   This allows the LSL and USL to be specified like so if it is not a simple value or is
%   a value inside of an array: 
%       -> C_ATD_pr_DPF_dP_Init_Thresh + C_ATD_pr_DPF_dP_Offset
%       -> C_UTD_tm_UHM_Thaw_Y(2)
%       -> C_SCD_pc_NXSD_SelfDiag_LLim + C_SCD_pc_NXSD_LLim_Offset
%   This will call eval with those strings and return the computed value. This is the
%   slowest way. Single parameters are like the below are the fastest:
%       -> C_UTD_trc_InitTmptrRise_Delta
%       -> C_ATD_ct_HiTmptr_Persist_Fault
%   
%   If NaN is passed in to specString, a numeric value of NaN is returned
%   If 'NaN' is passes in to specString, a numeric value of NaN is returned (not a string)
%   
%   Inputs ---
%   specStr: See above, string of the calibratable threshold
%   family:  Engine family name as defined in [dbo].[tblCals]
%   
%   Outputs ---
%   val:     Calculated numerical value of the string passed in
%              Will return a NaN if a NaN was passed as input
%   
%   Original Version - Chris Remington - April 12, 2012
%   Revised - Chris Remington - July 16, 2013
%     - Changed for Atlatnic
%   Revised - Chris Remington - January 14, 2014
%     - Modified to accomodate floating engine family names for different programs so that
%       acceptable family names are defined in the [dbo].[tblCals] and [dbo].[tblTrucks] 
%       tables
%   Revised - Chris Remiington - March 6, 2014
%     - Modified behavior so if the LSL or USL is not NULL in the database but just an 
%       empty string, values of '' passed into this function will result in a return value
%       of NaN to keep the behavior consistant with NULL LSL / USL
    
    % If the input was a NaN
    if isnan(specStr)
        % Keep the output as a NaN
        val = NaN;
        % Exit execution, retrun to the caller
        return
    elseif ~ischar(specStr) % Check that the input was a string
        % If it wasn't, throw an error
        error('CalParameters:getSpecValue:InvalidSpecStr', 'Input to specStr must be a string');
    elseif isempty(specStr) % the input was ''
        % Make the output as a NaN
        val = NaN;
        % Exit
        return
    end
    
    %% Find the threshold value
    % Default is an acceptable input and will just return what was uploaded by Threshold
    % Exporter as the Default threshold values
    
    % If the specified family couldn't be found in the threshold information
    if ~isfield(obj.cals,family)% || strcmp('All',family)
        % Capture the input family name
        inputFam = family;
        % If there is a Default family
        if isfield(obj.cals,'Default');
            % Fall back to the default values
            family = 'Default';
        else
            % Get the list of possible families
            fieldNames = fields(obj.cals);
            % Just use the first one so something will be returned
            family = fieldNames{1};
        end
        % Throw a warning that a different family was used
        %warning('Capability:getSpecValue:InvalidFamily','Could not find threshold value for the family specified as ''%s'' so the value from ''%s'' was used instead.',inputFam,family)
    end
    
    try
        % If this is a single value (a field of the specific cal structure)
        if isfield(obj.cals.(family), specStr)
            % Get the value the easy way with a dynamic field name
            val = obj.cals.(family).(specStr);
        else
            % Do it the hard way, load all calibratibles and call eval
            val = hardWay(obj.cals.(family), specStr);
        end
    catch ex
        % If the parameter wasn't present in the threhsold values
        if strcmp(ex.identifier,'MATLAB:UndefinedFunction')
            % Thow a more meaningful error
            error('Capability:getSpecValue:UndefinedThreshold','The value of ''%s'' couldn''t be found in pre-exported threshold values for the ''%s'' family.',specStr,family);
        else
            % Unknown error, rethrow original exception
            rethrow(ex)
        end
    end
    
end

function val = hardWay(params, specStr)
% This will bring in all the calibratiable values into this function's workspace and
% then call eval to set the value of the spec limit (this is a bass ackwards way)
    
    % Get a listing of parameter present in the structure
    paramList = fieldnames(params);
    
    % For each parameter, load it into this workspace
    for i = 1:length(paramList);
        eval([paramList{i} ' = params.' paramList{i} ';'])
    end
    
    %%--%% Add try-catch to handle better then parameters are missing form the
    %      calibrations mat file
    try
        % Use eval to set the return value to return the calculated value
        eval(['val = ' specStr ';']);
    catch ex
        % If it was an error that 
        if strcmp('MATLAB:UndefinedFunction',ex.identifier)
            % For now throw original exception like the old behavior
            rethrow(ex)
            % Maybe this should be a custom error that gets thrown
            %error('Capability:getSpecValue:NotFound','Description')
            % Atlantic GUI used to silently return a NaN so no line or value is added
            %val = NaN;
        else
            rethrow(ex)
        end
    end
end
