
function writeEvddIgnore3(SEID,fullFileName, truckID, obj)

% Purpose:write into report the number of times evdd ignore occurs
% Usage:inputs are SEID, fullfileName which is already input through
% Addcsv, truckID and the capabilityUploader object
% Where: SEID=seid, as matrix (1x1)
% program=database name as string
% example:writeEvddIgnore2(13048,'Y:\MinMaxData\DragonMR\DNET_Hunkes_Transfer\LCDv5005_1449900985_MinMax_12-12-2015_06-14-04-AM.log',2, obj)
% author: Blaisy Rodrigues
% Date: 13-Dec-2015


%get file date and time from file name
splitFullFileName=toklin(fullFileName,'\');
fileName=splitFullFileName(length(splitFullFileName));
splitFileName=toklin(cell2mat(fileName),'_');
FileDate=splitFileName(length(splitFileName)-1);
FileTimeExt=splitFileName(length(splitFileName));
splitFileTime=toklin(cell2mat(FileTimeExt),'.');
FileTime=splitFileTime(1);

% names of files to read/create
countReportPath=strcat('..\capbility_logs\',obj.program);
ReportName=strcat('evddIgnoreRpt_',obj.program,'.xlsx');
RptName=strcat('evddIgnoreRpt_',obj.program);
countReportfullFile=fullfile(countReportPath,ReportName);
countReportfullFile2=fullfile(countReportPath,RptName);
 





fid1=fopen(countReportfullFile, 'r');
if fid1<0
% if file doesn't exist, then create the first file's contents (because you can't read the file as in the else below)
	SEIDEvddIgnore=SEID;
	SEIDEvddIgnoreCount=1;
	TruckID=truckID;
	StartDate=strcat(FileDate, ' ',FileTime);
	EndDate=strcat(FileDate, ' ',FileTime);
    sizeEI=length(SEIDEvddIgnore);
%  fid2=fopen(countReportfullFile, 'w');
%  if fid2<0
%      error(['Unable to open' ReportName 'report file'])
%  end %if fid2<0
%  if fid2>=0 
%      fclose (fid2);
%  end
    
else

%    [num,txt,dataRead] = xlsread('C:\Users\nn732\Documents\CapabilityGUI\capbility_logs\DragonMR\evddIgnoreRpt_DragonMR.xlsx');
    [num,txt,dataRead] = xlsread(countReportfullFile);
	%dataRead=importdata(countReportfullFile);
    system('taskkill /F /IM EXCEL.EXE');
	SEIDEvddIgnore=cell2mat(dataRead(2:end,[1]));
	SEIDEvddIgnoreCount=cell2mat(dataRead(2:end,[2]));
	TruckID=cell2mat(dataRead(2:end,[3]));
	StartDate=dataRead(2:end,[4]);
	EndDate=dataRead(2:end,[5]);
    
	sizeEI=length(SEIDEvddIgnore);

	if ~any(SEID==SEIDEvddIgnore) 
        
	  SEIDEvddIgnore(sizeEI+1)=SEID;
	  SEIDEvddIgnoreCount(sizeEI+1)=1;
	  TruckID(sizeEI+1)=truckID;
	  StartDate(sizeEI+1)=strcat(FileDate, ' ',FileTime);
	  EndDate(sizeEI+1)=strcat(FileDate,' ',FileTime);
	else
	  idx=find(SEID==SEIDEvddIgnore);
      TruckIDForThisSEID=TruckID(idx);
      
         if  ~any(truckID==TruckIDForThisSEID)
           SEIDEvddIgnore(sizeEI+1)=SEID;
	       SEIDEvddIgnoreCount(sizeEI+1)=1;
	       TruckID(sizeEI+1)=truckID;
	       StartDate(sizeEI+1)=strcat(FileDate, ' ',FileTime);
	       EndDate(sizeEI+1)=strcat(FileDate,' ',FileTime);
      
         else
             
	     SEIDEvddIgnoreCount(idx)=SEIDEvddIgnoreCount(idx)+1;
	     TruckID(idx)=truckID;
	     EndDate(idx)=cellstr(cell2mat(horzcat(FileDate,' ',FileTime)));
      
         end %if  ~any(truckID==TruckIDForThisSEID)
    
    end %~any(SEID==SEIDEvddIgnore)
    
end %if fid2<0

sizeEI2=length(SEIDEvddIgnore);

% if fid1>=0 
%     fclose (fid1);
% end
% 
% fid2=fopen(countReportfullFile, 'w');
% if fid2<0
%     error(['Unable to open' ReportName 'report file'])
% end %if fid2<0
% 
% 
% if fid2>=0 
%     fclose (fid2);
% end

%fprintf(fid2, 'SEIDIgnore\t');


%fprintf(fid2, 'Count \r\n\r\n');
% StartDate=char(StartDate);
% EndDate=char(EndDate);
% sd=size(StartDate);
% ed=size(EndDate);
% for i=1:sd(1)
%     StDate(i)=StartDate(i,:);
% end
% for i=1:3
%     StDate(i)=StartDate(i,:);
% end
% for i=1:ed(1)
%     EDate(i)=EndDate(i,:);
% end
Header={'SEID','EvddIgnoreCount', 'TruckID', 'DateOfFirstFileWithThisSEID','DateOfLastFileWithThisSEID'}; 
writeMatrix=horzcat(SEIDEvddIgnore,SEIDEvddIgnoreCount,TruckID);
xRangeStDate=strcat('D2:D',num2str(sizeEI2+1));
xRangeEdDate=strcat('E2:E',num2str(sizeEI2+1));
xdataRange=strcat('A2:C',num2str(sizeEI2+1));

% for n=1:length(SEIDEvddIgnore)
%     fprintf(fid2,'%i\t%i\t\r\n', SEIDEvddIgnore(n),SEIDEvddIgnoreCount(n));
%      %fprintf(fid2,'\n');
% end

% Excel = actxserver('Excel.Application'); 
% 
% if ~exist(countReportfullFile2,'file') 
% ExcelWorkbook = Excel.Workbooks.Add; 
% ExcelWorkbook.Sheets.Add; 
% ExcelWorkbook.SaveAs(countReportfullFile); 
% ExcelWorkbook.Close(false); 
% end 
% invoke(Excel.Workbooks,'Open',countReportfullFile2);

xlswrite(countReportfullFile,Header,'A1:E1');
xlswrite(countReportfullFile, writeMatrix,xdataRange);
xlswrite(countReportfullFile,StartDate(:),xRangeStDate);
xlswrite(countReportfullFile,EndDate(:),xRangeEdDate);


% invoke(Excel.ActiveWorkbook,'Save'); 
% Excel.Quit 




  


end
