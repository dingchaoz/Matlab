:: The bat file automatically calls CapabilityUpdatePpk.m from
:: C:\Users\kz429\data crunching\GUI code\codeNew on Yiyuan's workstation W4-S128450 from the command line to run the capability upload script.
:: This bat file is run via the task scheduler
:: Author : Yiyuan Chen; Date: 2014/09/16

:: change the directory to C:\Users\kz429\data crunching\GUI code\codeNew
:: d:
:: cd Users\kz429\data crunching\GUI code\codeNew
cd data crunching\GUI code\codeNew

:: Call Matlab script
matlab -r CapabilityUpdatePpk