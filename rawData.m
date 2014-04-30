function varargout = rawData(varargin)
% RAWDATA M-file for rawData.fig
%      RAWDATA, by itself, creates a new RAWDATA or raises the existing
%      singleton*.
%
%      H = RAWDATA returns the handle to a new RAWDATA or the handle to
%      the existing singleton*.
%
%      RAWDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RAWDATA.M with the given input arguments.
%
%      RAWDATA('Property','Value',...) creates a new RAWDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rawData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rawData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rawData

% Last Modified by GUIDE v2.5 15-Oct-2012 11:48:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rawData_OpeningFcn, ...
                   'gui_OutputFcn',  @rawData_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before rawData is made visible.
function rawData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rawData (see VARARGIN)

% Choose default command line output for rawData
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rawData wait for user response (see UIRESUME)
% uiwait(handles.figRawData);

% Parse input arguments
if ~isempty(varargin)
    % Parse the input arguments
    
    % Set the name of the window
    set(hObject, 'Name', sprintf('%s - SE%.0f',varargin{4},varargin{3}))
    
    % Put the formatted data into the table
    set(handles.tblData, 'Data', varargin{1})
    % Add the column names
    set(handles.tblData, 'ColumnName', varargin{2});
    
    % Add the SEID number
    set(handles.txtSEID, 'String', varargin{3});
    % Add the SE Name
    set(handles.txtSEName, 'String', varargin{4});
    
    % If more than 4 arguments were passed in
    % Can't remember what this was for
    if length(varargin) > 4
        % Add the abs_time value to the userdata for the tblData
        set(handles.tblData, 'UserData', varargin{5});
    end
    
else % no arguments passed in
    % Delete the current windows
    delete(gcf)
    % Display an error message
    msgbox('No data was passed in.','Error','error')
    return
end

% Have to tune on visibility just before the code below so the java handle can be grabbed
set(hObject, 'Visible','on')
% Code from this link: http://undocumentedmatlab.com/blog/uitable-sorting/
% Turns on the internal Java columns sorting column
mtable = handles.tblData;
jscrollpane = findjobj(mtable);
jtable = jscrollpane.getViewport.getView;
% Now turn the JIDE sorting on
jtable.setSortable(true);		% or: set(jtable,'Sortable','on');
jtable.setAutoResort(true);
jtable.setMultiColumnSortable(true);
jtable.setPreserveSelectionsAfterSorting(true);

% If the truck status table was passed in
if any(strcmp('ditw',varargin{2}))
    % Set the columns to be a good starting width for the trucks table
    set(handles.tblData,'ColumnWidth',{200 50 90 90 60 50 70 120 50 70 120 70 70 70})
% Min/Max data was passed in
elseif any(strcmp('Min/Max Set ID',varargin{2}))
    % Set the columns to be a good starting width for Min/Max data
    set(handles.tblData,'ColumnWidth',{50 120 94 200 60 60 92 200 200})
else % Event Driven Data was passed in
    % Set the columns to be a good starting width for Event Driven data
    set(handles.tblData,'ColumnWidth',{50 120 94 200 60 60 200 200 200 200 200 200 200 200})
end

% --- Outputs from this function are returned to the command line.
function varargout = rawData_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    % Return an empty array
    varargout{1} = [];
else
    % Return the valid handle to the main window
    varargout{1} = handles.output;
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when figRawData is resized.
function figRawData_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figRawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the new size of the window
pos = get(hObject, 'Position');

%If the new width is smaller than the minimum allowed
if pos(3) < 420
    % Set the size back to the original size
    set(hObject, 'Position', [pos(1) pos(2) 420 pos(4)]);
    % Update the position
    pos = get(hObject, 'Position');
end
%If the new height is smaller than the minimum allowed
if pos(4) < 125
    % Set the size back the the original size
    set(hObject, 'Position', [pos(1) pos(2) pos(3) 125]);
    % Update the position
    pos = get(hObject, 'Position');
end
% Set the new position of the lblSEID and txtSEID
set(handles.lblSEID, 'Position', [10 pos(4)-27 31 14]);
set(handles.txtSEID, 'Position', [42 pos(4)-31 51 21]);
% Set the new position of the lblSEName and txtSEName
set(handles.lblSEName, 'Position', [98 pos(4)-27 72 14]);
set(handles.txtSEName, 'Position', [170 pos(4)-31 241 21]);
% Set the new position of the tblData
set(handles.tblData, 'Position', [10 10 pos(3)-19 pos(4)-50]);


function txtSEID_Callback(hObject, eventdata, handles)
% hObject    handle to txtSEID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSEID as text
%        str2double(get(hObject,'String')) returns contents of txtSEID as a double


% --- Executes during object creation, after setting all properties.
function txtSEID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSEID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtSEName_Callback(hObject, eventdata, handles)
% hObject    handle to txtSEName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSEName as text
%        str2double(get(hObject,'String')) returns contents of txtSEName as a double


% --- Executes during object creation, after setting all properties.
function txtSEName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSEName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('Debugging');
