function updatePrecalcResults(obj)
%Update Ppk calculations in the precalculated database table
%   Update the pre-calculated Ppk results in the database tables [tblDataTruckSw] and
%   [tblTruckTimeSw]
%   
%   Usage: updatePrecalcResults(obj)
%   
%   Original Verison - Chris Remington - December 12, 2013
%   Revised - Chris Remington - December 17, 2013
%     - Hack this to work with datainsert
%     - Added loop to upload data in chunks
%   Revised - Chris Remington - March ??, 2014
%     - Use the engine families as defined in the truck table instead of a hard-coded list
%   Revised - Chris Remington - April 14, 2014
%     - Account for the case where a system error has no data present in the database for
%       any of the engine families
    
    %% Initalize
    % Initalize empty structures
    truckSw = [];
    truckTimeSw = [];
    
    % Initalize empty counters
    rowsTruckSw = 0;
    rowsTruckTimeSw = 0;
    
    % Time
    tic
    
    %% Process System Errors
    % For each system error
    for i = 1:length(obj.ppi.SEID)
        
        % Display the current system error being worked on
        fprintf('Working on SE %s\r',obj.ppi.Name{i})
        
        try
            
            % Get a system error report by truck and software for this system error
            truckSwData = obj.getSEReport(i,1);
            % Get a system error report by truck, time, and software
            truckTimeSwData = obj.getSEReport(i,2);
            
            % If this system error had no data in the database for any engine families
            if isempty(truckSwData) || isempty(truckTimeSwData)
                % Print a messge
                fprintf('=====> No data found for any engine family on %s\r',obj.ppi.Name{i})
                % Continue to the next system error
                continue
            end
            
            % Add the rows returned to the total number of rows
            rowsTruckSw = rowsTruckSw + length(truckSwData.SEID);
            rowsTruckTimeSw = rowsTruckTimeSw + length(truckTimeSwData.SEID);
            
        catch ex
            % Error handling
            % Display the system error
            fprintf('Error on system error %s.\r',obj.ppi.Name{i})
            % Display the Matlab error text
            disp(ex.getReport)
            % For now, continue on to the next system error
            continue
        end
        
        % Concatinate the data for this system error with all of the system errors
        
        % If this is the first family processed
        if isempty(truckSw)
            % Just use the whole output structure
            truckSw = truckSwData;
        else
            % Append each field onto the master structure
            dataFields = fields(truckSw);
            % For each field present
            for j = 1:length(dataFields)
                % Append the data from output onto each field
                truckSw.(dataFields{j}) = cat(1,truckSw.(dataFields{j}),truckSwData.(dataFields{j}));
            end
        end
        
        % If this is the first family processed
        if isempty(truckTimeSw)
            % Just use the whole output structure
            truckTimeSw = truckTimeSwData;
        else
            % Append each field onto the master structure
            dataFields = fields(truckTimeSw);
            % For each field present
            for j = 1:length(dataFields)
                % Append the data from output onto each field
                truckTimeSw.(dataFields{j}) = cat(1,truckTimeSw.(dataFields{j}),truckTimeSwData.(dataFields{j}));
            end
        end
        
    end
    %% Error Checking
    % Make sure each individual entry got added to the final structure
    if length(truckSw.SEID) ~= rowsTruckSw
        % Throw an error
        error('EventProcessor:DataLengthMatchError','The sum of the length of the resutls for data grouped by truck and software don''t match the length of the final data set.')
    end
    if length(truckTimeSw.SEID) ~= rowsTruckTimeSw
        % Throw an error
        error('EventProcessor:DataLengthMatchError','The sum of the length of the resutls for data grouped by truck, time, and software don''t match the length of the final data set.')
    end
    
    % Display processing time
    disp('Time to get results from the database.');
    toc
    
    %% Delete Existing Data
    tic
    % Turn autocommit off to do this all at once
    % Skip this for now, may want to add this later
    %set(obj.conn,'AutoCommit','off')
    
    % Delete from tblDataTruckSw
    curs = exec(obj.conn, 'DELETE FROM [dbo].[tblDataTruckSw]');
    close(curs)
    
    % Delete from tblDataTruckTimeSw
    curs = exec(obj.conn, 'DELETE FROM [dbo].[tblDataTruckTimeSw]');
    close(curs)
    
    %% Format data for upload
    
    % Convert to cell array for datainsert
    uploadTruckSw = convertToCell(truckSw);
    % Sort the rows like the database index so it hopefully uploads faster
    uploadTruckSw = sortrows(uploadTruckSw,[12 2 1]);
    
    % Convert to cell array for datainsert
    uploadTruckTimeSw = convertToCell(truckTimeSw);
    % Sort the rows like the database index so it hopefully uploads faster
    uploadTruckTimeSw = sortrows(uploadTruckTimeSw,[13 3 9 2]);
    
    disp('Time to delete old data and format/sort new data')
    toc
    
    %% Upload New Data
    
    % Define the incement to upload data in
    inc = 10000;
    
    tic
    %fastinsert(obj.conn,'[dbo].[tblDataTruckSw]',fields(truckSw),uploadTruckSw);
    %datainsert(obj.conn,'[dbo].[tblDataTruckSw]',fields(truckSw),uploadTruckSw);
    % Upload data to tblDataTruckSw
    for i = 1:floor(size(uploadTruckSw,1)/inc)
        % Upload this chunk
        fastinsert(obj.conn,'[dbo].[tblDataTruckSw]',fields(truckSw),uploadTruckSw((i-1)*inc+1:i*inc,:));
    end
    % If data was smaller then inc size, change i from empty to 0
    if isempty(i),i = 0;end
    % Upload the final chunk
    fastinsert(obj.conn,'[dbo].[tblDataTruckSw]',fields(truckSw),uploadTruckSw(i*inc+1:end,:));
    % Monitor the upload time
    disp('Upload TruckSw');toc
    
    tic
    % Upload data to tblDataTruckTimeSw
    %fastinsert(obj.conn,'[dbo].[tblDataTruckTimeSw]',fields(truckTimeSw),uploadTruckTimeSw);
    %datainsert(obj.conn,'[dbo].[tblDataTruckTimeSw]',fields(truckTimeSw),uploadTruckTimeSw);
    for i = 1:floor(size(uploadTruckTimeSw,1)/inc)
        % Upload this chunk
        fastinsert(obj.conn,'[dbo].[tblDataTruckTimeSw]',fields(truckTimeSw),uploadTruckTimeSw((i-1)*inc+1:i*inc,:));
    end
    % If data was smaller then inc size, change i from empty to 0
    if isempty(i),i = 0;end
    % Upload the final chunk
    fastinsert(obj.conn,'[dbo].[tblDataTruckTimeSw]',fields(truckTimeSw),uploadTruckTimeSw(i*inc+1:end,:));
    % Monitor the upload time
    disp('Upload TruckTimeSw');toc
    
    % Turn on Autocommit
    % Skip this for now, may want to add this later
    %set(obj.conn,'AutoCommit','on')
    
