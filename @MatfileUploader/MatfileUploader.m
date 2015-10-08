classdef MatfileUploader < CapabilityUploader
    properties %(Access = protected)
        parameterlist
        errorlist
        matpath
        lastfileparsed
    end % properties (Access = protected)
    properties (Access = private)
        
        duty
    end
    properties(Dependent)
%         lastfileparsed
%         parameterlist
    end % properties(Dependent)
    properties (Transient)
        addtrucklistener
    end
    methods
%         constructor method
        function obj = MatfileUploader(program,varargin)
            obj = obj@CapabilityUploader(program,varargin{1});
            pathmap = {'Acadia' 'HD' '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\Acadia\MatData'...
                'Seahawk' 'MR' '\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Seahawk'...
                };
            idx = strcmp(program,pathmap(:,1));
            obj.matpath = pathmap{idx,3};
            obj.duty = pathmap{idx,2};
            obj.lastfileparsed = [];
            obj.parameterlist = [];
        end % function obj = MatfileUploader(program)
       
    end % constructor method
    methods 
        function obj = get.lastfileparsed(obj)
            % verify the below code
            date = fetch(obj.conn,['SELECT MAX(datenum)'...
                        'FROM (SELECT datenum,TruckID FROM tblProcessedMatFiles',...
                        'UNION ALL', ...
                        'SELECT datenum FROM tblErrMatFiles) as temptbl']);
                    if isempty(date)
                        disp('No prior data found')
                        obj.lastfileparsed = date;
                    else
                        obj.lastfileparsed = datestr(date,'yymmdd');
                    end
        end
        function obj = set.parameterlist(obj,~)
            % code to query parameterlist goes here
            obj.parameterlist = fetch(obj.conn, ['Select Parameter from tblscreen0parameter'...
                ' where Ignore <> 1']);
            if isempty(obj.parameterlist)
                fprintf('The table "tblscreen0parameter" is empty in %s database. Update table with necessary parameter',...
                    obj.program);
                obj.parameterlist = [];
            end
        end
    end
    methods (Access = protected)
%         method to intialize error log files
        function clearLogFiles(obj)
            obj.networkLogRoot = '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\MinMaxData\MatLogs';
            clearLogFiles@CapabilityUploader(obj)
        end % function clearLogFiles(obj)
        
    end
    methods % get methods goes in here
        function getclearLogFiles(obj,~)
            clearLogFiles(obj);
        end % function getclearLogFiles(obj,~)
        
        function parameterlist = get.parameterlist(obj)
            parameterlist = obj.parameterlist;
        end
    end
    
    methods % methods that are implemented externally goes here
        % read parameters in the tbl Parameter list
        TruckId = obj.addTrucks(obj);
        
    end
    
    
end