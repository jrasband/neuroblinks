function varargout = SecondEyeWindows(varargin)
% SECONDEYEWINDOWS MATLAB code for SecondEyeWindows.fig
%      SECONDEYEWINDOWS, by itself, creates a new SECONDEYEWINDOWS or raises the existing
%      singleton*.
%
%      H = SECONDEYEWINDOWS returns the handle to a new SECONDEYEWINDOWS or the handle to
%      the existing singleton*.
%
%      SECONDEYEWINDOWS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SECONDEYEWINDOWS.M with the given input arguments.
%
%      SECONDEYEWINDOWS('Property','Value',...) creates a new SECONDEYEWINDOWS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SecondEyeWindows_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SecondEyeWindows_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SecondEyeWindows

% Last Modified by GUIDE v2.5 04-Mar-2021 09:14:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SecondEyeWindows_OpeningFcn, ...
                   'gui_OutputFcn',  @SecondEyeWindows_OutputFcn, ...
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


% --- Executes just before SecondEyeWindows is made visible.
function SecondEyeWindows_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to SecondEyeWindows (see VARARGIN)

    % Choose default command line output for SecondEyeWindows
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes SecondEyeWindows wait for user response (see UIRESUME)
    % uiwait(handles.figure1);

    src_eye_2=getappdata(0,'src_eye_2');
    metadata=getappdata(0,'metadata');
    
    metadata.cam_eye_2.fps=src_eye_2.AcquisitionFrameRate; %in frames per second
    metadata.cam_eye_2.thresh=0.125;
    metadata.cam_eye_2.trialnum=1;
    metadata.eye_2.trialnum1=1;  %  for conditioning
    metadata.eye_2.trialnum2=1;

    metadata.cam_eye_2.time(1) = metadata.cam.time(1);
    metadata.cam_eye_2.time(3) = metadata.cam.time(3);
    metadata.cam_eye_2.cal = 0;
    metadata.cam_eye_2.calib_offset = 0;
    metadata.cam_eye_2.calib_scale = 1;
    
    setappdata(0,'metadata',metadata);


