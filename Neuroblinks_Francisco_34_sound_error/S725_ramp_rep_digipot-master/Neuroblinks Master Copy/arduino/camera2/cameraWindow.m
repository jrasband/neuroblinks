function varargout = cameraWindow(varargin)
% CAMERAWINDOW MATLAB code for cameraWindow.fig
%      CAMERAWINDOW, by itself, creates a new CAMERAWINDOW or raises the existing
%      singleton*.
%
%      H = CAMERAWINDOW returns the handle to a new CAMERAWINDOW or the handle to
%      the existing singleton*.
%
%      CAMERAWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAMERAWINDOW.M with the given input arguments.
%
%      CAMERAWINDOW('Property','Value',...) creates a new CAMERAWINDOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cameraWindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cameraWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cameraWindow

% Last Modified by GUIDE v2.5 30-Aug-2016 21:49:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cameraWindow_OpeningFcn, ...
                   'gui_OutputFcn',  @cameraWindow_OutputFcn, ...
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


% --- Executes just before cameraWindow is made visible.
function cameraWindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cameraWindow (see VARARGIN)


% Choose default command line output for cameraWindow
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes cameraWindow wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cameraWindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cam2 = getappdata(0,'cam2');

if strcmp(cam2.triggermode,'Sync trials')
    instantReplay(getappdata(0,'lastvideo2'),getappdata(0,'lastmetadata'))
else
    instantReplay(getappdata(0,'lastvideo2'))
end


% --- Executes on button press in togglebutton_startStopPreview.
function togglebutton_startStopPreview_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_startStopPreview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

vidobj2 = getappdata(0,'vidobj2');

if hObject.Value == 1
    set(hObject,'String','Stop Preview')
    pwin=image(zeros(480,640), 'Parent',handles.cameraAx2);
    preview(vidobj2,pwin)
else
    set(hObject,'String','Start Preview')
    stoppreview(vidobj2)
end


% --- Executes on button press in togglebutton_cameraManualAcquire.
function togglebutton_cameraManualAcquire_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_cameraManualAcquire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if hObject.Value == 1
    set(hObject,'String','Stop acquiring')
    startCamera2()
else
    set(hObject,'String','Acquire frames')
    stopCamera2()
end


% --- Executes on button press in togglebutton_cameraConnect.
function togglebutton_cameraConnect_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_cameraConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% CAMERA_LOCATION = 'contra_eye';
CAMERA_LOCATION = 'body';

if hObject.Value == 1
    
    
    TDT = getappdata(0,'tdt');
    
    set(hObject,'String','Disconnect Cam')
    set(handles.popupmenu_cameraRecordMode,'Value',1)
    set(handles.togglebutton_cameraManualAcquire, 'Enable', 'On')
    
    switch CAMERA_LOCATION
        case 'body'
            vidobj2 = addCam('14158');
        case 'contra_eye'
            vidobj2 = addCam('02-2020C-07418');
    end
   
    src=getselectedsource(vidobj2);
    
    % Initialize camera
%    switch CAMERA_LOCATION
%        case 'body'
%            src.ExposureTimeAbs = 2000;
%        case 'contra_eye'
%            src.ExposureTimeAbs = 4900;
%    end

%    src.GainRaw = 0;
%    src.StreamBytesPerSecond=80e6;
%    src.AcquisitionFrameRateAbs=200;
    src.TriggerMode = 'On';
    src.TriggerActivation = 'LevelHigh';
%    src.TriggerSource = 'Freerun';
    
    vidobj2.TriggerRepeat = 0;
    vidobj2.FramesPerTrigger = Inf;
    
    triggerconfig(vidobj2, 'hardware');
    
    cam2.trialnum = 1;
    cam2.triggermode = 'Manual';
 %   TDT.setParameterValue('RZ5(1)','Cam2Manual',1);

    setappdata(0,'cam2',cam2);
    setappdata(0,'vidobj2',vidobj2);
else
    set(hObject,'String','Connect Cam')
    if isappdata(0,'vidobj2')
        vidobj2 = getappdata(0,'vidobj2');
        delete(vidobj2);
    end
end


% --- Executes on selection change in popupmenu_cameraRecordMode.
function popupmenu_cameraRecordMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_cameraRecordMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_cameraRecordMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_cameraRecordMode

mode = hObject.String{hObject.Value};

TDT = getappdata(0,'tdt');
vidobj2 = getappdata(0,'vidobj2');
cam2=getappdata(0,'cam2');
cam2.triggermode = mode;
setappdata(0,'cam2',cam2);  % So the rest of the program knows what mode we're in

% Use a switch statement here in case we want to do something different for
% the other modes later
switch mode
    case {'Manual','Manual to disk'}
        set(handles.togglebutton_cameraManualAcquire, 'Enable', 'On')
        vidobj2.FramesPerTrigger = Inf; % Have to reset this bc MainWindow alters it during sync trial mode
        TDT.setParameterValue('RZ5(1)','Cam2Manual',1);
    otherwise
        set(handles.togglebutton_cameraManualAcquire, 'Enable', 'Off')
        TDT.setParameterValue('RZ5(1)','Cam2Manual',0);
end

if strcmp(mode,'Manual to disk')
    % Set up to record compressed file to disk
    vidobj2.LoggingMode = 'disk';
else
    % Set up to record to memory
    vidobj2.LoggingMode = 'memory';
end

% --- Executes during object creation, after setting all properties.
function popupmenu_cameraRecordMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_cameraRecordMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_resetTrialNum.
function pushbutton_resetTrialNum_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_resetTrialNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cam2 = getappdata(0,'cam2');

cam2.trialnum = 1;

disp('Trial number reset for Camera 2')

setappdata(0,'cam2',cam2);


% --- Executes on button press in pushbutton_manualNow.
function pushbutton_manualNow_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_manualNow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% This function saves the user a little time when it's critical by
% combining two steps: select manual mode and trigger manual recording

set(handles.popupmenu_cameraRecordMode,'Value',1);
popupmenu_cameraRecordMode_Callback(handles.popupmenu_cameraRecordMode, eventdata, handles);

set(handles.togglebutton_cameraManualAcquire,'Value',1);
togglebutton_cameraManualAcquire_Callback(handles.togglebutton_cameraManualAcquire, eventdata, handles);
