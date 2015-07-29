function varargout = CapabilityGUI(varargin)
% CAPABILITYGUI M-file for CapabilityGUI.fig
%      CAPABILITYGUI, by itself, creates a new CAPABILITYGUI or raises the existing
%      singleton*.
%
%      H = CAPABILITYGUI returns the handle to a new CAPABILITYGUI or the handle to
%      the existing singleton*.
%
%      CAPABILITYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAPABILITYGUI.M with the given input arguments.
%
%      CAPABILITYGUI('Property','Value',...) creates a new CAPABILITYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CapabilityGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CapabilityGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CapabilityGUI

% Last Modified by GUIDE v2.5 14-Apr-2014 14:03:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CapabilityGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CapabilityGUI_OutputFcn, ...
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

% -----------------------------------------------------------------------------

% --- Executes just before CapabilityGUI is made visible.
function CapabilityGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CapabilityGUI (see VARARGIN)

% Choose default command line output for CapabilityGUI
handles.output = hObject;
% UIWAIT makes CapabilityGUI wait for user response (see UIRESUME)
% uiwait(handles.mainWindow);

% Check that the necessary Matlab Toolboxes are installed on the user's machine
v = ver;               % Get toolbox information
toolbox = {v(:).Name}; % Strip off the toolbox names
% If Matlab is older than 2015a, the matlab version will be smaller
    % than 8.5.0
    if verLessThan('matlab','8.5.0')
        % Check for the Statistics Toolbox and the Database Toolbox
        if ~any(strcmp('Statistics Toolbox',toolbox)|strcmp('Database Toolbox',toolbox))
            msgbox('You need to have the Statistics Toolbox and Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    
        % Check for the Statistics Toolbox
        if ~any(strcmp('Statistics Toolbox',toolbox))
            msgbox('You need to have the Statistics Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    else
    % Else if using Matlab 2015a or newer version
        % Check for the Statistics and Machine learning Toolbox which is the name for statitics toolbox in Matlab 2015 and the Database Toolbox
        if ~any(strcmp('Statistics and Machine Learning Toolbox',toolbox)|strcmp('Database Toolbox',toolbox))
            msgbox('You need to have the Statistics and Machine Learning Toolbox and Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    
        % Check for the Statistics and Machine Learning Toolbox
        if ~any(strcmp('Statistics and Machine Learning Toolbox',toolbox))
            msgbox('You need to have the Statistics and Machine Learning Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
            return
        end
    end
    
    % Check for the Database Toolbox
    if  ~any(strcmp('Database Toolbox',toolbox))
        msgbox('You need to have the Database Toolbox installed in order for the Capability GUI program to function.', 'Error', 'error')
        return
    end

%% Program Display Name to Database Name Map

% Get the calatolg listing to autopopualte the program list
%P = catalogs(c.conn)
% Clean out the extras ?
%P = P(1:end-4);
% Set the list into the 
%set(handles.lstProgram,'String',P)

% Define program display name for the GUI selection box to database name mapping
progMap = {
% 'Display Name',                              'Database Name'
  'Acadia',                                    'Acadia';
  'Atlantic',                                  'Atlantic';
  'Ayrton',                                    'Ayrton';
  'Blazer',                                    'Blazer';
  'Bronco',                                    'Bronco';
  'Clydesdale',                                'Clydesdale';
  'Dragnet_B  |  Dragon Rear (MR)  |  ISB',    'DragonMR';
  'Dragnet_CC  |  Dragon Front (Chassis Cab)', 'DragonCC';
  'Dragnet_L  |  Yukon  |  ISL',               'Yukon';
  'Dragnet_PU  |  Seahawk (Pick-up Truck)',    'Seahawk';
  'Dragnet_X  |  Pacific  |  ISX',             'HDPacific';
  'Mamba',                                     'Mamba';
  'Nighthawk',                                 'Nighthawk';
  'Pele',                                      'Pele';
  'Shadowfax',                                 'Shadowfax';
  'Sierra',                                    'Sierra';
  'Vanguard',                                  'Vanguard';
  'Ventura',                                   'Ventura';
  };

% Populate the program list into the drop-down menu
set(handles.lstProgram,'String',progMap(:,1));
set(handles.lstProgram,'UserData',progMap(:,2));

% Default program index
defaultIndex = 10;

set(handles.lstProgram,'Value',defaultIndex)
% Set initial database to connect to
initialDB = progMap{defaultIndex,2};

%% Initial Connection to Database

% Display a warning that the GUI is initalizing
h = msgbox('Attempting to connect to the OBD capability database','Please Wait');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)

try
    % Initalized the Capability object to the default program
    handles.c = Capability(initialDB);
catch ex
    % Print the original error report to the workspace
    disp(ex.getReport);
    % Handle various errors appropriatly
    switch ex.identifier
        % User couldn't connect the the database
        case {'database:database:connectionFailure','Capability:UnableToConnect'}
            % If the driver isn't installed / configured correctly
            if strcmp('JDBC Driver Error: com.microsoft.sqlserver.jdbc.SQLServerDriver. Driver Not Found/Loaded.',ex.message)
                % Display a message stating such
                msgbox({'Your installation of Matlab doens''t have the java class com.microsoft.sqlserver.jdbc.SQLServerDriver correctly assosiated so Matlab will not be able to communitcate with the SQL Server.', ...
                        '','Please make sure you ran the InstallSQLDriver.m file first before attampting to launch CapabilityGUI.m'}, ...
                        'Error','error')
            else
                % The user can't connect to the database
                % Display an error message box % 'Cannot open database'
                msgbox({'Failed to connect to the OBD Capability database. Possible reasons include:', ...
                        '1) You are not connected to the Cummins network (need to be on VPN when off-site)', ...
                        '2) The OBD Capability data server is down or offline.'}, 'Error', 'error')
            end
        % User doesn't have permission to connect to the database
        case 'Capability:InvalidProgram'% 'database:database:cursorError'
            msgbox({'You don''t have permission to access the OBD Capability database.', ...
                    'Please send an e-mail to Srivathsan Seshadri (ku906@cummins.com) with your WWID and job responsibility to get access.'}, ...
                    'Error', 'error');
        % License Manager Check-out error
        case 'MATLAB:license:checkouterror'
            % Check if it was because of the Database toolbox
            if any(strfind(ex.message,'Database_Toolbox'))
                % Message box about the error
                msgbox({'There was a failure checking-out a license for the Database toolbox because the maximum number of users was reached. Please try to open the tool again later when a license may become free.'}, 'Error', 'error')
            else
                % Unknown license manager error
                msgbox('There was a failure checking-out a license for an unknown toolbox because the maximum number of users was reached. Please try to open the tool again later when a license may become free. See workspace for the specific failure.', 'Error', 'error')
            end
        % Unknown error
        otherwise
            % Show a message that an unknown error occured.
            msgbox('Unknown failure occured. See workspace for any details.', 'Error', 'error')
    end
    % Delete the initialization message box
    if ishandle(h)
        delete(h);
    end
    % Delete and close the GUI
    delete(hObject)
    % Exit execution of the code
    return
end

% Update handles structure
guidata(hObject, handles);

% Update the GUI with this program's information (system error list + trucks/families)
updateProgramInfo(handles);

% If the code is going to be complied
if isdeployed
    % Disable the button to export data to the Matlab workspace
    set(handles.btnToWorkspace,'Enable','off')
end

% Connection and loading was successful, close the msgbox if the user hasn't selected out of it
if ishandle(h)
    delete(h);
end

% -----------------------------------------------------------------------------

% --- Outputs from this function are returned to the command line.
function varargout = CapabilityGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% If the GUI errored during initialization and was deleted
if isempty(handles)
    % Return an empty array
    varargout{1} = [];
else
    % Return the valid handle to the main window
    varargout{1} = handles.output;
end

% -----------------------------------------------------------------------------

% --- Executes when user attempts to close mainWindow.
function mainWindow_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function mainWindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstSEPlots.
function lstSEPlots_Callback(hObject, eventdata, handles)
% hObject    handle to lstSEPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstSEPlots contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstSEPlots

% New system error plot was selected, update the labels in the window
updateDisplayInfo(handles)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstSEPlots_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstSEPlots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes during object deletion, before destroying properties.
function mainWindow_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to mainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Call this code to clean everything up when the window is closed
%disp('figure1_DeleteFcn called')

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtSEPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSEPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtSEID_Callback(hObject, eventdata, handles)
% hObject    handle to txtSEID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtSEID as text
%        str2double(get(hObject,'String')) returns contents of txtSEID as a double

% -----------------------------------------------------------------------------

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

% -----------------------------------------------------------------------------

function txtExtID_Callback(hObject, eventdata, handles)
% hObject    handle to txtExtID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtExtID as text
%        str2double(get(hObject,'String')) returns contents of txtExtID as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtExtID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtExtID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtParameter_Callback(hObject, eventdata, handles)
% hObject    handle to txtParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtParameter as text
%        str2double(get(hObject,'String')) returns contents of txtParameter as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtParameter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtLSL_Callback(hObject, eventdata, handles)
% hObject    handle to txtLSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtLSL as text
%        str2double(get(hObject,'String')) returns contents of txtLSL as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtLSL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtLSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtUSL_Callback(hObject, eventdata, handles)
% hObject    handle to txtUSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtUSL as text
%        str2double(get(hObject,'String')) returns contents of txtUSL as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtUSL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtUSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtLSLValue_Callback(hObject, eventdata, handles)
% hObject    handle to txtLSLValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtLSLValue as text
%        str2double(get(hObject,'String')) returns contents of txtLSLValue as a double

% Check that the input could be a valid number
if isnan(str2double(get(hObject,'String')))
    % Set the value to the default value in the cal
    set(hObject, 'String', '')
end
% Set the lock button to selected as the user has over-ridden the default cal value
set(handles.btnLockLSL, 'Value', 1)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtLSLValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtLSLValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtUSLValue_Callback(hObject, eventdata, handles)
% hObject    handle to txtUSLValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtUSLValue as text
%        str2double(get(hObject,'String')) returns contents of txtUSLValue as a double

% Check that the input could be a valid number
if isnan(str2double(get(hObject,'String')))
    % Set the value to the default value in the cal
    set(hObject, 'String', '')
end
% Set the lock button to selected as the user has over-ridden the default cal value
set(handles.btnLockUSL, 'Value', 1)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtUSLValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtUSLValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtFromSW_Callback(hObject, eventdata, handles)
% hObject    handle to txtFromSW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtFromSW as text
%        str2double(get(hObject,'String')) returns contents of txtFromSW as a double

% Check the input, if it isn't in dot notation, fix it
if sum(get(hObject, 'String')=='.') == 0
    try
        % Set the value to the dot notation calibration
        set(hObject, 'String', handles.c.num2dot(get(hObject, 'String')))
    catch ex
        % There was an error, blank out the string
        set(hObject, 'String', '')
    end
% Elseif there are the required three dots present
elseif sum(get(hObject, 'String')=='.') == 3
    try
        % Get the cal number from the dot string to a double to make sure it works
        cal = handles.c.dot2num(get(hObject, 'String'));
        % Convert the cal number back to a string and set in the field
        set(hObject, 'String', handles.c.num2dot(cal))
    catch ex
        % There was an error, blank out the string
        set(hObject, 'String', '')
    end
else
    % Set the value back to an empty string as there was an invalid input
    set(hObject, 'String', '')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtFromSW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFromSW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtToSW_Callback(hObject, eventdata, handles)
% hObject    handle to txtToSW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtToSW as text
%        str2double(get(hObject,'String')) returns contents of txtToSW as a double

% Check the input, if it isn't in dot notation, fix it
if sum(get(hObject, 'String')=='.') == 0
    try
        % Set the value to the dot notation calibration
        set(hObject, 'String', handles.c.num2dot(get(hObject, 'String')))
    catch ex
        % There was an error, blank out the string
        set(hObject, 'String', '')
    end
% Elseif there are the required three dots present
elseif sum(get(hObject, 'String')=='.') == 3
    try
        % Get the cal number from the dot string to a double to make sure it works
        cal = handles.c.dot2num(get(hObject, 'String'));
        % Convert the cal number back to a string and set in the field
        set(hObject, 'String', handles.c.num2dot(cal))
    catch ex
        % There was an error, blank out the string
        set(hObject, 'String', '')
    end
else
    % Set the value back to an empty string as there was an invalid input
    set(hObject, 'String', '')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtToSW_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtToSW (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtFromDate_Callback(hObject, eventdata, handles)
% hObject    handle to txtFromDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtFromDate as text
%        str2double(get(hObject,'String')) returns contents of txtFromDate as a double

% Update the string date field and the from date filtering criteria
input = get(hObject, 'String');
% If the input was an empty string
[~, datestring] = handles.c.getDateInfo(input);
% Set the datestring to the proper box
set(handles.txtFromDateString, 'String', datestring)
% If the date string was empty because of an error
if isempty(datestring)
    % Clear out the value placed into the box
    set(hObject,'String','')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtFromDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFromDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtToDate_Callback(hObject, eventdata, handles)
% hObject    handle to txtToDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtToDate as text
%        str2double(get(hObject,'String')) returns contents of txtToDate as a double

% Update the string date field and the from date filtering criteria
input = get(hObject, 'String');
% If the input was an empty string
[~, datestring] = handles.c.getDateInfo(input);
% Set the datestring to the proper box
set(handles.txtToDateString, 'String', datestring)
% If the date string was empty because of an error
if isempty(datestring)
    % Clear out the value placed into the box
    set(hObject,'String','')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtToDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtToDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtFromDateString_Callback(hObject, eventdata, handles)
% hObject    handle to txtFromDateString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtFromDateString as text
%        str2double(get(hObject,'String')) returns contents of txtFromDateString as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtFromDateString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFromDateString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtToDateString_Callback(hObject, eventdata, handles)
% hObject    handle to txtToDateString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtToDateString as text
%        str2double(get(hObject,'String')) returns contents of txtToDateString as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtToDateString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtToDateString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on button press in btnBoxPlot.
function btnBoxPlot_Callback(hObject, eventdata, handles)
% hObject    handle to btnBoxPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Time how long it takes to make a plot
tic

% Update the filtering values with the current settings
updateFilterValues(handles)

% Set the BoxPlot object properties
handles.c.fillBoxInfo

% Get the spec limit values based on the user input
LSLuser = str2double(get(handles.txtLSLValue, 'String'));
USLuser = str2double(get(handles.txtUSLValue, 'String'));
% Get the mainline cal spec limit
LSLcal = handles.c.filt.LSL;
USLcal = handles.c.filt.USL;
% If the LSL limit was changed from the value in the cal
if (abs(LSLcal - LSLuser) >= 0.01 || isnan(LSLcal)&&~isnan(LSLuser)) && ~(isnan(LSLcal) && isnan(LSLuser))
    % Make the parameter name this value instead
    handles.c.box.LSLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the box plot object
    handles.c.box.LSL = LSLuser;
elseif isnan(LSLuser) && ~isnan(LSLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.box.LSLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.box.LSL = NaN;
end
% If the USL limit was changed from the value in the cal
if (abs(USLcal - USLuser) >= 0.01 || isnan(USLcal)&&~isnan(USLuser)) && ~(isnan(handles.c.filt.USL) && isnan(USLuser))
    % Make the parameter name this value instead
    handles.c.box.USLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the box plot object
    handles.c.box.USL = USLuser;
elseif isnan(USLuser) && ~isnan(USLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.box.USLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.box.USL = NaN;
end

% Get the filtering setting
if get(handles.rdoByTruck, 'Value')
    group = 1;
elseif get(handles.rdoByFamily, 'Value')
    group = 2;
elseif get(handles.rdoByMonth, 'Value')
    group = 3;
else % get(handles.rdoBySoftware, 'Value')
    group = 0;
end

% Get the second grouping setting
if get(handles.rdoByTruck2, 'Value')
    group2 = 1;
elseif get(handles.rdoByFamily2, 'Value')
    group2 = 2;
elseif get(handles.rdoByMonth2, 'Value')
    group2 = 3;
elseif get(handles.rdoBySoftware2, 'Value')
    group2 = 0;
else % get(handles.rdoByNone2, 'Value')
    group2 = -1;
end

% Display a warning that data is being fetched
h = msgbox('Fetching data from database. Please Wait.','Working...');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Try to fetch and fill data into the box object
try
    % Fill the data into the box object
    handles.c.fillBoxData(group,group2)
catch ex
    % Handle the case of when there is no data found
    switch ex.identifier
        case 'Capability:fillBoxData:NoDataFound'
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!',...
                   'Error', 'warn', 'modal')
            % Reset the box object to clear the system error information
            handles.c.box.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'database:database:connectionFailure'
            % Display a warning messge to the user
            msgbox({'Could not establish a connection to the database.', ...
                    'Please make sure you are connected to the Cummins Inc. network.'}, ...
                    'Error', 'warn', 'modal')
            % Reset the box object to clear the system error information
            handles.c.box.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        otherwise
            % Rethrow the original exception
            rethrow(ex)
    end
end
% Change the message to a warning that the plot is being generated
h = msgbox('Generating requested plot. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Generate the plot, set it to display when made
handles.c.box.makePlot(1)
% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Reset the box object as the plot has already been made
handles.c.box.reset

% Plot completed, print time to the workspace
toc

% -----------------------------------------------------------------------------

% --- Executes on button press in btnHistogram.
function btnHistogram_Callback(hObject, eventdata, handles)
% hObject    handle to btnHistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Time how long it takes to make a plot
tic

% Update the filtering values with the current settings
updateFilterValues(handles)

% Set the Histogram object properties
handles.c.fillHistInfo

% Get the spec limit values based on the user input
LSLuser = str2double(get(handles.txtLSLValue, 'String'));
USLuser = str2double(get(handles.txtUSLValue, 'String'));
% Get the mainline cal spec limit
LSLcal = handles.c.filt.LSL;
USLcal = handles.c.filt.USL;
% If the LSL limit was changed from the value in the cal
if (abs(LSLcal - LSLuser) >= 0.01 || isnan(LSLcal)&&~isnan(LSLuser)) && ~(isnan(LSLcal) && isnan(LSLuser))
    % Make the parameter name this value instead
    handles.c.hist.LSLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the box plot object
    handles.c.hist.LSL = LSLuser;
elseif isnan(LSLuser) && ~isnan(LSLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.hist.LSLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.hist.LSL = NaN;
end
% If the USL limit was changed from the value in the cal
if (abs(USLcal - USLuser) >= 0.01 || isnan(USLcal)&&~isnan(USLuser)) && ~(isnan(handles.c.filt.USL) && isnan(USLuser))
    % Make the parameter name this value instead
    handles.c.hist.USLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the box plot object
    handles.c.hist.USL = USLuser;
elseif isnan(USLuser) && ~isnan(USLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.hist.USLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.hist.USL = NaN;
end

% Always return the standard Ppk calculatioin
handles.c.hist.Dist = 'norm';

% Display a warning that data is being fetched
h = msgbox('Fetching data from database. Please Wait.','Working...');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Try to fetch and fill data into the box object
try
    % Fill the data into the box object
    handles.c.fillHistData
catch ex
    % Handle the case of when there is no data found
    switch ex.identifier
        case 'Capability:fillHistData:NoDataFound'
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!', 'Error', 'warn', 'modal')
            % Reset the box object to clear the system error information
            handles.c.hist.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'database:database:connectionFailure'
            % Display a warning messge to the user
            msgbox({'Could not establish a connection to the database.', ...
                    'Please make sure you are connected to the Cummins Inc. network.'}, ...
                    'Error', 'warn', 'modal')
            % Reset the box object to clear the system error information
            handles.c.hist.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        otherwise
            % Rethrow the original exception
            rethrow(ex)
    end
end
% Change the message to a warning that the plot is being generated
h = msgbox('Generating requested plot. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)

try
    % Generate the plot, set it to display when made
    handles.c.hist.makePlot(1)
catch ex
    % Reset the properties of the histogram object
    handles.c.hist.reset;
    % Handle known errors
    switch ex.identifier
        case 'StatCalculator:calcCapability:LSLwithExp'
            % This happens when an exponential distribution is selected with a LSL
            % diagnostic, which shouldn't be done
            msgbox('You cannot select an exponential distribution type for diagnostics that have a LSL.','Error','warn','modal');
            % Delete the original status box
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'StatCalculator:fitDist:AllZero'
            % This happens when the data is all zero
            msgbox('Data returned was all zero. No distribution could be fit to the data.','Error','warn','modal');
            % Delete the status box
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'StatCalculator:fitDist:NegativeData'
            % This happens when there is negative data present for a non-normal distribution
            msgbox('The select distribution is not compatible with negative data values.','Error','warn','modal');
            % Delete the status box
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        otherwise
            % Unknown exception, throw the original error
            rethrow(ex)
    end
end

% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Reset the box object as the plot has already been made
handles.c.hist.reset

% Plot completed, print time to the workspace
toc

% -----------------------------------------------------------------------------

% --- Executes on selection change in lst3StepOwner.
function lst3StepOwner_Callback(hObject, eventdata, handles)
% hObject    handle to lst3StepOwner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lst3StepOwner contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lst3StepOwner

% Change the list of system errors displayed in lstSEPlots
set(handles.lstSEPlots, 'String', handles.c.plotOwners.plots{get(hObject, 'Value')})
% Set the first one as the selected one
set(handles.lstSEPlots, 'Value', 1)
% Update the display info to show the first system error by default
updateDisplayInfo(handles)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lst3StepOwner_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lst3StepOwner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on button press in btnLockLSL.
function btnLockLSL_Callback(hObject, eventdata, handles)
% hObject    handle to btnLockLSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hint: get(hObject,'Value') returns toggle state of btnLockLSL

% -----------------------------------------------------------------------------

% --- Executes on button press in btnLockUSL.
function btnLockUSL_Callback(hObject, eventdata, handles)
% hObject    handle to btnLockUSL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hint: get(hObject,'Value') returns toggle state of btnLockUSL

% -----------------------------------------------------------------------------

% --- Executes on button press in btnRawData.
function btnRawData_Callback(hObject, eventdata, handles)
% hObject    handle to btnRawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Time how long it takes to make the raw data window
tic

% Update the filtering values with the current settings
updateFilterValues(handles)

% Call the getRawData function to fetch the selected dataset and format it
%openRawData(handles)
[data, header, abs_time] = getRawData(handles);

% Format the ECM_Run_Time as a string so that it displays properly
% For each row of data
for i = 1:size(data,1)
    % Convert ECM Run Time to a string so it displays properly
    data{i,3} = sprintf('%.1f',data{i,3});
end

% If there was data returned
if ~isempty(data)
    % Change the message to a warning that the window is being created
    h = msgbox('Opening raw data window. Please Wait.','Working...','replace');
    % Remove the OK button
    child = get(h,'Children');
    delete(child(end))
    pause(0.02)
    % Try to make the rawData window using the formatted data
    rawData(data, header, handles.c.filt.SEID, handles.c.filt.Name)%, abs_time)
    % Close the msgbox if it still exists
    if ishandle(h)
        delete(h)
    end
end

% Print the time to make the raw data window
toc

% -----------------------------------------------------------------------------

function txtLowerFilt_Callback(hObject, eventdata, handles)
% hObject    handle to txtLowerFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtLowerFilt as text
%        str2double(get(hObject,'String')) returns contents of txtLowerFilt as a double

% Check that the input is a number
if isnan(str2double(get(hObject,'String')))
    % Set the filed back to a blank
    set(hObject, 'String', '')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtLowerFilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtLowerFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

function txtUpperFilt_Callback(hObject, eventdata, handles)
% hObject    handle to txtUpperFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtUpperFilt as text
%        str2double(get(hObject,'String')) returns contents of txtUpperFilt as a double

% Check that the input is a number
if isnan(str2double(get(hObject,'String')))
    % Set the filed back to a blank
    set(hObject, 'String', '')
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtUpperFilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtUpperFilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on button press in rdoAnd.
function rdoAnd_Callback(hObject, eventdata, handles)
% hObject    handle to rdoAnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rdoAnd

% If the And button was set to selected
if get(hObject,'Value')
    % Set the Or button to un-selected
    set(handles.rdoOr, 'Value', 0)
else % The And button was set to unselected
    % Set the Or button to selected
    set(handles.rdoOr, 'Value', 1)
end

% -----------------------------------------------------------------------------

% --- Executes on button press in rdoOr.
function rdoOr_Callback(hObject, eventdata, handles)
% hObject    handle to rdoOr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rdoOr

% If the Or button was set to selected
if get(hObject,'Value')
    % Set the And button to selected
    set(handles.rdoAnd, 'Value', 0)
else % The Or button was was to unselected
    % Set the And button to selected
    set(handles.rdoAnd, 'Value', 1)
end

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstMinMax.
function lstMinMax_Callback(hObject, eventdata, handles)
% hObject    handle to lstMinMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 
% Hints: contents = cellstr(get(hObject,'String')) returns lstMinMax contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstMinMax

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstMinMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstMinMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on button press in btnToWorkspace.
function btnToWorkspace_Callback(hObject, eventdata, handles)
% hObject    handle to btnToWorkspace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Time how long it takes to export the data to the workspace
tic
% Update the filtering values with the current settings
updateFilterValues(handles)
% Call the getRawData function to fetch the selected dataset and format it
[data, header, abs_time] = getRawData(handles);

% If there was no data returned
if isempty(data)
    % Print the time and return out of the function
    toc
    return
end

% Change the message to a warning that the data is being exported to the workspace
h = msgbox('Exporting data to the Matlab workspace. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)

% Take care of the standard metadata values
assignin('base','abs_time',abs_time);                % Matlab serial date number
assignin('base','DateTime',data(:,2));               % Date and Time string
assignin('base','ECM_Run_Time',cell2mat(data(:,3))); % ECM_Run_Time
assignin('base','TruckName',data(:,4));              % Truck Name
assignin('base','Family',data(:,5));                 % Engine Family
assignin('base','Software',cell2mat(data(:,6)));     % Software Version

% If the seventh column is the MinMaxSetID
if strcmp(header{7},'Min/Max Set ID')
    % Make sure this name is used for the variable
    assignin('base','MinMaxSetID',cell2mat(data(:,7)));
    % Start the data export from the 8th column (as the 7th column as already exported)
    startCol = 8;
else
    % Start the data export from the 7th column
    startCol = 7;
end
% Export variables to the workspace (column startCol to the last column)
for i = startCol:size(data,2)
    % Get a Matlab friendly name
    name = generateMatVarName(header{i});
    % Push the data to the workspace
    assignin('base',name,cell2mat(data(:,i)));
end

% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Print the time to export the raw data
toc

% -----------------------------------------------------------------------------

% --- Executes on button press in btnToExcel.
function btnToExcel_Callback(hObject, eventdata, handles)
% hObject    handle to btnToExcel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Decide what the default file name and tab name in the output should be named 
% depending on whether it's Min/Max or Event Drievn
if isnan(handles.c.filt.ExtID)
    % If we're Min/Max, use the parameter name
    defaultFile = fullfile('D:\',[handles.c.filt.CriticalParam '.xlsb']);
    tabName = handles.c.filt.CriticalParam;
else % Event Driven, use SEID
    SEID = handles.c.filt.SEID;
    %SEName = handles.c.getSEName(handles.c.filt.SEID);
    % Use the plot name instead which is mostly the system error because it doesn't rely
    % on the function getSEName to work correctly
    SEName = handles.c.filt.Name;
    defaultFile = fullfile('D:\',sprintf('%s - SE%.0f.xlsb',SEName,SEID));
    tabName = SEName;
end
% If the tabName is longer than 31 characters
if length(tabName) > 31
    % Trim it to 31 characters
    tabName = tabName(1:31);
end
% Create the file specifications to prompt the user with
fileSpec = {'D:\*.xlsb','Excel Binary Workbook (*.xlsb)'; ...
            'D:\*.xlsx','Excel Workbook (*.xlsx)'; ...
            'D:\*.xlsm','Excel Macro-Enabled Workbook (*.xlsm)'; ...
            'D:\*.xls','Excel 97-2003 Workboox (*.xls)'; ...
            'D:\*.*','All Files (*.*)'};
% Prompt the user to specify a file name and location
[fname, path] = uiputfile(fileSpec,'Export Data to Excel File...',defaultFile);
% If the user clicked cancel
if isnumeric(fname)
    % Return and do nothing
    return
end

% Time how long it takes to export the data to the workspace
tic
% Update the filtering values with the current settings
updateFilterValues(handles)
% Call the getRawData function to fetch the selected dataset and format it
[data, header, ~] = getRawData(handles);
% If there was no data returned
if isempty(data)
    % Print the time and return out of the function
    toc
    return
end

% Change the message to a warning that the data is being exported to the workspace
h = msgbox('Exporting data to Excel file. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Add the header to the top of data
data = [header;data];
try
    % Turn the xlswrite AddSheet warnings off
    warning('off', 'MATLAB:xlswrite:AddSheet')
    % Write it to the specified spreadsheet
    xlswrite2(fullfile(path,fname),data,tabName)
    % Turn the xlswrite AddSheet warnings back on
    warning('on', 'MATLAB:xlswrite:AddSheet')
catch ex
    % Display the error on the workspace to keep the information
    disp(ex.getReport)
    % Display an error dialog warning the user that file export failed
    msgbox('There was an error writing the data to the specified file. See the workspace for details.','Data Export Error','error','modal')
end

% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Print the time to export the raw data
toc

% -----------------------------------------------------------------------------

% --- Executes on button press in btnToMat.
function btnToMat_Callback(hObject, eventdata, handles)
% hObject    handle to btnToMat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If there is no system error selected (as the plot name is empty)
if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.','Error','error')
    % Exit the function
    return
end

% Decide what the default file name and tab name in the output should be named 
% depending on whether it's Min/Max or Event Drievn
if isnan(handles.c.filt.ExtID)
    % If we're Min/Max, use the parameter name
    defaultFile = fullfile('D:\',[handles.c.filt.CriticalParam '.mat']);
else % Event Driven, use SEID
    SEID = handles.c.filt.SEID;
    %SEName = handles.c.getSEName(handles.c.filt.SEID);
    % Use the plot name instead which is mostly the system error because it doesn't rely
    % on the function getSEName to work correctly
    SEName = handles.c.filt.Name;
    defaultFile = fullfile('D:\',sprintf('%s - SE%.0f.mat',SEName,SEID));
end
% Prompt the user to specify a file name and location
[fname, path] = uiputfile({'.mat'},'Export Data to Matlab .mat File...',defaultFile);
% If the user clicked cancel
if isnumeric(fname)
    % Return and do nothing
    return
end

% Time how long it takes to export the data to the workspace
tic
% Update the filtering values with the current settings
updateFilterValues(handles)
% Call the getRawData function to fetch the selected dataset and format it
[data, header, abs_time] = getRawData(handles);
% If there was no data returned
if isempty(data)
    % Print the time and return out of the function
    toc
    return
end

% Change the message to a warning that the data is being exported to the workspace
h = msgbox('Exporting data to .mat File. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Take care of the standard metadata values
% abs_time already exists           % Matlab serial date number
DateTime = data(:,2);               % Date and Time string
ECM_Run_Time = cell2mat(data(:,3)); % ECM_Run_Time
TruckName = data(:,4);              % Truck Name
Family = data(:,5);                 % Engine Family
Software = cell2mat(data(:,6));     % Software Version

% If the seventh column is the MinMaxSetID
if strcmp(header{7},'Min/Max Set ID')
    % Make sure this name is used for the variable
    MinMaxSetID = cell2mat(data(:,7));
    % Save the first 7 variables to the .mat file first
    save(fullfile(path,fname),'abs_time','DateTime','ECM_Run_Time','TruckName', ...
                              'Family','Software','MinMaxSetID');
    % Start the data export from the 8th column (as the 7th column as already exported)
    startCol = 8;
else
    % Save the first 6 variables to the .mat file first
    save(fullfile(path,fname),'abs_time','DateTime','ECM_Run_Time','TruckName', ...
                              'Family','Software');
    % Start the data export from the 7th column
    startCol = 7;
end

% Append the additional data variables to the .mat file (column startCol to the last column)
for i = startCol:size(data,2)
    % Get a Matlab friendly name
    name = generateMatVarName(header{i});
    % Create the variable in this workspace
    eval([name ' = cell2mat(data(:,i));']);
    % Append it onto the desired .mat file
    save(fullfile(path,fname),name,'-append');
end

% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Print the time to export the raw data
toc

% -----------------------------------------------------------------------------

function txtFC_Callback(hObject, eventdata, handles)
% hObject    handle to txtFC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents of txtFC as text
%        str2double(get(hObject,'String')) returns contents of txtFC as a double

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function txtFC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Updates the display of the system error info when a new plot definition is selected
function updateDisplayInfo(handles)
% handles   handles for all the objects

% Update the display with the newest information and additionally fill the values into the
% capability.filt structure

% Get the index of the item selected
selectedIdx = get(handles.lstSEPlots, 'Value');
% If there are no diagnostics present
if isempty(selectedIdx) || isempty(get(handles.lstSEPlots, 'String'))
    % Set everything to a blank
    % Plot Name
    set(handles.txtSEPlot, 'String', '');
    % System Error ID
    set(handles.txtSEID, 'String', '');
    % Extension ID
    set(handles.txtExtID, 'String', '');
    % Fault Code
    set(handles.txtFC, 'String', '');
    % Parameter plotted / (Critical/Decision Parameter)
    set(handles.txtParameter, 'String', '');
    % Lower Spec Limit name
    set(handles.txtLSL, 'String', '');
    % Upper Spec Limit name
    set(handles.txtUSL, 'String', '');
    % From Software filter
    set(handles.txtFromSW, 'String', '');
    % To Software filtering
    set(handles.txtToSW, 'String', '');
    % Tell the capability object to refresh it's filt structure internally
    handles.c.fillFiltPlotInfo(NaN);
else
    % Get the list of current diagnostics
    diagList = cellstr(get(handles.lstSEPlots, 'String'));
    % Pull out the value of the selected system error plot
    diagSelected = diagList{selectedIdx};
    % Find this index in the master selection list
    idx = find(strcmp(diagSelected, handles.c.ppi.Name));
    
    % Set the name of the system error plots
    set(handles.txtSEPlot, 'String', handles.c.ppi.Name{idx});
    % Set the system error id
    set(handles.txtSEID, 'String', handles.c.ppi.SEID(idx));
    % Set the fault code, leave it blank if it isn't found in the error_table or is a NaN
    try
        % Get fault code and convert it to a string
        fcval = sprintf('%.0f',handles.c.getFC(handles.c.ppi.SEID(idx)));
        % Based on the OBD type
        switch handles.c.obd
            % If it's a J1979 program
            case {'obdii','euro5','euro6'}
                % Get the J2010 P-code
                pcode = handles.c.getPcode(handles.c.ppi.SEID(idx));
                % Calculate the string to set into the window
                setString = [fcval ' | ' pcode];
            %If it's a J1939 program
            case {'hdobd','eurovi'}
                % Get J1939 SPN and FMI
                spn = handles.c.getSPN(handles.c.ppi.SEID(idx));
                fmi = handles.c.getFMI(handles.c.ppi.SEID(idx));
                % Calculate the string to set into the window
                setString = [fcval ' | ' sprintf('%.0f.%.0f',spn,fmi)];
            % Unknow obd type (how do you get here?)
            otherwise
                % Just do the cumming 4 digit fault code
                setString = fcval;
        end
        % Set the value into the GUI
        set(handles.txtFC, 'String', setString);
    catch ex
        % On any error, leave the window blank
        set(handles.txtFC, 'String', ' | ');
    end
    % Set the ExtID based on whether or not this is a Min/Max or Event Driven system error
    if isnan(handles.c.ppi.ExtID(idx))
        set(handles.txtExtID, 'String', '');
    else
        set(handles.txtExtID, 'String', handles.c.ppi.ExtID(idx));
    end
    % Critical Parameter Name
    set(handles.txtParameter, 'String', handles.c.ppi.CriticalParam{idx});
    % Set the name of the LSL if they exist
    if strcmp('null', handles.c.ppi.LSL{idx}) || any(isnan(handles.c.ppi.LSL{idx}))
        set(handles.txtLSL, 'String', '');
    else
        set(handles.txtLSL, 'String', handles.c.ppi.LSL{idx});
    end
    % Set the name of the USL if they exist
    if strcmp('null', handles.c.ppi.USL{idx}) || any(isnan(handles.c.ppi.USL{idx}))
        set(handles.txtUSL, 'String', '');
    else
        set(handles.txtUSL, 'String', handles.c.ppi.USL{idx});
    end
    % Set the default software filtering value
    %set(handles.txtFromSW, 'String', handles.c.ppi.fromSW(idx));
    %set(handles.txtToSW, 'String', handles.c.ppi.toSW(idx));
    % Execute the callbacks for each to set the value to the correct values
    %txtFromSW_Callback(handles.txtFromSW, [], handles)
    %txtToSW_Callback(handles.txtToSW, [], handles)
    % Tell the capability object to refresh it's filt structure internally
    handles.c.fillFiltPlotInfo(idx);
end

% Set both of the spec value buttons to unlocked as the system error has changed
set(handles.btnLockLSL, 'Value', 0);
set(handles.btnLockUSL, 'Value', 0);
% Update the LSL and USL value fields
updateSpecValues(handles)

% Enable or disable the Min or Max data filtering selection depending 
% on if it's min/max or not If this is a Min/Max system error
if isnan(handles.c.filt.ExtID)
    % Enable the Min/Max selection
    set(handles.lstMinMax, 'Enable', 'on')
    % If there is a LSL
    if ~isempty(get(handles.txtLSL, 'String'))
        % Set the filtering on raw data filtering the "Min Data" option
        set(handles.lstMinMax, 'Value', 1)
    end
    % If there is a USL (this over-rides the LSL when both are present)
    if ~isempty(get(handles.txtUSL, 'String'))
        % Set the filtering on raw data filtering the "Max Data" option
        set(handles.lstMinMax, 'Value', 2)
    end
else % this is an Event Driven system error
    % Disable the Min/Max selection
    set(handles.lstMinMax, 'Enable', 'off')
end

% -----------------------------------------------------------------------------

% --- Updates the values of the LSL and USL 
function updateSpecValues(handles)
% Update the LSL and USL values for the current family and system error
% Should be called when either the plot or engine family is changed in the GUI

% Get the currently selected engine family(s)
family = handles.c.filtDisp.engfams(get(handles.lstFamily,'Value'));
% If any were 'All'
if any(strcmp('All',family))
    % Use the 'Default' family that each program should have uploaded
    family = 'Default';
else
    % Use the first family name present, even if there are more than one selected
    family = family{1};
end

% If the lock button itn't selected
if ~get(handles.btnLockLSL, 'Value')
    % If there is no LSL
    if isempty(get(handles.txtLSL, 'String'))
        % Set the value to a blank
        set(handles.txtLSLValue, 'String', '')
        % Make it a NaN in the filt structure
        handles.c.filt.LSL = NaN;
        % Automatically set the lower raw data filtering to empty
        set(handles.txtLowerFilt, 'String', '')
    else
        try
            % Get the value of the LSL from the cal for the selected engine family
            LSL = handles.c.getSpecValue(get(handles.txtLSL, 'String'),family);
            % Set it in the correct box
            set(handles.txtLSLValue, 'String', LSL)
            % Update the value in the filt structure
            handles.c.filt.LSL = LSL;
            % Automatically set the lower raw data filtering to the LSL value
            set(handles.txtLowerFilt, 'String', LSL)
        catch ex
            % If the error was that the threshold value couldn't be found
            if strcmp(ex.identifier,'Capability:getSpecValue:UndefinedThreshold')
                % Set the box to be empty
                set(handles.txtLSLValue, 'String', '')
                % Update the value in the filt structure
                handles.c.filt.LSL = NaN;
                % Set the lower raw data filtering to be nothing
                set(handles.txtLowerFilt, 'String', '')
                % Display a message that the calibratable couldn't be found
                fprintf('Failed to find the value for %s in the database.\r',get(handles.txtLSL, 'String'));
            else % Rethrow the original, unknown exception
                rethrow(ex)
            end
        end
    end
end

% If the lock button isn't selected
if ~get(handles.btnLockUSL, 'Value')
    % If there is no USL
    if isempty(get(handles.txtUSL, 'String'))
        % Set the value to a blank
        set(handles.txtUSLValue, 'String', '')
        % Make it a NaN in the filt structure
        handles.c.filt.USL = NaN;
        % Automatically set the upper raw data filtering to empty
        set(handles.txtUpperFilt, 'String', '')
    else
        try
            % Get the value of the USL from the cal for the selected engine family
            USL = handles.c.getSpecValue(get(handles.txtUSL, 'String'),family);
            % Get the correct value from the cal for the selected engine family
            set(handles.txtUSLValue, 'String', USL)
            % Update the value in the filt structure
            handles.c.filt.USL = USL;
            % Automatically set the upper raw data filtering to the USL value
            set(handles.txtUpperFilt, 'String', USL)
        catch ex
            % If the error was that the threshold value couldn't be found
            if strcmp(ex.identifier,'Capability:getSpecValue:UndefinedThreshold')
                % Set the value to a blank
                set(handles.txtUSLValue, 'String', '')
                % Make it a NaN in the filt structure
                handles.c.filt.USL = NaN;
                % Automatically set the upper raw data filtering to empty
                set(handles.txtUpperFilt, 'String', '')
                % Display a message that the calibratable couldn't be found
                fprintf('Failed to find the value for %s in the database.\r',get(handles.txtUSL, 'String'));
            else % Rethrow the original exception
                rethrow(ex)
            end
        end
    end
end

% -----------------------------------------------------------------------------

% --- Updates the filter values of all things in the filter structure
function updateFilterValues(handles)
% Update the user specified filtering criteria and put it into the Capability object

% Get the selected vehicle filtering
vehicle = get(handles.lstTrucks,'String');
vehicle = vehicle(get(handles.lstTrucks,'Value'));
% Get the selected truck type filtering
vehtype = handles.c.filtDisp.vehtypes(get(handles.lstVehType,'Value'));
% Get the selected family filtering
engfam = handles.c.filtDisp.engfams(get(handles.lstFamily,'Value'));

% If the user chose individual vehicles
if handles.c.filt.byVehicle
    % New specific vehicle filtering method
    handles.c.filt.vehicle = vehicle;
    % Set the family and truck type to deafult so they don't do anything
    %handles.c.filt.vehtype = {''};
    %handles.c.filt.engfam = {''};
else
    % Set to the vehicle filtering to the default value so that will do nothing
    handles.c.filt.vehicle = {''};
    % Update new truck type filtering method
    handles.c.filt.vehtype = vehtype;
    % Update new engine family filtering method
    handles.c.filt.engfam = engfam;
end

% Software filtering
% Get the string values of the to and from software filtering
fromSW = get(handles.txtFromSW, 'String');
toSW = get(handles.txtToSW, 'String');
% Get the software version numbers or set to NaN for a blank
if isempty(fromSW)
    fromSWnum = NaN;
else
    fromSWnum = handles.c.dot2num(fromSW);
end
if isempty(toSW)
    toSWnum = NaN;
else
    toSWnum = handles.c.dot2num(toSW);
end
% Set the values to the filtering structure
handles.c.filt.software = [fromSWnum toSWnum];

% Date filtering
% Get the datenumber conversion from the txtFromDate field
[fromDate, ~] = handles.c.getDateInfo(get(handles.txtFromDate, 'String'));
% Get the datenumber conversion from the txtToDate field
[toDate, ~] = handles.c.getDateInfo(get(handles.txtToDate, 'String'));

% Set the datenumber of toDate to the max date the data has if it's not specified
if isnan(toDate)
    if isnan(handles.c.filt.ExtID) % for MinMax parameters
        if ~isnan(handles.c.filt.CriticalParam)
            % Get the public data id
            pdid = handles.c.getPublicDataID(handles.c.filt.CriticalParam);
            if pdid==89752 %Set publicDataID to the new one for LPC_ct_DiscreteHighSet & LPC_ct_DiscreteLowSet
                pdid = 197902;
            elseif pdid==89754
                pdid = 197903;
            else
            end
            
            if isnan(fromSWnum)
                if isnan(toSWnum)
                    sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblMinMaxData WHERE PublicDataID = %d',handles.c.program, pdid);
                else
                    sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblMinMaxData WHERE PublicDataID = %d And CalibrationVersion <= %d',handles.c.program, pdid, toSWnum);
                end
            else
                if isnan(toSWnum)
                    sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblMinMaxData WHERE PublicDataID = %d And CalibrationVersion >= %d',handles.c.program, pdid, fromSWnum);
                else
                    sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblMinMaxData WHERE PublicDataID = %d And CalibrationVersion Between %d And %d',handles.c.program, pdid, fromSWnum, toSWnum);
                end
            end
            toDate = cell2mat(struct2cell(fetch(handles.c.conn, sql)));
        else
            % Do nothing to toDate if the parameter does not exist yet since it's just a switch to a new platform
        end
    else % for EventDriven parameters
        if isnan(fromSWnum)
            if isnan(toSWnum)
                sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblEventDrivenData WHERE SEID = %d AND ExtID = %d',handles.c.program, handles.c.filt.SEID, handles.c.filt.ExtID);
            else
                sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblEventDrivenData WHERE SEID = %d AND ExtID = %d And CalibrationVersion <= %d',handles.c.program, handles.c.filt.SEID, handles.c.filt.ExtID, toSWnum);
            end
        else
            if isnan(toSWnum)
                sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblEventDrivenData WHERE SEID = %d AND ExtID = %d And CalibrationVersion >= %d',handles.c.program, handles.c.filt.SEID, handles.c.filt.ExtID, fromSWnum);
            else
                sql = sprintf('SELECT max(datenum) FROM %s.dbo.tblEventDrivenData WHERE SEID = %d AND ExtID = %d And CalibrationVersion Between %d And %d',handles.c.program, handles.c.filt.SEID, handles.c.filt.ExtID, fromSWnum, toSWnum);
            end
        end
        toDate = cell2mat(struct2cell(fetch(handles.c.conn, sql)));
    end
else
end

% Set the filtering in the filter structure (add one to the toDate to include data from that entire day up to midnight the next day)
handles.c.filt.date = [fromDate toDate+1];

% Trip filtering
if get(handles.rdoNoTestTrip, 'Value')
    handles.c.filt.trip = 0;
elseif get(handles.rdoTestTrip, 'Value')
    handles.c.filt.trip = NaN;
else % has to be rdoTestTripOnly
    handles.c.filt.trip = 1;
end

% EMB filtering
if get(handles.rdoNoEMB, 'Value')
    handles.c.filt.emb = 0;
elseif get(handles.rdoEMB, 'Value')
    handles.c.filt.emb = NaN;
else % has to be rdoEMBOnly
    handles.c.filt.emb = 1;
end

% Raw Data filter criteria
% Set raw data upper limit
handles.c.filt.RawLowerVal = str2double(get(handles.txtLowerFilt, 'String'));
% Set raw data lower limit
handles.c.filt.RawUpperVal = str2double(get(handles.txtUpperFilt, 'String'));
% If 'and' is selected
if get(handles.rdoAnd, 'Value')
    handles.c.filt.RawCondition = 'and';
else % has to be 'or'
    handles.c.filt.RawCondition = 'or';
end
% If 'Min Data' is selected
if get(handles.lstMinMax, 'Value') == 1
    handles.c.filt.MinOrMax = 'valuemin';
else % 'MaxData' is selected % == 2
    handles.c.filt.MinOrMax = 'valuemax';
end

% -----------------------------------------------------------------------------

function updatePossibleVehicles(handles)

% Change the list of avaiable truck names beased on the select engine family
% and truck type
familiesSel = handles.c.filtDisp.engfams(get(handles.lstFamily,'Value'));
typesSel =    handles.c.filtDisp.vehtypes(get(handles.lstVehType,'Value'));

% If All was selected
if any(strcmp(familiesSel,'All'))
    % Keep everything
    idx1 = ones(size(handles.c.tblTrucks.TruckName),'uint8');
else
    % Find the vehicles that are any of the selected families
    % Do the first one to initalize idx
    idx1 = strcmp(handles.c.tblTrucks.Family,familiesSel{1});
    % Loop through each to get additional trucks that meet the criteria
    for i = 2:length(familiesSel)
        idx1 = idx1 | strcmp(handles.c.tblTrucks.Family,familiesSel{i});
    end
end

% If All was selected
if any(strcmp(typesSel,'All'))
    % Keep everything
    idx2 = ones(size(handles.c.tblTrucks.TruckName),'uint8');
else
    % Find the vehicles that are any of the selected vehicle types
    % Do the first one to initalize idx
    idx2 = strcmp(handles.c.tblTrucks.TruckType,typesSel{1});
    % Loop through each to get additional trucks that meet the criteria
    for i = 2:length(typesSel)
        idx2 = idx2 | strcmp(handles.c.tblTrucks.TruckType,typesSel{i});
    end
end

% Sort the final list
trucks = sort(handles.c.tblTrucks.TruckName(idx1&idx2));
% Default to selecting the first vehicle to prevent errors
set(handles.lstTrucks, 'Value', 1);
% Assign to the control
set(handles.lstTrucks, 'String', trucks);
% Now select all vehicles by default
set(handles.lstTrucks,'Value',1:length(trucks));

% Set the flag that the user has changed the truck select so filter using that instead
handles.c.filt.byVehicle = 0;

% -----------------------------------------------------------------------------

function updateProgramInfo(handles)
%%% Call this after handles.c had been set to the correct program
% This will load the system error information and families/trucks into the GUI

% Fill the system error plot list
set(handles.lstSEPlots,'Value',1);
set(handles.lstSEPlots,'String',handles.c.ppi.Name);

% Set the all plots option as the default
set(handles.lst3StepOwner,'Value',1);
% Fill in the 3-step owners for the filter drop down box
set(handles.lst3StepOwner,'String',handles.c.plotOwners.name);

% Fill the the engine families and select the first one by default
set(handles.lstFamily,'Value',1);
set(handles.lstFamily,'String',handles.c.filtDisp.engfams);
% Fill in the vehicle types and select the first one by default
set(handles.lstVehType,'Value',1);
set(handles.lstVehType,'String',handles.c.filtDisp.vehtypes);
% Refresh what trucks, truck types, and families are possible / present
updatePossibleVehicles(handles)

% Initalize the filtering values to their default in the capability object
updateFilterValues(handles) % Needs to be done for the below to work correctly
% Fill in the definition for the first system error by default
updateDisplayInfo(handles)

% Update the fault code indicator label
switch handles.c.obd
    case {'obdii','euro5','euro6'}
        % Note that the P-code will be displayed
        set(handles.lblFC,'String','Fault Code | P-Code:');
    case {'hdobd','eurovi'}
        % Note that the SPN.FMI will be displayed
        set(handles.lblFC,'String','Fault Code | SPN.FMI:');
    otherwise
        % Only the fault code will be displayed (how do you get here?)
        set(handles.lblFC,'String','Fault Code:');
end

% -----------------------------------------------------------------------------

% -- Clone of openRawData, attempt to separate out the function responsibilities
function [data, header, abs_time] = getRawData(handles)
% Using the filtering specified in the GUI and will pull capability data from the database
% and format in into a cell array for usage in various different ways

% Display a warning that data is being fetched
h = msgbox('Fetching data from database. Please Wait.','Working...');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)

% Pull out the filtering values from the filt structure
sw = handles.c.filt.software;
date = handles.c.filt.date;
trip = handles.c.filt.trip;
emb = handles.c.filt.emb;
valA = handles.c.filt.RawLowerVal;
valB = handles.c.filt.RawUpperVal;
rawCond = handles.c.filt.RawCondition;
rawMM = handles.c.filt.MinOrMax;
% New filtering methods
engfam = handles.c.filt.engfam;
vehtype = handles.c.filt.vehtype;
vehicle = handles.c.filt.vehicle;

% Two main paths, Event Driven or Min/Max

% If this is a Min/Max system error
if isnan(handles.c.filt.ExtID)
    %% Formulate the 'valuemin'/'valuemax' filter field
    % If there are valid numbers in both fields
    if ~isnan(valA) && ~isnan(valB)
        % Execute based on the condition specified
        switch rawCond
            case 'and' % If it is an 'and' condition
                % Switch the A and B to do a between filter
                valuesFilt = [valB valA];
            case 'or' % If it is an 'or' condition
                % Add a NaN to let the fetch function know to get the tails
                valuesFilt = [valA NaN valB];
        end
    else
        % One is a NaN, set them in this order as the NaN will presist
        valuesFilt = [valB valA];
    end
    
    %% Get Data From Database
    try
        % Find the public data id of the parameter
        pdid = handles.c.getPublicDataID(handles.c.filt.CriticalParam);
        % Fetch the data from the database (filtering on either DataMin or DataMax as selected by the user)
        d = handles.c.getMinMaxData(pdid,'software',sw,'date',date,'trip',trip,'emb',emb,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle,rawMM,valuesFilt);
    catch ex
        % Look for if the connection to the database couldn't be established
        if strcmp('database:database:connectionFailure',ex.identifier)
            % Delete the message that data is being fetched from the database
            if ishandle(h), delete(h), end
            % Display a warning message to the user
            msgbox({'Could not establish a connection to the database.', ...
                    'Please make sure you are connected to the Cummins Inc. network.'}, ...
                    'Error', 'warn', 'modal');
            % Set the return data to empty sets and return from the function
            data = {};header = {};abs_time = [];return
        else
            % Rethrow the original exception
            rethrow(ex)
        end
    end
    % If no data was returned
    if isempty(d)
        % Delete the message that data is being fetched from the database
        if ishandle(h), delete(h), end
        % Display a warning message to the user
        msgbox({'No data found for specified system error and filtering!' ...
                'Make sure you have correctly selected either the ''Min Data'' or', ...
                '''Max Data'' selection to filter the values with.'}, 'Error', 'warn', 'modal')
        % Set the return data to empty sets and return from the function
        data = {};header = {};abs_time = [];return
    end
    
    %% Format The Data
    % Change the message to a warning that the data is being formatted
    h = msgbox('Formatting data from Database (creating date strings). Please Wait.','Working...','replace');
    % Remove the OK button
    child = get(h,'Children');
    delete(child(end))
    pause(0.02)
	
    % Pull out the abs_time values for the function output argument
    abs_time = d.datenum;
    % Convert to a cell array ready for the rawData GUI window
    data = cell(length(d.datenum),9);           % Initalization
    data(:,1) = num2cell(mod(d.datenum,1)*24);  % Value of the tod
    data(:,2) = cellstr(datestr(d.datenum,31)); % Sortable date and time
    data(:,3) = num2cell(d.ECMRunTime);         % Approximate ECM_Run_Time value
    data(:,4) = d.TruckName;                    
    data(:,5) = d.Family;                       
    data(:,6) = num2cell(d.CalibrationVersion); 
    data(:,7) = num2cell(d.ConditionID);        % Min/Max Set ID
    data(:,8) = num2cell(d.DataMin);            
    data(:,9) = num2cell(d.DataMax);            
    % Make the header row to label the data
    header = {'tod', 'Date/Time (UTC)', 'ECM_Run_Time', 'Truck Name', ...
              'Family', 'Software', 'Min/Max Set ID', ...
              [handles.c.filt.CriticalParam ' Min'], [handles.c.filt.CriticalParam ' Max']};
    
else
    %% Event Driven System Error
    % Pull local copies of these
    SEID = handles.c.filt.SEID;
    ExtID = handles.c.filt.ExtID;
    % Check the evdd if there is more than one ExtID for this SEID
    % Get the list of SEIDs & ExtIDs from the xSEID
    SEIDList = handles.c.evdd.xSEID-floor(handles.c.evdd.xSEID/2^16)*2^16;
    SEIDidx = find(SEIDList==SEID);
    ExtIDList = floor(handles.c.evdd.xSEID(SEIDidx)/2^16);
    % If there is more than one ExtID
    if sum(SEIDList==SEID) > 1
        %% Do it the harder way and grid parameters from all ExtIDs together first
        try
            % Match all event driven data for all filtering conditions except the value filters
            [data, header] = handles.c.matchEventData(SEID,'software',sw,'date',date,'trip',trip,'emb',emb,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        catch ex
            % Look for if the connection to the database couldn't be established
            if strcmp('database:database:connectionFailure',ex.identifier)
                % Delete the message that data is being fetched from the database
                if ishandle(h), delete(h), end
                % Display a warning message to the user
                msgbox({'Could not establish a connection to the database.', ...
                        'Please make sure you are connected to the Cummins Inc. network.'}, ...
                        'Error', 'warn', 'modal');
                % Set the return data to empty sets and return from the function
                data = {};header = {};abs_time = [];return
            else
                % Rethrow the original exception
                rethrow(ex)
            end
        end
        % Error handling if no data is returned
        if isempty(data)
            % Delete the message that data is being fetched from the database
            if ishandle(h), delete(h), end
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!','Error','warn','modal')
            % Set the return data to empty sets and return from the function
            data = {};header = {};abs_time = [];return
        end
        
        %%% The reason for using matchEventData and the manual filtering below is that if
        %%% you try to filter on the DataValue using SQL before you match the data, you 
        %%% will eliminate values from other ExtID parameters and then no matches will be found
        % Manualy filter the data using Matlab because you can't do it with matchEventData
        
        %% Pull out the values to do the filtering on
        ExtIDidx = find(ExtIDList==ExtID);
        filtData = cell2mat(data(:,ExtIDidx+5));
        % If a value was entered into both boxes
        if ~isnan(valA) && ~isnan(valB)
            % Execute based on the condition specified
            switch rawCond
                case 'and' % If it is an 'and' condition
                    % Filter for values between lower and upper
                    idx = filtData>=valB & filtData<=valA;
                case 'or' % If it is an 'or' condition
                    % Add a NaN to let the fetch function know to get the tails
                    idx = filtData>=valB | filtData<=valA;
            end
        elseif isnan(valA) && ~isnan(valB)
            % Find the values >= valB specified
            idx = filtData>=valB;
        elseif isnan(valB) && ~isnan(valA)
            % Find the values <= valA specified
            idx = filtData<=valA;
        else % both are NaN and no filtering should be done
            idx = [];
        end
        
        % Stip out only the desired values
        if ~isempty(idx)
            data = data(idx,:);
        end
        
        % If all of the data was manually filtered out
        if isempty(data)
            % Delete the message that data is being fetched from the database
            if ishandle(h), delete(h), end
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!', 'Error', 'warn', 'modal')
            % Set the return data to empty sets
            data = {};header = {};abs_time = [];
            % Return from the function and don't try to open the rawData window
            return
        end
        
        %% Format Data
        % Change the message to a warning that the data is being formatted
        h = msgbox('Formatting data from the database (creating date strings). Please Wait.','Working...','replace');
        % Remove the OK button
        child = get(h,'Children');
        delete(child(end))
        pause(0.02)
        
        % Pull out the abs_time values for the function output argument
        abs_time = cell2mat(data(:,1));
        % Reformat the output of matchEventData to suit the needs of the rawData window by
        % adding 1 column to the begining
        data = [cell(size(data,1),1) data];
        % Fill in the new column at the begining and replace the datenum column
        data(:,1) = num2cell(mod(cell2mat(data(:,2)),1)*24);
        %data(:,2) = cellstr(datestr(cell2mat(data(:,3)),'yymmdd HH:MM:SS'));
        data(:,2) = cellstr(datestr(cell2mat(data(:,2)),31));
        % Make the header row to label the data
        header = [{'tod', 'Date/Time (UTC)', 'ECM_Run_Time', 'Truck Name', ...
                  'Family', 'Software'} header{6:end}];
        
    else
        %% There is only one ExtID, use getEventData for the job
        % Quick consistency check, is the ExtID 0? (it should be, except SEID 7834)
        if ExtID ~= 0 && SEID~=7834, error('Logic Error in Function'), end
        
        % Formulate the 'values' filter field
        % If there are valid numbers in both fields
        if ~isnan(valA) && ~isnan(valB)
            % Execute based on the condition specified
            switch rawCond
                case 'and' % If it is an 'and' condition
                    % Switch the A and B to do a between filter
                    valuesFilt = [valB valA];
                case 'or' % If it is an 'or' condition
                    % Add a NaN to let the fetch function know to get the tails
                    valuesFilt = [valA NaN valB];
            end
        else
            % One is a NaN, set them in this order as the NaN will presist
            valuesFilt = [valB valA];
        end
        
        %% Fetch Data From Database
        try
            % Go and get the data
            d = handles.c.getEventData(SEID,ExtID,'software',sw,'date',date,'trip',trip,'emb',emb,'values',valuesFilt,'engfam',engfam,'vehtype',vehtype,'vehicle',vehicle);
        catch ex
            % Look for if the connection to the database couldn't be established
            if strcmp('database:database:connectionFailure',ex.identifier)
                % Delete the message that data is being fetched from the database
                if ishandle(h), delete(h), end
                % Display a warning message to the user
                msgbox({'Could not establish a connection to the database.', ...
                        'Please make sure you are connected to the Cummins Inc. network.'}, ...
                        'Error', 'warn', 'modal');
                % Set the return data to empty sets and return from the function
                data = {};header = {};abs_time = [];return
            else
                % Rethrow the original exception
                rethrow(ex)
            end
        end
        % If no data was returned
        if isempty(d)
            % Delete the message that data is being fetched from the database
            if ishandle(h), delete(h), end
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!', 'Error', 'warn', 'modal')
            % Set the return data to empty sets and return from the function
            data = {};header = {};abs_time = [];return
        end
        
        %% Format Data
        % Change the message to a warning that the data is being formatted
        h = msgbox('Formatting data from the database (creating date strings). Please Wait.','Working...','replace');
        % Remove the OK button
        child = get(h,'Children');
        delete(child(end))
        pause(0.02)
        
        % Pull out the abs_time values for the function output argument
        abs_time = d.datenum;
        % Convert to a cell array ready for the rawData GUI window
        data = cell(length(d.datenum),7);
        data(:,1) = num2cell(mod(d.datenum,1)*24);
        %data(:,2) = cellstr(datestr(d.datenum,'yymmdd HH:MM:SS'));
        data(:,2) = cellstr(datestr(d.datenum,31));
        
        d = rmfield(d, 'datenum'); % Remove datenum field to conserve memory as we're done with it
        
        %data(:,3) = cellstr(datestr(d.datenum));
        data(:,3) = num2cell(d.ECMRunTime);
        data(:,4) = d.TruckName;
        data(:,5) = d.Family;
        data(:,6) = num2cell(d.CalibrationVersion);
        data(:,7) = num2cell(d.DataValue);
        % Make the header row to label the data
        header = {'tod', 'Date/Time (UTC)', 'ECM_Run_Time', ...
                  'Truck Name', 'Family', 'Software', handles.c.filt.CriticalParam};
    end
end

% -----------------------------------------------------------------------------

function in = generateMatVarName(in)
%Used to trim illegal Matlab characters from variable names and shorten them to length
%   Some data broadcast is a calculation of two different parameters and the name notes
%   this distinction. However, this will cause a problem with eval if you try to create a
%   variable and have the name contain the following characters (-, (, ), *, /, +, etc.)

% Look for illegal characters
idx = (in=='-' | in=='(' | in==')' | in=='/' | in=='*' | in=='+' | in==' ');
% If there were any illegal characters
if sum(idx)>0
    % Replace them with an underscore
    in(idx) = '_';
end
% If the first character got replaced with an underscore
if in(1)=='_'
    % Drop it from the name
    in = in(2:end);
end
% If the name is too long, truncate it to 63 characters (the Matlab max)
if length(in)>63
    in = in(1:63);
end

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstVehType.
function lstVehType_Callback(hObject, eventdata, handles)
% hObject    handle to lstVehType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstVehType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstVehType

% Update the list of possible vehicles
updatePossibleVehicles(handles)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstVehType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstVehType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstFamily.
function lstFamily_Callback(hObject, eventdata, handles)
% hObject    handle to lstFamily (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstFamily contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstFamily

% Update the list of possible vehicles
updatePossibleVehicles(handles)
% Update the spec values for the selected engine family
updateSpecValues(handles)

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstFamily_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstFamily (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstTrucks.
function lstTrucks_Callback(hObject, eventdata, handles)
% hObject    handle to lstTrucks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstTrucks contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstTrucks

% If every possible truck was selected
if length(get(hObject,'String')) == length(get(hObject,'Value'))
    % Set the falg to ignore the vehicle specific filtering
    handles.c.filt.byVehicle = 0;
else
    % Set the flag that the user has changed the truck select so filter using that instead
    handles.c.filt.byVehicle = 1;
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstTrucks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstTrucks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes on button press in btnDotPlot.
function btnDotPlot_Callback(hObject, eventdata, handles)
% hObject    handle to btnDotPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(get(handles.txtSEPlot, 'String'))
    % Display an error message
    msgbox('No system error is selected.', 'Error', 'error')
    % Exit the function
    return
end

% Time how long it takes to make a plot
tic

% Update the filtering values with the current settings
updateFilterValues(handles)
if handles.c.filt.date(1)>=handles.c.filt.date(2)
    msgbox('End Date should be greater than Start Date', 'Date Filtering Error', 'error')
end

% Set the Dot plot object properties
handles.c.fillDotInfo

% Get the spec limit values based on the user input
LSLuser = str2double(get(handles.txtLSLValue, 'String'));
USLuser = str2double(get(handles.txtUSLValue, 'String'));
% Get the mainline cal spec limit
LSLcal = handles.c.filt.LSL;
USLcal = handles.c.filt.USL;
% If the LSL limit was changed from the value in the cal
if (abs(LSLcal - LSLuser) >= 0.01 || isnan(LSLcal)&&~isnan(LSLuser)) && ~(isnan(LSLcal) && isnan(LSLuser))
    % Make the parameter name this value instead
    handles.c.dot.LSLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the dot plot object
    handles.c.dot.LSL = LSLuser;
elseif isnan(LSLuser) && ~isnan(LSLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.dot.LSLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.dot.LSL = NaN;
end
% If the USL limit was changed from the value in the cal
if (abs(USLcal - USLuser) >= 0.01 || isnan(USLcal)&&~isnan(USLuser)) && ~(isnan(handles.c.filt.USL) && isnan(USLuser))
    % Make the parameter name this value instead
    handles.c.dot.USLName = 'User_Specified_Value';
    % Set the user-specified spec limit in the dot plot object
    handles.c.dot.USL = USLuser;
elseif isnan(USLuser) && ~isnan(USLcal) % If the LSL was removed by the user
    % Make the parameter name 'null'
    handles.c.dot.USLName = '';
    % Set the spec limit to a NaN to get rid of it
    handles.c.dot.USL = NaN;
end

% Get the grouping setting
if get(handles.rdoByTruck, 'Value')
    group = 1;
elseif get(handles.rdoByFamily, 'Value')
    group = 2;
elseif get(handles.rdoByMonth, 'Value')
    group = 3;
else % get(handles.rdoBySoftware, 'Value')
    group = 0;
end

% Get the second grouping setting
if get(handles.rdoByTruck2, 'Value')
    group2 = 1;
elseif get(handles.rdoByFamily2, 'Value')
    group2 = 2;
elseif get(handles.rdoByMonth2, 'Value')
    group2 = 3;
elseif get(handles.rdoBySoftware2, 'Value')
    group2 = 0;
else % get(handles.rdoByNone2, 'Value')
    group2 = -1;
end

% Display a warning that data is being fetched
h = msgbox('Fetching data from database. Please Wait.','Working...');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Try to fetch and fill data into the dot object
try
    % Fill the data into the dot object
    handles.c.fillDotData(group,group2)
catch ex
    % Handle the case of when there is no data found
    switch ex.identifier
        case 'Capability:fillDotData:NoDataFound'
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!',...
                'Error', 'warn', 'modal')
            % Reset the dot object to clear the system error information
            handles.c.dot.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'database:database:connectionFailure'
            % Display a warning messge to the user
            msgbox({'Could not establish a connection to the database.', ...
                'Please make sure you are connected to the Cummins Inc. network.'}, ...
                'Error', 'warn', 'modal')
            % Reset the dot object to clear the system error information
            handles.c.dot.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        otherwise
            % Rethrow the original exception
            rethrow(ex)
    end
end
% Change the message to a warning that the plot is being generated
h = msgbox('Generating requested plot. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Generate the plot, set it to display when made
handles.c.dot.makePlot(1)
% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Reset the dot object as the plot has already been made
handles.c.dot.reset

% Plot completed, print time to the workspace
toc

% -----------------------------------------------------------------------------

% --- Executes on selection change in lstProgram.
function lstProgram_Callback(hObject, eventdata, handles)
% hObject    handle to lstProgram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstProgram contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstProgram

% Get the name of the progam to connect to
program = get(handles.lstProgram,'UserData');
program = program{get(handles.lstProgram,'Value')};
programDisp = get(handles.lstProgram,'String');
programDisp = programDisp{get(handles.lstProgram,'Value')};

% Note the currently connect to database (assumption that it was working)
currentDB = handles.c.program;
% Find the index of the current database
currentDBIdx = find(strcmp(currentDB,get(handles.lstProgram,'UserData')));
% Find the display name of the currently connected to database
currentDBDisp = get(handles.lstProgram,'String');
currentDBDisp = currentDBDisp{currentDBIdx};

% Clear out the software filtering values because those shouldn't persist across programs
set(handles.txtFromSW,'String','')
set(handles.txtToSW,'String','')

try
    % Change the engine program of the object
    handles.c.program = program;
    % Update the GUI with the new program's information
    updateProgramInfo(handles)
catch ex
    % Error handling
    switch ex.identifier
        % If there weren't permissions for the new program
        case {'Capability:InvalidProgram','database:database:cursorError'}
            try
                % Try to reconnect to the old program
                handles.c.program = currentDB;
                % Update the GUI with the new program's information
                updateProgramInfo(handles)
                % Re-set the selector box to the old selection
                set(handles.lstProgram,'Value',currentDBIdx)
                % Display a message about what happened
                msgbox(['You may not have permission to connect to the "' programDisp '" database. Reconnecting back to the "' currentDBDisp '" database.'],'Error','error')
            catch ex
                % If this fails, empty out the GUI
                emptyGUI(handles)
                % Display a message
                msgbox(['Failed to connect to either the selected database of "' programDisp '" or the previous database of "' currentDBDisp '".'],'Error','error')
            end
        case 'Capability:UnableToConnect'
            % Empty out the GUI
            emptyGUI(handles)
            % Print a message box, try again later
            msgbox('Unable to establish a connection to the database. Please check that you are connected to the Cummins network.','Error','error')
        case 'MATLAB:license:checkouterror'
            % Empty out the GUI
            emptyGUI(handles)
            % Print a message box, try again later
            msgbox('Matlab was unable to check-out a license for the Database toolbox. Please try again later.','Error','error')
        otherwise
            % Empty out the GUI
            emptyGUI(handles)
            % Print the error to the workspace
            disp(ex.getReport)
            % Print a message box, try again later
            msgbox(['Unknown error occured connecting to the "' programDisp '" database. See the workspace for a detailed error message.'],'Error','error')
    end
end

% -----------------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function lstProgram_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstProgram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% -----------------------------------------------------------------------------

% --- Executes when selected object is changed in pnlGroupBy.
function pnlGroupBy_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in pnlGroupBy 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% This shouldn't do anything

% -----------------------------------------------------------------------------

% --- Executes on button press in btnTruckInfo.
function btnTruckInfo_Callback(hObject, eventdata, handles)
% hObject    handle to btnTruckInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Pop up information about the trucks with data

% Make a cell array
data = cell(length(handles.c.tblTrucks.TruckName),14);
% Fill in the data
data(:,1) = handles.c.tblTrucks.TruckName;
data(:,2) = handles.c.tblTrucks.Family;
data(:,3) = handles.c.tblTrucks.TruckType;
data(:,4) = handles.c.tblTrucks.Rating;
data(:,5) = num2cell(handles.c.tblTrucks.SoftwareCache);
data(:,6) = num2cell(handles.c.tblTrucks.RevisionCache);
data(:,7) = handles.c.tblTrucks.ECMCode;
data(:,8) = handles.c.tblTrucks.LastFileDateTime;
data(:,9) = cellstr(num2str(now-handles.c.tblTrucks.LastFileDatenum,'%0.1f'));
data(:,10) = handles.c.tblTrucks.ETDVersion;
data(:,11) = handles.c.tblTrucks.CaltermVersion;
data(:,12) = handles.c.tblTrucks.EventData;
data(:,13) = handles.c.tblTrucks.MinMaxData;
data(:,14) = handles.c.tblTrucks.MMMTurnedOn;
data(:,15) = handles.c.tblTrucks.SinceWhenNoCapabilityData;
data(:,16) = num2cell(handles.c.tblTrucks.DaysofNoCapabilityData);
data(:,17) = handles.c.tblTrucks.IUPRData;
data(:,18) = handles.c.tblTrucks.SinceWhenNoIUPRData;
data(:,19) = num2cell(handles.c.tblTrucks.DaysofNoIUPRData);

% Trim rows without a software cache (i.e. vehicle that probably never had data)
%data = data(~isnan(handles.c.tblTrucks.SoftwareCache),:);
data = data(~strcmp('null',handles.c.tblTrucks.LastFileDateTime),:);
% Clean out null and NaN
for i = 1:numel(data)
    if strcmp('null',data{i}) || any(isnan(data{i})) || ~isempty(strfind(data{i},'NaN'))
        data{i} = '';
    end
end
% Sort data by truck name
data = sortrows(data,1);

% Fill in header row
header = {'Vehicle','Family','Vehicle Type','Rating','Last Software','Cal Rev',...
          'ECM Code','Last File Date','ditw','ETD Version','CaltermVersion',...
          'EventData','MinMaxData','Capability Data On','SinceWhenNoCapabilityData','DaysofNoCapabilityData','IUPRData On',...
          'SinceWhenNoIUPRData','DaysofNoIUPRData'};

% Use RawData to display this info
rawData(data, header, [], ['Truck Information for ' handles.c.program])

% -----------------------------------------------------------------------------

% --- Executes on button press in btnPpkChart.
function btnPpkChart_Callback(hObject, eventdata, handles)
% hObject    handle to btnPpkChart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Time how long it takes to make a plot
tic

% Update the filtering values with the current settings
updateFilterValues(handles)

% Set the ppk object properties
handles.c.fillCapHistInfo

h = msgbox('Fetching data from database. Please Wait.','Working...');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Try to fetch and fill data into the ppk plotter object
try
    % Fill in the data into the ppk object
    handles.c.fillCapHistData
catch ex
    % Handles errors
    switch ex.identifier
        case 'Capability:fillCapHistData:NoDataFound'
            % Display a warning message to the user
            msgbox('No data found for specified system error and filtering!',...
                'Error', 'warn', 'modal')
            % Reset the ppk object to clear the system error information
            handles.c.caphist.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        case 'database:database:connectionFailure'
            % Display a warning messge to the user
            msgbox({'Could not establish a connection to the database.', ...
                'Please make sure you are connected to the Cummins Inc. network.'}, ...
                'Error', 'warn', 'modal')
            % Reset the ppk object to clear the system error information
            handles.c.caphist.reset
            % Delete the message that data is being fetched from the database
            if ishandle(h),delete(h),end
            % Return from the function and don't make the plot
            return
        otherwise
            % Rethrow the original expection
            rethrow(ex)
    end
end
% Change the message to a warning that the plot is being generated
h = msgbox('Generating requested plot. Please Wait.','Working...','replace');
% Remove the OK button
child = get(h,'Children');
delete(child(end))
pause(0.02)
% Generatre the plot, set it to display when made
handles.c.caphist.makePlot(1)
% Close the msgbox if it still exists
if ishandle(h)
    delete(h)
end
% Reset the ppk object as the plot has already been made
handles.c.caphist.reset

% Plot completed, print time to the workspace
toc

% -----------------------------------------------------------------------------

function emptyGUI(handles)
% Empty out the GUI contents to indicate that something is wrong

% Plots listing
set(handles.lstSEPlots,'Value',1)
set(handles.lstSEPlots,'String',{'Error'})

% Truck listing
set(handles.lstTrucks,'Value',1)
set(handles.lstTrucks,'String',{'Error'})

% Vehicle Type listing
set(handles.lstVehType,'Value',1)
set(handles.lstVehType,'String',{'Error'})

% Family listing
set(handles.lstFamily,'Value',1)
set(handles.lstFamily,'String',{'Error'})
