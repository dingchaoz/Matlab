%  This script is intended to load selected parameters in the data loggers
%  screen 0 to the database.
% Author : Sri Seshadri
% History : 2015-09-14
classdef Screen0Uploader < CapabilityUploader
    properties (SetAccess = protected)
        %       List of parameters that we would like to get from matfile
        parameterlist
        %         path where the mat files reside.
        MatFilespath
        %         last file attempted to parse. file may have been successfully
        %         parsed (ends up in the processed files bucket or in the error
        %         files bucket.
%         lastfileparsed
        %         list of errored files that need to be re-processed.
        errorlist
          lastfileparsed
        
    end %  properties (SetAccess = protected)
      
        % The program name currently connect to
      
 
    methods % constructor method
        function obj= Screen0Uploader(program)
            
            if ~exist('program','var')
                % Default to Pacific
                program = 'HDPacific';
                
            end % if ~exist('program','var')
            obj = obj@CapabilityUploader(program);
            %% set MatFilespath
            matfilepath_map = {'Acadia'          '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\Acadia\MatData';...
                'HDPacific'       '\\CIDCSDFS01\EBU_Data01$\NACTGx\fngroup_ctc\ETD_Data\Pacific\MatData';...
                'Seahawk'         '\\CIDCSDFS01\EBU_Data01$\NACTGx\mrdata\Seahawk\FieldTest_Dragnet';...
                };
            idx = strcmp(program,matfilepath_map(:,1));
            obj.MatFilespath = char(matfilepath_map(idx,2));
            obj.lastfileparsed = lastfileparsed;
        end % function obj= Screen0Uploader(program)
    end % methods
    
    methods %(Access = protected)
        function obj = set.lastfileparsed(obj,in)
%             Code goes here 
            obj.lastfileparsed = '2015-09-22';
        end
    end
    
end % classdef Screen0 < CapabilityUploader