
@REM Master Diagnostics List - SQL update
@REM 22nd Jan 2015
@echo Updating MDL Script
::@echo off
SET SCRIPTFILE="C:\Users\ku906\Documents\CapabilityAutomation\CapabilityGUI\UploadMDLInfoCapDB.m"
SET MATLABEXE="C:\Software\Mathworks\Matlab_All_Products_2010A_PSP_41\bin\matlab.exe"
SET LOGFILE="W:\Data Analysis\Storage\logs\MDLUpdatelog"
SET Update=false
IF EXIST %SCRIPTFILE% IF EXIST %MATLABEXE% SET Update=true
IF "%Update%"=="true" (
%MATLABEXE% -nosplash -nodesktop -minimize -r  "run('%SCRIPTFILE%');exit;" -logfile %LOGFILE%
exit
) else (
@echo File not found : Matlab executable OR MDL Update matlab script > %LOGFILE% 2>&1
)