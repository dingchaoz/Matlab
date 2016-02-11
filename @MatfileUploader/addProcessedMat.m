%This will update the table tblProcessedMatFiles
% Author - Dingchao Zhang, 2/2/2016

function  addProcessedMat(obj, file,filepath,truckID,mth,yr)

   
   % Get the latest processed FileID and increment by 1
%     LastFileID = fetch(obj.conn, sprintf('SELECT max ([FileID]) FROM [dbo].[tblProcessedMatFiles]')); 
%     FileID = LastFileID.x + 1;
%     obj.FileID = FileID;
    
    % Convert from cell array to number so the yr and mth can be inserted
    % into db
%     yr = str2num(cell2mat(yr));
%     mth = str2num(cell2mat(mth));

    try
        % Insert the new vehicle into the tblTrucks table
        fastinsert(obj.conn, '[dbo].[tblProcessedMatFiles]', ...
            {'TruckID','FileName','Year','Month','FilePath'}, ...
            {truckID,file,yr,mth,filepath})
    catch ex
        % If it was a duplicate truck error
        if ~isempty(strfind(ex.message,'Cannot insert duplicate key row in object'))
            % Catch the exception for index violation and send a more meaningful error
            error('CapabilityUploader:addTruck:Duplicate','The truck %s is already present in tblTrucks.',truckName)
        else
            % Rethrow the original exception
            rethrow(ex)
        end
    end
    

    
end