end

function output = convertToCell(structInput)
%Convert structure data into a cell array for 
    
    % Find the field names
    fieldNames = fields(structInput);
    
    % Initalize the cell array
    output = cell(length(structInput.(fieldNames{1})),length(fieldNames));
    
    % Fill in the data to the cell array
    for i = 1:length(fieldNames)
        % If it is a cell array already
        if strcmp(fieldNames{i},'StartDate')
            % Use the StartDateStr field instead for compatibility with datainsert
            output(:,i) = structInput.StartDateStr;
        elseif strcmp(fieldNames{i},'EndDate')
            % Use the EndDateStr field instead for compatibility with datainsert
            output(:,i) = structInput.EndDateStr;
        elseif strcmp(fieldNames{i},'Units')
            % Add a space pad to the end of units to account for bug in datainsert
            output(:,i) = strcat(structInput.Units,{' '});
        elseif iscell(structInput.(fieldNames{i}))
            % Assign the data
            output(:,i) = structInput.(fieldNames{i});
        else
            % Convert to cell array and assign
            output(:,i) = num2cell(structInput.(fieldNames{i}));
        end
    end
    
%     % Check for bad inputs that aren't compatible with datainsert
%     for i = 1:numel(output)
%         % Check for NaN values
%         if isnan(output{i})
%             % Convert NaN to ''
%             output{i} = '';
%         elseif length(output{i}) == 1 && ischar(output{i})
%             % Add a space so single character strings, datainsert chokes on this
%             output{i} = [output{i} ' '];
%         end
%     end
    
end
