/* This script compares the MDL with the processing list and outputs the list of diagnostics that are required 
per the MDL but is not listed in the processing list*/
select * from

(select * from

(
Select  Error_Name from tblMDLInfo except
Select  distinct Error_Name
--,SEID
--, Name 
from tblProcessingInfo   join
tblErrTable on tblProcessingInfo.SEID = tblErrTable.Error_Table_ID
) as temptbl
except select * from .tblMDLIgnore) as tbl
where Error_Name NOT LIKE 'J39_%'

