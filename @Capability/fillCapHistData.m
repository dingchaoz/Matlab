function fillCapHistData(obj)
    sw = obj.filt.software;
    date = obj.filt.date;
    trip = obj.filt.trip;
    emb = obj.filt.emb;
    % New filtering critera
    engfam = obj.filt.engfam;
    vehtype = obj.filt.vehtype;
    vehicle = obj.filt.vehicle;
    Name = obj.filt.Name;
    
    d = obj.getCapHistData(Name,'software',sw,'date',date,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
    
    % If there was no data for this parameter
    if isempty(d)
        % Throw an error so that the GUI can react and execution of this code stops
        error('Capability:fillCapHistData:NoDataFound', 'No data found for the specified filtering conditions.');
    end
    obj.caphist.PpK = d.PpK;
    obj.caphist.TimePeriod = d.TimePeriod;
    obj.caphist.DataPoints = d.DataPoints;
    obj.caphist.FailureDataPoints = d.FailureDataPoints;
    obj.caphist.TruckName = d.TruckName;
    obj.caphist.CalibrationVersion = d.CalibrationVersion;
    obj.caphist.StartDateStr = d.StartDateStr;
    obj.caphist.EndDateStr = d.EndDateStr;
end
