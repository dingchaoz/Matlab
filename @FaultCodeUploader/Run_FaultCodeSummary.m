loggerMasterList

period = clock;
year = datenum(period(1));
month = datenum(period(2));
prevMonth = month-1;
day = datenum(period(3));
[a,b] = size(loggerList);
for i=1:a
    if strcmp(loggerList{i,1},loggerList{i,2})
        continue
    else
        truckName = char(loggerList(i,2));
    end
    Summary_FC(truckName,year,month);
    if(day <7)
        Summary_FC(truckName,year,prevMonth);
    end
    Summary_FC_Cumulative(truckName);
end
