:: Jacky Zhang - Oct 2, 2014
:: Batch the linkedserver IUPR query to update tbltruck's IUPR data receving monitoring related columns 


:::: Definitions for the script
:: Define the server name here
SET SERVERNAME=tcp:W4-S129433\CAPABILITYDB
:: Define the name of all program databases to operate on (with a space between each)
SET PROGRAMS=Atlantic HDPacific Pele Mamba DragonCC DragonMR Seahawk Yukon Blazer Bronco Clydesdale Shadowfax Vanguard Ventura PacificArchive PacificArchive2 Acadia

:: Run sqlcmd to query linkedserver to update tbltruck's IUPR related info in the databases
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "exec IUPR_update"
:: Generet batch run logs for exmamination
autoBkupFull_W4S129433.bat > testlog_Full.txt 2>&1t