% --- Outputs from this function are returned to the command line.
function varargout = SecondEyeWindows_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% % --- Executes on button press in pushbutton_setROI.
% function pushbutton_setROI_Callback(hObject, eventdata, handles)
% 
%     vidobj_eye_2=getappdata(0,'vidobj_eye_2');
%     metadata=getappdata(0,'metadata');
% 
%     if isfield(metadata.cam_eye_2,'winpos')
%         winpos_2=metadata.cam_eye_2.winpos;
%         winpos_2(1:2)=winpos_2(1:2)+metadata.cam_eye_2.vidobj_ROIposition(1:2);
%     else
%         winpos_2=[0 0 800 600];
%     end
% 
%     % Place rectangle on vidobj
%     % h=imrect(handles.cameraAx,winpos);
%     h=imellipse(handles.cameraAx_2,winpos_2);
% 
%     % fcn = makeConstrainToRectFcn('imrect',get(handles.cameraAx,'XLim'),get(handles.cameraAx,'YLim'));
%     fcn = makeConstrainToRectFcn('imellipse',get(handles.cameraAx_2,'XLim'),get(handles.cameraAx_2,'YLim'));
%     setPositionConstraintFcn(h,fcn);
% 
%     % metadata.cam.winpos=round(wait(h));
%     XY=round(wait(h));  % only use for imellipse
%     metadata.cam_eye_2.winpos=round(getPosition(h));
%     metadata.cam_eye_2.winpos(1:2)=metadata.cam_eye_2.winpos(1:2)-metadata.cam_eye_2.vidobj_ROIposition(1:2);
%     metadata.cam_eye_2.mask=createMask(h);
% 
%     wholeframe=getsnapshot(vidobj_eye_2);
%     binframe=im2bw(wholeframe,metadata.cam_eye_2.thresh);
%     eyeframe=binframe.*metadata.cam_eye_2.mask;
%     metadata.cam_eye_2.pixelpeak=sum(sum(eyeframe));
% 
%     hp=findobj(handles.cameraAx_2,'Tag','roipatch');
%     delete(hp)
%     % handles.roipatch=patch([xmin,xmin+width,xmin+width,xmin],[ymin,ymin,ymin+height,ymin+height],'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
%     % XY=getVertices(h);
%     delete(h);
%     handles.roipatch=patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
%     handles.XY=XY;
% 
%     setappdata(0,'metadata',metadata);
%     guidata(hObject,handles)


% --- Executes on button press in pushbutton_setROI.
function pushbutton_setROI_Callback(hObject, eventdata, handles)

    vidobj_eye_2=getappdata(0,'vidobj_eye_2');
    metadata=getappdata(0,'metadata');

    if isfield(metadata.cam_eye_2,'winpos')
        winpos_2=metadata.cam_eye_2.winpos;
        winpos_2(1:2)=winpos_2(1:2)+metadata.cam_eye_2.vidobj_ROIposition(1:2);
    else
        winpos_2=[0 0 800 600];
    end

    % Place elipse on vidobj
    h = drawellipse(handles.cameraAx_2);
    
    %wait until the user fix the ellipse position
    XY=round(customWait(h));

    x_pos = min(XY(:,1));
    x_size = max(XY(:,1)) - x_pos;
    y_pos = min(XY(:,2));
    y_size = max(XY(:,2)) - y_pos;
    metadata.cam_eye_2.winpos = [x_pos, y_pos, x_size, y_size] ;
    metadata.cam_eye_2.winpos(1:2)=metadata.cam_eye_2.winpos(1:2)-metadata.cam_eye_2.vidobj_ROIposition(1:2);
    metadata.cam_eye_2.mask=createMask(h);

    wholeframe=getsnapshot(vidobj_eye_2);
    binframe=im2bw(wholeframe,metadata.cam_eye_2.thresh);
    eyeframe=binframe.*metadata.cam_eye_2.mask;
    metadata.cam_eye_2.pixelpeak=sum(sum(eyeframe));

    hp=findobj(handles.cameraAx_2,'Tag','roipatch');
    delete(hp)
    % handles.roipatch=patch([xmin,xmin+width,xmin+width,xmin],[ymin,ymin,ymin+height,ymin+height],'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
    % XY=getVertices(h);
    delete(h);
    handles.roipatch=patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
    handles.XY=XY;

    setappdata(0,'metadata',metadata);
    guidata(hObject,handles)


function pos = customWait(hROI)

    % Listen for mouse clicks on the ROI
    l = addlistener(hROI,'ROIClicked',@clickROICallback);

    % Block program execution
    uiwait;

    % Remove listener
    delete(l);

    % Return the current position
    %pos = hROI.Position;
    pos = hROI.Vertices;

function clickROICallback(~,evt)

    if strcmp(evt.SelectionType,'double')
        uiresume;
    end


% --- Executes on button press in pushbutton_StartStopPreview.
function pushbutton_StartStopPreview_Callback(hObject, eventdata, handles)
    vidobj_eye_2=getappdata(0,'vidobj_eye_2');
    %vidobj_eye_2=getappdata(0,'vidobj');
    metadata=getappdata(0,'metadata');

    if ~isfield(metadata.cam_eye_2,'fullsize')
        metadata.cam_eye_2.fullsize = [0 0 800 600];
    end
    metadata.cam_eye_2.vidobj_ROIposition=vidobj_eye_2.ROIposition;

    % Start/Stop Camera
    if strcmp(get(handles.pushbutton_StartStopPreview,'String'),'Start Preview')
        % Camera is off. Change button string and start camera.
        set(handles.pushbutton_StartStopPreview,'String','Stop Preview')
        % Send camera preview to GUI
        imx=metadata.cam_eye_2.vidobj_ROIposition(1)+[1:metadata.cam_eye_2.vidobj_ROIposition(3)];
        imy=metadata.cam_eye_2.vidobj_ROIposition(2)+[1:metadata.cam_eye_2.vidobj_ROIposition(4)];
        handles.pwin2=image(imx,imy,zeros(metadata.cam_eye_2.vidobj_ROIposition([4 3])), 'Parent',handles.cameraAx_2);

        preview(vidobj_eye_2,handles.pwin2);
        set(handles.cameraAx_2,'XLim', 0.5+metadata.cam_eye_2.fullsize([1 3])),
        set(handles.cameraAx_2,'YLim', 0.5+metadata.cam_eye_2.fullsize([2 4])),
        hp=findobj(handles.cameraAx_2,'Tag','roipatch');  delete(hp)
        if isfield(handles,'XY')
            handles.roipatch=patch(handles.XY(:,1),handles.XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
        end

        ht=findobj(handles.cameraAx_2,'Tag','trialtimecounter');
    %     delete(ht)

        axes(handles.cameraAx_2)
%         handles.trialtimecounter = text(790,590,' ','Color','c','HorizontalAlignment','Right',...
%             'VerticalAlignment', 'Bottom', 'Visible', 'Off', 'Tag', 'trialtimecounter',...
%             'FontSize',18);
    else
        % Camera is on. Stop camera and change button string.
        stopPreview(handles);
    end

    setappdata(0,'metadata',metadata);
    guidata(hObject,handles)
    
    
function stopPreview(handles)
    % Pulled this out as a function so it can be called from elsewhere
    vidobj_eye_2=getappdata(0,'vidobj_eye_2');

    set(handles.pushbutton_StartStopPreview,'String','Start Preview')
    closepreview(vidobj_eye_2);    


% --- Executes on button press in togglebutton_stream.
function togglebutton_stream_Callback(hObject, eventdata, handles)
    if get(hObject,'Value'),
        set(hObject,'String','Stop Streaming')
        %stream2(handles)
        startStreaming2(handles)
    else
        set(hObject,'String','Start Streaming')
        stopStreaming2(handles)
    end

function stopStreaming2(handles)

    set(handles.togglebutton_stream,'String','Start Streaming')
    setappdata(handles.pwin2,'UpdatePreviewWindowFcn',[]);    
    
function startStreaming2(handles)

    set(handles.togglebutton_stream,'String','Stop Streaming')
    setappdata(handles.pwin2,'UpdatePreviewWindowFcn',@newFrame2Callback);
    
    
function newFrame2Callback(obj,event,himage)
    ghandles=getappdata(0,'ghandles');
    handles=guidata(ghandles.secondeyegui);
    % vidobj=getappdata(0,'vidobj');
    %src=getappdata(0,'src_eye_2');
    metadata=getappdata(0,'metadata');

    persistent timeOfStreamStart

    if isempty(timeOfStreamStart)
        timeOfStreamStart=clock;
    end

    persistent timeSinceLastTrial

    if isempty(timeSinceLastTrial)
        timeSinceLastTrial=clock;
    end

    persistent eyedata

    if isempty(eyedata)
        eyedata=NaN*ones(500,2);
    end

    plt_range=-2100;

    persistent eyeTrace

    if isempty(eyeTrace)
        set(0,'currentfigure',ghandles.secondeyegui)
    %     set(ghandles.maingui,'CurrentAxes',handles.axes_eye)
    %     cla
        eyeTrace=plot(handles.axes_eye_2,[plt_range 0],[1 1]*0,'k-',[plt_range 0],[1 1]*0.2,'r--'); hold on
        set(handles.axes_eye_2,'color',[240 240 240]/255,'YAxisLocation','right');
        set(handles.axes_eye_2,'xlim',[plt_range 0],'ylim',[-0.1 1.1])
        set(handles.axes_eye_2,'xtick',[-3000:500:0],'box','off')
        set(handles.axes_eye_2,'ytick',[0:0.5:1],'yticklabel',{'0' '' '1'})
    end


    % --- eye trace ---
    wholeframe = event.Data;
    roi=wholeframe.*uint8(metadata.cam_eye_2.mask);
    eyelidpos=sum(roi(:)>=256*metadata.cam_eye_2.thresh);

    % --- eye trace buffer ---
    eyedata(1:end-1,:)=eyedata(2:end,:);
    timeSinceStreamStartMS=round(1000*etime(clock,timeOfStreamStart));
    eyedata(end,1)=timeSinceStreamStartMS;
    eyedata(end,2)=(eyelidpos-metadata.cam_eye_2.calib_offset)/metadata.cam_eye_2.calib_scale; % eyelid pos

    set(eyeTrace(1),'XData',eyedata(:,1)-timeSinceStreamStartMS,'YData',eyedata(:,2))
    eyeThreshold=getappdata(0,'eyeThreshold');
    set(eyeTrace(2),'XData',eyedata(:,1)-timeSinceStreamStartMS,'YData',ones(1,length(eyedata))*eyeThreshold)
    set(himage,'CData',event.Data)
    
    
    %We store this value en a global array to check the eyelid position in
    %the main windows before each trial
    setappdata(0,'eyedata_2',eyedata);
    
    
%    try
%     % --- Check if new trial should be triggered ----
%     if get(handles.toggle_continuous,'Value') == 1
% 
%         stopTrial = str2double(get(handles.edit_StopAfterTrial,'String'));
%         if stopTrial > 0 && metadata.cam.trialnum > stopTrial
%             set(handles.toggle_continuous,'Value',0);
%             set(handles.toggle_continuous,'String','Start Continuous');
%         end
% 
%         elapsedTimeSinceLastTrial=etime(clock,timeSinceLastTrial);
%         timeLeft = metadata.stim.c.ITI - elapsedTimeSinceLastTrial;
% 
%         set(handles.trialtimecounter,'String',num2str(round(timeLeft)))
% 
%         if timeLeft <= 0
%             eyeok=checkeye(handles,eyedata);
%             if eyeok
%                 TriggerArduino(handles)
%                 timeSinceLastTrial=clock;
%             end
%         end
%     end
%    catch
%         try % If it's a dropped frame, see if we can recover
%             handles.pwin2=image(zeros(600,800),'Parent',handles.cameraAx);
%             pause(0.5)
%             closepreview(vidobj);
%             pause(0.2)
%             preview(vidobj,handles.pwin2);
%         %     guidata(handles.cameraAx,handles)
%             stream(handles)
%             disp('Caught camera error')
%         catch
%             disp('Aborted eye streaming.')
%             set(handles.togglebutton_stream,'Value',0);
%         %     set(handles.pushbutton_StartStopPreview,'String','Start Preview')
%         %     closepreview(vidobj);
%             return
%         end
%     end
    
    
function stream2(handles)
    ghandles=getappdata(0,'ghandles');
    vidobj_eye_2=getappdata(0,'vidobj_eye_2');
    % updaterate=0.017;   % ~67 Hz
    % updaterate=0.1;   % 10 Hz
    if ~exist('t1','var')
        t1=clock;
    end
    t0=clock;

    eyedata2=NaN*ones(500,2);
    plt_range=-2100;

    if get(handles.togglebutton_stream,'Value')
        set(0,'currentfigure',ghandles.secondeyegui)
        set(ghandles.secondeyegui,'CurrentAxes',handles.axes_eye_2)
        cla
        pl1=plot([plt_range 0],[1 1]*0,'k-'); hold on
        set(gca,'color',[240 240 240]/255,'YAxisLocation','right');
        set(gca,'xlim',[plt_range 0],'ylim',[-0.1 1.1])
        set(gca,'xtick',[-3000:500:0],'box','off')
        set(gca,'ytick',[0:0.5:1],'yticklabel',{'0' '' '1'})
    end

    try
        while get(handles.togglebutton_stream,'Value') == 1
            t2=clock;
            metadata=getappdata(0,'metadata');  % get updated metadata within this loop, otherwise we'll be using stale data

            % --- eye trace ---
            wholeframe=getsnapshot(vidobj_eye_2);
            roi=wholeframe.*uint8(metadata.cam_eye_2.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
            eyelidpos2=sum(roi(:)>=256*metadata.cam_eye_2.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units

            % --- eye trace buffer ---
            etime0=round(1000*etime(clock,t0));
            eyedata2(1:end-1,:)=eyedata2(2:end,:);
            eyedata2(end,1)=etime0;
            eyedata2(end,2)=(eyelidpos2-metadata.cam_eye_2.calib_offset)/metadata.cam_eye_2.calib_scale; % eyelid pos

            set(pl1,'XData',eyedata2(:,1)-etime0,'YData',eyedata2(:,2))

%             % --- Trigger ----
%             if get(handles.toggle_continuous,'Value') == 1
% 
%                 stopTrial = str2double(get(handles.edit_StopAfterTrial,'String'));
%                 if stopTrial > 0 && metadata.cam.trialnum > stopTrial
%                     set(handles.toggle_continuous,'Value',0);
%                     set(handles.toggle_continuous,'String','Start Continuous');
%                 end
% 
%                 etime1=round(1000*etime(clock,t1))/1000;
%                 if etime1>metadata.stim.c.ITI,
%                     eyeok=checkeye(handles,eyedata);
%                     if eyeok
%                         TriggerArduino(handles)
%                         t1=clock;
%                     end
%                 end
%             end
        end
    catch
        if isvalid(handles.togglebutton_stream) %if we are quitting, don't try to restart the stream
            try % If it's a dropped frame, see if we can recover
                handles.pwin2=image(zeros(600,800),'Parent',handles.cameraAx_2);
                pause(0.5)
                closepreview(vidobj_eye_2);
                pause(0.2)
                preview(vidobj_eye_2,handles.pwin2);
                %     guidata(handles.cameraAx,handles)
                stream2(handles)
                disp('Caught camera error')
            catch
                disp('Aborted eye streaming.')
                set(handles.togglebutton_stream,'Value',0);
                %     set(handles.pushbutton_StartStopPreview,'String','Start Preview')
                %     closepreview(vidobj_eye_2);
                return
            end
        end
    end    
