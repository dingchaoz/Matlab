function fillFiltPlotInfo(obj, idx)
%Fills the information from the ppi into the filt structure
%   Can be called by the GUI on demand to refresh the information in the filt
%   structure with the currently select plot index
%   
%   Usage: fillFiltPlotInfo(obj, idx)
%   
%   Inputs -
%   idx:     Index inside ppi of the currently selected plot definition
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - October 2, 2012
%   Revised - Chris Remington - February 4, 2014
%     - Added support for FC and new vehcile filtering
    
    % If idx is a NaN, set everything to empty / blank
    if isnan(idx)
        % Set all the relevant fields to a blank
        obj.filt.Name = '';
        obj.filt.SEID = NaN;
        obj.filt.ExtID = NaN;
        obj.filt.FC = NaN;
        obj.filt.CriticalParam = '';
        obj.filt.Units = '';
        obj.filt.LSLName = NaN;
        obj.filt.USLName = NaN;
        obj.filt.software = [NaN NaN];
    else
        % Set everything to the real values of the specified index
        % Set the name of the plot
        obj.filt.Name = obj.ppi.Name{idx};
        % Set the system error id
        obj.filt.SEID = obj.ppi.SEID(idx);
        % Set the Extension ID (NaN for Min/Max data)
        obj.filt.ExtID = obj.ppi.ExtID(idx);
        % Set the fault code
        try
            obj.filt.FC = obj.getFC(obj.ppi.SEID(idx));
        catch ex
            obj.filt.FC = [];
        end
        % Set the critical parameter name
        obj.filt.CriticalParam = obj.ppi.CriticalParam{idx};
        % Set the units of the critical parameter
        obj.filt.Units = obj.ppi.Units{idx};
        % If the LSL value is literally 'null' (as returned by the database toolbox)
        if strcmp('null', obj.ppi.LSL{idx})
            % Set it to a NaN
            obj.filt.LSLName = NaN;
        else
            % Otherwise use the real value
            obj.filt.LSLName = obj.ppi.LSL{idx};
        end
        % If the USL value is literally 'null' (as returned by the database toolbox)
        if strcmp('null', obj.ppi.USL{idx})
            % Set it to a NaN
            obj.filt.USLName = NaN;
        else
            % Otherwise use the real value
            obj.filt.USLName = obj.ppi.USL{idx};
        end
        % Set the software filtering value
        obj.filt.software = [obj.ppi.fromSW(idx) obj.ppi.toSW(idx)];
    end
end
