:: The bat file automatically pulls the latest Capability scripts and calls CapabilityUploadScript.m from
:: C:\Users\kz429\data crunching\GUI code\codeNew on Yiyuan's workstation W4-S128450 from the command line to run the capability upload script.
:: This bat file is run via the task scheduler
:: Author : Yiyuan Chen; Date: 2014/09/16

:: change the directory to C:\Users\kz429\data crunching\GUI code\codeNew
:: d:
:: cd Users\kz429\data crunching\GUI code\codeNew
cd data crunching\GUI code\codeNew

git.exe pull origin master
git.exe pull --tags origin master

:: Call Matlab script
matlab -r CapabilityUploadScript