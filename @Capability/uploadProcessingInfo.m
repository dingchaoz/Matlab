function uploadProcessingInfo(obj,fileName)
%Refresh the Processing / Plot definintions for the current database
%   This method finds the spreadsheet that defines the processing and plot information and
%   updates the values stored in the database for the current database connected to.
%   
%   Usage: uploadProcessingInfo(obj,fileName)
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
        error('Capability:uploadProcessingInfo','Couldn''t find the excel file ''%s'' the defines the processing info.',fileName)
    end
    
    % Read in the the two tabs from the spreadsheet
    % Event Driven data
    [~,~,rawE] = xlsread(fileName,'Event');
    evp.SEID = cell2mat(rawE(3:end,1));
    evp.ExtID = cell2mat(rawE(3:end,2));
    evp.Name = rawE(3:end,3);
    evp.CriticalParam = rawE(3:end,4);
    evp.Units = rawE(3:end,5);
    evp.LSL = rawE(3:end,6);
    evp.USL = rawE(3:end,7);
    evp.fromSW = cell2mat(rawE(3:end,8));
    evp.toSW = cell2mat(rawE(3:end,9));
    evp.famSpecific = cell2mat(rawE(3:end,10));
    % MinMax data
    [~,~,rawM] = xlsread(fileName,'MinMax');
    mmp.SEID = cell2mat(rawM(3:end,1));
    mmp.ExtID = NaN(size(mmp.SEID));       % Generate a blank NaN column as it doesn't apply
    mmp.Name = rawM(3:end,2);
    mmp.CriticalParam = rawM(3:end,3);
    mmp.Units = rawM(3:end,4);
    mmp.LSL = rawM(3:end,5);
    mmp.USL = rawM(3:end,6);
    mmp.fromSW = cell2mat(rawM(3:end,7));
    mmp.toSW = cell2mat(rawM(3:end,8));
    mmp.famSpecific = NaN(size(mmp.SEID)); % Generate a blank NaN columns as it doesn't apply
    
    % Delete the existing list
    curs = exec(obj.conn, 'DELETE FROM [dbo].[tblProcessingInfo]');
    close(curs),clear curs
    
    % Try adding the new data
    try
        % Define the columns of the data
        cols = {'SEID','ExtID','Name','CriticalParam','Units','LSL','USL','fromSW','toSW','famSpecific'};
        % Upload the new data for event driven and min/max
        fastinsert(obj.conn, '[dbo].[tblProcessingInfo]', cols, evp);
        fastinsert(obj.conn, '[dbo].[tblProcessingInfo]', cols, mmp);
        
        % Update the internal values
        obj.ppi = fetch(obj.conn, 'SELECT [SEID],[ExtID],[Name],[CriticalParam],[Units],[LSL],[USL],[fromSW],[toSW],CONVERT(float,[famSpecific]) As famSpecific FROM [dbo].[tblProcessingInfo]');
        % Set null strings to NaN for the LSL and USL for compatibility with other stuff
        obj.ppi.LSL(strcmp(obj.ppi.LSL,'null')) = {NaN};
        obj.ppi.USL(strcmp(obj.ppi.USL,'null')) = {NaN};
        
    catch ex
        % Dislay the error
        disp(ex.getReport)
        disp(' ')
        disp('------->Reversing changes and re-uploading the current data')
        disp('Most likely cause is that one of the plots system error name is exactly the same as another one')
        % Should a warning be thrown here or not???
        
        % Re-delete any existing data that made it in
        curs = exec(obj.conn, 'DELETE FROM [dbo].[tblProcessingInfo]');
        close(curs),clear curs
        
        % Re-upload the old data to the database (that we knew must have worked)
        fastinsert(obj.conn, '[dbo].[tblProcessingInfo]',cols,obj.ppi)
    end
end
