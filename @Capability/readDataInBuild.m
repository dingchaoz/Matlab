function data = readDataInBuild(obj, fileName, cal)
%Read in raw datainbuild file and properly format output into cell matrix
%   This function will read the raw contents of a datainbuild.csv file
%   from the C2ST and parse it's contents into a cell matrix (which can
%   then be added to the database easily)
%   Input---
%   fileName:  Path to the datainbuild.csv file that be read
%   cal:       Calibration number of the datainbuild.csv file (this will
%                  be repeaded in a column of the output for filtering in
%                  the database later).
%   
%   Output--- Cell matrix of the entire contents of the datainbuild file
%   
%   Original Version - Chris Remington - January 10, 2011
%   Revised - N/A - N/A - TO DO: tune this up to be faster by using sscanf!
%   Revised - Chris Remington - September 13, 2012
%       - Modified code to account for the two additional columns that were added to the
%         datainbuild.csv file around about the end of June.
%   Revised - Chris Remington - October 2, 2012
%       - Modified for an additional column added after the last "Datavdesc"
%   Revised - Chris Remington - December 17, 2012
%       - Modified for the additional column that I requested to be added and to account
%         for the column reorganization at the end
%       - Changed some fundamental opperation wherein it will now replace instances of ","
%         with a pipe character | to use instead as a delimiter. This was needed as there
%         are some fileds whose values contain commas, confusing textscan when it attempts
%         to read in the line and messing up the columns
%   Revised - Yiyuan Chen - 2015/06/09
%       - Modified to rectify bad cells recognized by Matlab due to shifted columns in 
%         Ayrton's datainbuild file 
%   Revised - Yiyuan Chen - 2015/07/16
%       - Modified to skip the extra column "OverrideSubfileNumber" in datainbuild.csv of some new softwares
    
    % Open the file for reading
    fid = fopen(fileName); % addDataInBuild already checks for a valid file
    
    % Read the header line to get the cursor in the proper position
    header = fgetl(fid);
 
    % Some new softwares has an extra column "OverrideSubfileNumber" in datainbuild.csv
    
    hdcommaidx = find(header==',');
    orgheader = header; % save the original header (it's used later to check if it's a new header) 
    if strcmp(header(hdcommaidx(21)+1 : hdcommaidx(22)),'"OverrideSubfileNumber",')
        header = [header(1 : hdcommaidx(21)), header(hdcommaidx(22)+1 : end)]; % use the older header
    end
    
    % Count the number of commas in the header to check the number of columns
    % If there aren't 34 columns of data present
    if sum(header==',') ~= 33
        % Thow an error as a column was added or removed
        error('Capability:readDataInBuild:NumColumns', ...
        'Found %.0f columns in the datainbuild.csv file but expected 34 columns.', sum(header==',')+1)
    end
    
    % Read in the meat of the text
    % Initialize the cell array to contain the data
    rawData = cell([30000 1]);
    % Junk initalizations
    line = 'a';
    lineNumber = 1;
    % While we aren't at the end of the file
    while ischar(line)
        % Read the file, putting each line into a cell array of strings
        % Use fgets to keep the termination charachters
        line = fgets(fid);
        % If the line is not empty and starts with a quote, keep it, otherwise skip it
        if ~isempty(line) && line(1)=='"'
            % If there is a line-feed on the end like there should be
            if line(end)==char(10)
                % Remove the line-feed from the end
                line = line(1:end-1);
            % If there is a charriage return on the end (from the datavdesc field)
            % This happened when some of the description fields got filled with improper
            % characters
            elseif line(end)==char(13)
                % Get the next line and check if it has a charriage return
                line2 = fgets(fid);
                % If the ending is a charriage return
                if line2(end)==char(13)
                    % Try one last time to read in another line
                    line3 = fgets(fid);
                    % cat all three together
                    line = [line line2 line3];
                else
                    % Cat the first two line together
                    line = [line line2];
                end
                % Remove all new line characters from the line
                line = line(line~=char(10)&line~=char(13));
            end

            % some softwares have an extra column in datainbuild, which should be skipped
            commaidx = find(line==',');
            if strcmp(orgheader(hdcommaidx(21)+1 : hdcommaidx(22)),'"OverrideSubfileNumber",') 
                % if the original header has "OverrideSubfileNumber", skip its value
                line = [line(1:commaidx(21)), line(commaidx(22)+1 : end)];
            end            
            
            % Set the line in the raw data, replacing instances of '","' with a non-printing group separator cahracter
            % Trim the leading and trailing quotation mark " from the line, too
            rawData{lineNumber} = regexprep(line(2:end-1),'","',char(29));
            % Increment the line number counter
            lineNumber = lineNumber + 1;
        end
    end
    
    % Close the file because it's been fully read
    fclose(fid);
    % Trim the unsued cells that were initalized
    rawData = rawData(1:(lineNumber-1));
    
    %% Parse the data from the lines into a mater cell array
    % Initalize the cell array matrix that will contain each piece of data
    % in it's own cell (this makes it easier for the database toolbox to
    % add this to a database)
    data = cell([length(rawData) 35]);
    
    % For each line of formatted data (with pipes added)
    for i = 1:length(rawData)
        % Read in each column using the group separator character as the delimites
        oneRow = textscan(rawData{i}, '%s %s %s %s %n %n %n %s %s %s %n %s %s %s %n %n %s %s %s %n %n %s %n %n %n %n %s %s %n %s %s %s %n %s', 'delimiter', char(29));
        
        % Since textscan is only doing one line at a time and returns
        % strings inside of a cell array, each char vector is contined in a
        % cell, which is then put into another cell. This is not desired
        % behavior.
        % For each column in the datainbuild (except for the descriptions)
        for j = 1:34
            % If there's a cell in a cell
            if iscell(oneRow{j}) && ~isempty(oneRow{j})
                try % Get rid of that cell
                    data(i,j) = oneRow{j};
                catch ME
                    if strcmp(obj.program, 'Ayrton')
                        % There is a 2*1 cell in the 1st cell of oneRow, due to 
                        % the shifted cell in Column 35 in some Ayrton datainbuild files
                        oneRow{34} = {oneRow{1}{2}};
                        oneRow{1} = {oneRow{1}{1}};
                        data(i,j) = oneRow{j};
                    else
                        % For other programs, skip & display the error msg
                        error(ME.message)
                    end
                end
            % Elseif there's an empty cell in a cell
            elseif iscell(oneRow{j}) && isempty(oneRow{j})
                % Set to empty char array
                data{i,j} = '';
            else
                % Just keep this cell as it is, reassign it to the right place
                data(i,j) = oneRow(j);
            end
        end
    end
    
    %% Finish-up by adding a calibration version column on the end
    
    % Add the calibration to the 35th column (constant across all rows)
    % This will allow multiple datainbuild files to be placed in the same
    % table
    data(:,35) = num2cell(linspace(cal,cal,length(rawData))');
    
end
