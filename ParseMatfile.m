% This function is used to gather specified data from a specified truck's mat
% files (mat files made available by the data logger team (Rohit Reddy
% Tammanagiri)
% USE:
%       data = ParseMatfile(path,startdate,enddate,varargin)
% Where:
%       path      = path where the matfiles reside as string
%       startdate = date (yyyy-mm-dd) from which data is required as string
%       enddate   = date after which data is NOT required as string
%       varargin  = takes parameter(s) of interest that are logged in any
%                   given screen of a logger as a string. One parameter per
%                   argument - as string.
%       data      = Matrix with data for each parameter in a column in the
%                   order in which the parameter names were passed into the function
%                   and also the dataDateNum parameter.
% Example:
%          data = ParseMatfile(path,startdate,enddate,'V_PMSC_mg_PMFE_SootAllow','V_ATP_ec_PMSC_Out');
% Author :
%           Sri Seshadri; Group leader Diagnotics Data analysis 11th August 2015

function [data] = ParseMatfile(path,startdate,enddate,varargin)
%% converting dates into a foramt that suits the filename of the mat files
Syymmdd = regexprep(datestr(startdate,25),'/','');
Eyymmdd = regexprep(datestr(enddate,25),'/','');
%% initalizing variables
data = [];
datenumber =[];
len = [];
for varcount = 1:length(varargin)
    eval(['parameter',num2str(varcount),'= [];'])
end % for varcount = 1:length(varargin)
%% Looping through the matfiles in the specified path to gather data
foldercontents = dir(fullfile(path,'*.mat'));
for i = 1:length(foldercontents)
    filename = foldercontents(i).name;
    nameparts = toklin(filename,'_');
    datestrmat = nameparts(end);
    datestrg = toklin(char(datestrmat),'.');
    daten = str2num(datestrg{1});
    flag = 0;
    if daten >= str2num(Syymmdd) && daten <= str2num(Eyymmdd)
        disp(['Processing ' filename])
        load(fullfile(path,filename));
        %% clear parameteres that are input via the varargin when not all the parameters requested are not available in the mat file
        for j = 1 : nargin-3
            if ~exist(char(varargin{j}),'var')
                if j==1
                    continue
                else
                    for ct = length(varargin):-1:1
                        if exist(char(varargin{ct}),'var')
                            eval(['clearvars ' char(varargin{ct})]);
                        end % if exist(char(varargin{j}),'var')
                    end % for ct = length(varagin):-1:2
                    disp(['skipping ' filename])
                    flag = 1;
                    break
                end % if j==1
            end % ~exist(char(varargin{j}),'var')
        end % for j = 4 : nargin
        
        %% create variables such as parameter1 through parameter n where n = length of varargin
        if ~flag
            for k = 1: nargin - 3
                if exist(char(varargin{k}),'var')
                    eval(strcat('parameter',num2str(k),' = ','[parameter',num2str(k),';',' eval(char(varargin(k)))];')); % gets the parameter values stored
                end % if exist(char(varargin{k}),'var')
            end
            
            %% checking if the lengths of the parameters requested aare identical
            for m = 1: length(varargin)
                len = [len  eval(['length(parameter',num2str(m),')',char(39)])];
            end % for m = 1: length(varargin)
            
            if min(len)==max(len)
                datenumber = [datenumber; repmat(dataDateNum',length(eval('eval(varargin{1})')),1)];
                len = [];
            else
                error('You are likely requesting data from multiple logger screens. Please check the input arguments')
            end % if min(len)==max(len)
        end % if flag = 0
    end % if daten >= Syymmdd && daten <= Eyymmdd
    
    
    for l = 1: nargin -3
        if exist(char(varargin{l}),'var')
            eval(['clearvars ' char(varargin{l})]);
        end % if exist(char(varargin{l}),'var')
    end % for l = 1: nargin -3
    
end % foldercontents = dir(fullfile(path,'*.mat'));
%% concatenate required data into a matrix

for varcountA = 1:length(varargin)
    data = [data eval(['parameter',num2str(varcountA)])];
    
end % for varcountA = 1:length(varargin)
data = [data datenumber];
