function varargout = BodyCamWindow(varargin)
% BodyCamWindow MATLAB code for BodyCamWindow.fig
%      BodyCamWindow, by itself, creates a new BodyCamWindow or raises the existing
%      singleton*.
%
%      H = BodyCamWindow returns the handle to a new BodyCamWindow or the handle to
%      the existing singleton*.
%
%      BodyCamWindow('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BodyCamWindow.M with the given input arguments.
%
%      BodyCamWindow('Property','Value',...) creates a new BodyCamWindow or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BodyCamWindow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BodyCamWindow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BodyCamWindow

% Last Modified by GUIDE v2.5 21-Mar-2022 12:50:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0; %Fixed to 0 to allow several instances of the same window.
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BodyCamWindow_OpeningFcn, ...
                   'gui_OutputFcn',  @BodyCamWindow_OutputFcn, ...
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


% --- Executes just before BodyCamWindow is made visible.
function BodyCamWindow_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to BodyCamWindow (see VARARGIN)

    % Choose default command line output for BodyCamWindow
    handles.output = hObject;

    
    %Set body cam index.
    handles.body_cam_index = varargin{1};
    
    
    % Update handles structure
    guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = BodyCamWindow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on button press in pushbutton_StartStopPreview.
function pushbutton_StartStopPreview_Callback(hObject, eventdata, handles)
    vidobj_body=getappdata(0,['vidobj_body_' num2str(handles.body_cam_index)]);
    % Start/Stop Camera
    if strcmp(get(handles.pushbutton_StartStopPreview,'String'),'Start Preview')
        % Camera is off. Change button string and start camera.
        set(handles.pushbutton_StartStopPreview,'String','Stop Preview')      
      
        imx=[0:800];
        imy=[0:600];
        handles.pwin3=image(imx,imy,zeros(600, 800), 'Parent',handles.cameraAx_3);
        preview(vidobj_body,handles.pwin3);
    else
        % Camera is on. Stop camera and change button string.
        stopPreview(handles);
    end

    guidata(hObject,handles) 
      
      

      
 
    
function stopPreview(handles)
    % Pulled this out as a function so it can be called from elsewhere
    vidobj_body=getappdata(0,['vidobj_body_' num2str(handles.body_cam_index)]);

    set(handles.pushbutton_StartStopPreview,'String','Start Preview')
    closepreview(vidobj_body);    




% --- Executes on button press in pushbutton4.
function pushbutton_instantreplay_Callback(hObject, eventdata, handles)
    instantReplayBody(getappdata(0,['lastdata_body_' num2str(handles.body_cam_index)]),getappdata(0,'lastmetadata'));
