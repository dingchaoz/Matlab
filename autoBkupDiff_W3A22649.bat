:: HD Pacific SQL Database Backup Batch File - Differential Backup
:: 
:: this script should be executed 6 days a week (every day except days where a full weekly
:: backup is performed) to take a differential backup of HDPacific and to keep the system 
:: level databases master, model, and msdb current
:: 
:: This batch file will preform the following steps:
::  1) Call a sql quary to perform a database backup
::  2) Copy the backup file into the correct location on the M: drive
:: 
:: Chris Remington - September 20, 2012
:: Chris Remington - July 23, 2013
::   - Added the Atlantic database to the differential backup routine
:: Chris Remington - January 9, 2014
::   - Modified to objectify code somewhat so it works like the IUPR databse back-up code
:: Chris Remington - April 12, 2014
::   - Commented out the second network save directory
:: Chris Remington - April 24, 2014
::   - Modified system databases to each be backed-up to their own files instead of in one file together

:::: Definitions for the script
:: Define the server name here
SET SERVERNAME=tcp:W3-A22649\CAPABILITYDB
:: Define the local directory where to save the backup file (must be C: or D: drive) [NEED TRAILING \]
SET LOCALSAVEDIR=D:\SQL\MSSQL10_50.CAPABILITYDB\MSSQL\Backup\
:: Define the network directory where to copy the local file to for safe keeping [NEED TRAILING \]
SET NETWORKSAVDIR=N:\DL_Diag\Data Analysis\Storage\W3-A22649_SQLBackups\
:: Define the network directory where to copy the local file to for safe keeping [NEED TRAILING \]
::SET NETWORKSAVDIR2=H:\HDE_Pacific\OBD\CapabilitySQLServerBackup\
:: Set the prefix for the filenames so there are no collisions between capability and iupr database backups
SET FILEPREFIX=CAPABILITY_
:: Define the name of all program databases to operate on (with a space between each)
SET PROGRAMS=Atlantic HDPacific Pele Mamba DragonCC DragonMR Seahawk Yukon Blazer Bronco Clydesdale Shadowfax Vanguard Ventura


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
:: Run sqlcmd to backup the databases
FOR %%P IN (%PROGRAMS%) DO sqlcmd -S %SERVERNAME% -d %%P -E -Q "DECLARE @DiffBkName As varchar(40) = ('Differential Backup ' + CONVERT(varchar,CONVERT(date,GETDATE()))); BACKUP DATABASE [%%P] TO DISK='%LOCALSAVEDIR%%FILEPREFIX%%%P.bak' WITH DIFFERENTIAL, DESCRIPTION = 'Daily differential backup of %%P Capability database', NAME = @DiffBkName;"
:: Copy the file to the network share directory
FOR %%P IN (%PROGRAMS%) DO xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%%%P.bak" "%NETWORKSAVDIR%"
:: Copy the file to the network share directory 2
::FOR %%P IN (%PROGRAMS%) DO xcopy /y "%LOCALSAVEDIR%%FILEPREFIX%%%P.bak" "%NETWORKSAVDIR2%"

