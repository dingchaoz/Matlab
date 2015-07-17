
@REM Master Diagnostics List - SQL update
@REM 22nd Jan 2015
@echo Updating MDL Script
@echo off
SET SCRIPTFILE="D:\OBD\scripts\Capability\UploadMDLInfoCapDBx.m"
SET MATLABEXE="C:\Software\Mathworks\Matlab_All_Products_2013B_PSP_71\bin\matlab.exe"
SET LOGFILE="D:\OBD\MDLUpdatelog"
SET Update=false
IF EXIST %SCRIPTFILE% IF EXIST %MATLABEXE% SET Update=true
IF "%Update%"=="true" (
%MATLABEXE% -nosplash -nodesktop -minimize -r  "run('%SCRIPTFILE%');exit;" -logfile %LOGFILE%
exit
) else (
@echo File not found : Matlab executable OR MDL Update matlab script > %LOGFILE% 2>&1
)