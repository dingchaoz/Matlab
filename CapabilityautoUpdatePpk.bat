:: The bat file automatically calls CapabilityUpdatePpk.m from D:\Users\kz429\data crunching\GUI code\codeNew on W3-R15471 from
:: the command line to run the capability upload script. This bat file is run via the task scheduler
:: Author : Yiyuan Chen; Date: 2014/06/20

:: change the directory to D:\Users\kz429\data crunching\GUI code\codeNew
d:
cd Users\kz429\data crunching\GUI code\codeNew 

:: Call Matlab script
matlab -r CapabilityUpdatePpk