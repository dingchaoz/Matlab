/* This script compares the MDL with the processing list and outputs the list of diagnostics that are required 
per the MDL but is not listed in the MDL*/
select * from
(
Select  Error_Name from tblMDLInfo except
Select  distinct Error_Name
--,SEID, Name 
from tblProcessingInfo   join
tblErrTable on tblProcessingInfo.SEID = tblErrTable.Error_Table_ID
) as temptbl
where Error_Name NOT LIKe 'J39%' AND Error_Name NOT LIKE 'J1939%' AND Error_Name NOT LIKE '%_DATA_LOST%'
--AND Error_Name NOT LIKE '%_DATA_LOST%'
--order by SEID ASC
