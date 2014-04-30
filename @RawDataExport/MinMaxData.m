function MinMaxData(obj, dir)
%Exports all MinMax data from the database to Excel Files and Mat Files
%   This rountine will look for a listing of all parameters with data in tblMinMaxData.
%   It will then pull each parameters's worth of data from the database and save the raw
%   data into both an excel spreadsheet and a .mat file
%   
%   Usage: MinMaxData(obj, dir)
%   
%   Inputs -
%   dir:      Location of the base directory where the files should be stored
%   
%   Outputs -
%   none
%   
%   Original Version - Chris Remington - March 27, 2012
%   Revisied - Chris Remington - Septmeber 17, 2012
%       - Modified to call a single function of each parameter of data to be exported
    
    % Get a list of all PublicDataID values present in the database
    d = fetch(obj.conn, ...
        'SELECT DISTINCT [PublicDataID] FROM [dbo].[tblMinMaxData] WHERE [EMBFlag] = 0 ORDER BY [PublicDataID]');
    
    % Turn the xlswrite AddSheet warnings off
    warning('off','MATLAB:xlswrite:AddSheet')
    
    % Loop through the list, exporting each parameter worth of data
    for i = 1:length(d.PublicDataID)
        % Try to export this parameter of data
        try
            obj.SingleMinMaxData(d.PublicDataID(i), dir)
        catch ex
            % Print that an error occured
            fprintf('Error exporting parameter %.0f\n',d.PublicDataID(i))
            % Display the error report and move on
            disp(getReport(ex))
        end
    end
    
    % Turn the xlswrite AddSheet warnings back on
    warning('on', 'MATLAB:xlswrite:AddSheet')
    
end
