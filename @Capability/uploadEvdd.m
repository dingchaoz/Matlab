function uploadEvdd(obj,fileName)
%Refresh the Event Driven data decoding information for the current database
%   This method finds the spreadsheet that defines the decoding information for the event
%   driven data and updates the values stored in the database for the current database
%   connected to.
%   
%   Usage: uploadEvdd(obj,fileName)
%   
%   Inputs - 
%   fileName: Full path to the file that contains the Evdd information
%   
%   Outputs - None
%   
%   Original Version - Chris Remington - January 17, 2014
%     - Modified from original code and turned into a method of this object
%   Revised - Chris Remington - April 29, 2014
%     - Added input for file name as that should be defined externally
    
    % Check if the file exists first
    if ~exist(fileName,'file')
        % Throw an error
        error('Capability:uploadEvdd','Couldn''t find the excel file ''%s'' the defines the event driven data.',fileName)
    end
    
    % Call xlsread to read in the evdd tab of the spreadsheet
    [~, ~, rawData] =  xlsread(fileName,'evdd');
    % Read in the ignore software versions
    [~, ~, rawData1] = xlsread(fileName,'ignore');
    
    % Set the ouptuts appropriatly
    evdd.xSEID = cell2mat(rawData(2:end,3));
    evdd.Parameter = rawData(2:end,4);
    evdd.PublicDataID = cell2mat(rawData(2:end,5));
    evdd.BNumber = cell2mat(rawData(2:end,6));
    evdd.DataType = rawData(2:end,7);
    evdd.Units = rawData(2:end,8);
    
    % Ignore system error list
    evddIgnore.SEID = cell2mat(rawData1(2:end,1));
    evddIgnore.Error_Name = rawData1(2:end,2);
    evddIgnore.Description = rawData1(2:end,3);
    
    % Delete the existing list
    curs = exec(obj.conn, 'DELETE FROM [dbo].[tblEvdd]');
    close(curs),clear curs
    % Delete the existing list
    curs = exec(obj.conn, 'DELETE FROM [dbo].[tblEvddIgnore]');
    close(curs),clear curs
    
    % Try adding the new data
    try
        % Define the columns of the data
        cols = {'xSEID','Parameter','PublicDataID','BNumber','DataType','Units'};
        % Upload the new data
        fastinsert(obj.conn, '[dbo].[tblEvdd]',cols,evdd);
        
        % Define the columns of the data
        cols1 = {'SEID','Error_Name','Description'};
        % Upload the new data
        fastinsert(obj.conn, '[dbo].[tblEvddIgnore]',cols1,evddIgnore)
        
        % Update the internal values
        obj.evdd = fetch(obj.conn, 'SELECT [xSEID],[Parameter],[PublicDataID],[BNumber],[DataType],[Units] FROM [dbo].[tblEvdd]');
        obj.evddIgnore = fetch(obj.conn, 'SELECT [SEID],[Error_Name],[Description] FROM [dbo].[tblEvddIgnore]');
        
    catch ex
        % Dislay the error
        disp(ex.getReport)
        disp(' ')
        disp('------->Reversing changes and re-uploading the current data / settings')
        % Should a warning be thrown here or not
        
        % Re-delete any existing data that made it in
        curs = exec(obj.conn, 'DELETE FROM [dbo].[tblEvdd]');
        close(curs),clear curs
        % Re-delete any existing data that made it in
        curs = exec(obj.conn, 'DELETE FROM [dbo].[tblEvddIgnore]');
        close(curs),clear curs
        
        % Re-upload the old data to the database (that we knew must have worked)
        fastinsert(obj.conn, '[dbo].[tblEvdd]',cols,obj.evdd)
        fastinsert(obj.conn, '[dbo].[tblEvddIgnore]',cols1,obj.evddIgnore)
    end
end
