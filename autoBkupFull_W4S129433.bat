:: This batch file will automatically reorganize all of the 
:: critical indexes in the HDPacific database
:: 
:: This should be run right before a new full back-up is done because this will
:: reorgainze the pages of the database which causes a differential backup to think
:: that more has changed than what actually changed (the data was only moved) and this
:: will cause excessivly sized differential backups.
:: 
:: Chris Remington - November 7, 2012
:: Chris Remington - May 29, 2013
::   - Added tblProcessedFiles to the reorganize club
:: Chris Remington - July 23, 2013
::   - Added the Atlantic database to the backup routine
:: Chris Remington - January 9, 2014
::   - Modified to objectify code somewhat so it works like the IUPR databse back-up code
:: Chris Remington - April 12, 2014
::   - Commented out the second network save directory
:: Chris Remington - April 24, 2014
::   - Modified system databases to each be backed-up to their own files instead of in one file together
:: Dingchao Zhang -  Oct 31th, 2014
::   - Added git pull commands and VanguardArchive in the program
:: Dingchao Zhang -  March 21st, 2016
::   - Changed server name to the new fullfledged server SDWPSQL6001


:::: Definitions for the script
:: Define the server name here
SET SERVERNAME=tcp:SDWPSQL6001\CAPABILITYDB
:: Define the local directory where to save the backup file (must be C: or D: drive) [NEED TRAILING \]
SET LOCALSAVEDIR=C:\Program Files (x86)\SQL\MSSQL11.CAPABILITYDB\MSSQL\Backup
:: Define the network directory where to copy the local file to for safe keeping [NEED TRAILING \]
SET NETWORKSAVDIR=W:\Data Analysis\Storage\W3-A22649_SQLBackups
:: Define the network directory where to copy the local file to for safe keeping [NEED TRAILING \]
::SET NETWORKSAVDIR2=H:\HDE_Pacific\OBD\CapabilitySQLServerBackup\
:: Set the prefix for the filenames so there are no collisions between capability and iupr database backups
SET FILEPREFIX=CAPABILITY_
:: Define the name of all program databases to operate on (with a space between each)
SET PROGRAMS=Atlantic HDPacific Pele Mamba DragonCC DragonMR Seahawk Yukon Blazer Bronco Clydesdale Shadowfax Vanguard Ventura PacificArchive PacificArchive2 Acadia VanguardArchive

:: Pull the latest git from master branch
git.exe pull origin master
git.exe pull --tags origin master


:::: First do the backup of the server level databases (these are so small so they will always be full backups)
:: Backup the master database
sqlcmd -S %SERVERNAME% -E -Q "BACKUP DATABASE [master] TO DISK='%LOCALSAVEDIR%%FILEPREFIX%master.bak' WITH INIT,  NAME = 'master System DB Backup';"
:: Backup the model database
sqlcmd -S %SERVERNAME% -E -Q "BACKUP DATABASE [model] TO DISK='%LOCALSAVEDIR%%FILEPREFIX%model.bak' WITH NAME = 'model System DB Backup';"
:: Backup the msdb database
sqlcmd -S %SERVERNAME% -E -Q "BACKUP DATABASE [msdb] TO DISK='%LOCALSAVEDIR%%FILEPREFIX%msdb.bak' WITH NAME = 'msdb System DB Backup';"
:: Copy this file to the network location
xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%master.bak" "%NETWORKSAVDIR%"
xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%model.bak" "%NETWORKSAVDIR%"
xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%msdb.bak" "%NETWORKSAVDIR%"
:: Copy this file to the network location 2
::xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%master.bak" "%NETWORKSAVDIR2%"
::xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%model.bak" "%NETWORKSAVDIR2%"
::xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%msdb.bak" "%NETWORKSAVDIR2%"


:::: For each engine program database that is defined in the definitions
::: Do the index reorganizing before the full backup
:: Reorganize the indexes on [dbo].[tblEventDrivenData]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblEventDrivenData] REORGANIZE"
:: Reorganize the indexes on [dbo].[tblMinMaxData]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblMinMaxData] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblDataInBuild]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblDataInBuild] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblErrorTable]
::FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblErrorTable] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblErrTable]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblErrTable] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblEvdd]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblEvdd] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblMDL]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblMDL] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblMinMaxDataConditions]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblMinMaxDataConditions] REORGANIZE"
:: Reorgainze the indexes on [dbo].[tblProcessedFiles]
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "ALTER INDEX ALL ON [dbo].[tblProcessedFiles] REORGANIZE"


::: Backup the data and copy to the network
:: Run sqlcmd to backup the databases
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "DECLARE @FullBkName As varchar(40) = ('Full Backup ' + CONVERT(varchar,CONVERT(date,GETDATE()))); BACKUP DATABASE [%%P] TO DISK='%LOCALSAVEDIR%%FILEPREFIX%%%P.bak' WITH INIT, DESCRIPTION = 'Weekly full backup of %%P Capability database', NAME = @FullBkName;"
:: Copy the file to the network share directory
FOR %%P IN (%PROGRAMS%) DO xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%%%P.bak" "%NETWORKSAVDIR%"
:: Copy the file to the network share directory 2
::FOR %%P IN (%PROGRAMS%) DO xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%%%P.bak" "%NETWORKSAVDIR2%"

