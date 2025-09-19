function varargout = MainWindow(varargin)
    % MAINWINDOW M-file for MainWindow.fig
    %      MAINWINDOW, by itself, creates a new MAINWINDOW or raises the existing
    %      singleton*.
    %
    %      H = MAINWINDOW returns the handle to a new MAINWINDOW or the handle to
    %      the existing singleton*.
    %
    %      MAINWINDOW('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in MAINWINDOW.M with the given input arguments.
    %
    %      MAINWINDOW('Property','Value',...) creates a new MAINWINDOW or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before MainWindow_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to MainWindow_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help MainWindow

    % Last Modified by GUIDE v2.5 09-Jan-2023 11:04:16

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @MainWindow_OpeningFcn, ...
                       'gui_OutputFcn',  @MainWindow_OutputFcn, ...
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


% --- Executes just before MainWindow is made visible.
function MainWindow_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % varargin   command line arguments to MainWindow (see VARARGIN)

    % Choose default command line output for MainWindow
    handles.output = hObject;
    % Update handles structure
    guidata(hObject, handles);
    
    %Initialise the param dictionary indexes.
    set_param_dictionary_indexes(handles);
    
    configure; % Configuration script    

    % UIWAIT makes MainWindow wait for user response (see UIRESUME)
    % uiwait(handles.CamFig);
    src=getappdata(0,'src');
    metadata=getappdata(0,'metadata');
    metadata.date=date;
    metadata.TDTblockname='TempBlk';
    metadata.ts=[datenum(clock) 0]; % two element vector containing datenum at beginning of session and offset of current trial (in seconds) from beginning
    metadata.folder=pwd; % For now use current folder as base; will want to change this later

    metadata.cam.fps=src.AcquisitionFrameRate; %in frames per second
    metadata.cam.thresh=0.125;
    metadata.cam.trialnum=1;
    metadata.eye.trialnum1=1;  %  for conditioning
    metadata.eye.trialnum2=1;

    typestring=get(handles.popupmenu_stimtype,'String');
    metadata.stim.type=typestring{get(handles.popupmenu_stimtype,'Value')};
    
    % Set ITI using base time plus optional random range
    % We have to initialize here because "stream" function uses metadata.stim.c.ITI
    trialvars=readTrialTable(metadata.eye.trialnum1);
    base_ITI = trialvars(get_trial_index('ITI_s'));
    rand_ITI = trialvars(get_trial_index('random_ITI_s'));
    metadata.stim.c.ITI = base_ITI + rand(1,1) * rand_ITI;

    metadata.cam.time(1)=trialvars(get_trial_index('pre_time_ms'));
    metadata.cam.time(3)=trialvars(get_trial_index('post_time_ms'));
    metadata.cam.cal=0;
    metadata.cam.calib_offset=0;
    metadata.cam.calib_scale=1;

    trials.stimnum=0;
    trials.savematadata=0;

    setappdata(0,'metadata',metadata);
    setappdata(0,'trials',trials);

    %%%%%%%%%%%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Open parameter dialog
    %h=ParamsWindow;
    %waitfor(h);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % pushbutton_StartStopPreview_Callback(handles.pushbutton_StartStopPreview, [], handles)

    % --- init table ----
    if isappdata(0,'paramtable')
        paramtable=getappdata(0,'paramtable');
        set(handles.uitable_params,'Data',paramtable.data);
    end
    
    %We will use this variable to check if the default parameters have been
    %modified befor the start of the experiment.
    setappdata(0,'defaultparametersmodified', 0);
    
    %modify
    setappdata(0,'eyeThreshold',str2double(get(handles.edit_eyethr,'String')));
    
    %Set fast saving option
    fast_saving_option=get(handles.fast_saving_box,'Value');
    setappdata(0,'fast_saving_option',fast_saving_option);

% --- Executes on button press in pushbutton_StartStopPreview.
function pushbutton_StartStopPreview_Callback(hObject, eventdata, handles)
    vidobj=getappdata(0,'vidobj');
    metadata=getappdata(0,'metadata');
    
    src=getappdata(0,'src');

    if ~isfield(metadata.cam,'fullsize')
        metadata.cam.fullsize = [0 0 800 600];
    end
    metadata.cam.vidobj_ROIposition=vidobj.ROIposition;

    % Start/Stop Camera
    if strcmp(get(handles.pushbutton_StartStopPreview,'String'),'Start Preview')
        % Camera is off. Change button string and start camera.
        set(handles.pushbutton_StartStopPreview,'String','Stop Preview')
        % Send camera preview to GUI
        imx=metadata.cam.vidobj_ROIposition(1)+[1:metadata.cam.vidobj_ROIposition(3)];
        imy=metadata.cam.vidobj_ROIposition(2)+[1:metadata.cam.vidobj_ROIposition(4)];
        handles.pwin=image(imx,imy,zeros(metadata.cam.vidobj_ROIposition([4 3])), 'Parent',handles.cameraAx);

        preview(vidobj,handles.pwin);
        set(handles.cameraAx,'XLim', 0.5+metadata.cam.fullsize([1 3])),
        set(handles.cameraAx,'YLim', 0.5+metadata.cam.fullsize([2 4])),
        hp=findobj(handles.cameraAx,'Tag','roipatch');  delete(hp)
        if isfield(handles,'XY')
            handles.roipatch=patch(handles.XY(:,1),handles.XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
        end

        ht=findobj(handles.cameraAx,'Tag','trialtimecounter');
    %     delete(ht)

        axes(handles.cameraAx)
        handles.trialtimecounter = text(790,590,' ','Color','c','HorizontalAlignment','Right',...
            'VerticalAlignment', 'Bottom', 'Visible', 'Off', 'Tag', 'trialtimecounter',...
            'FontSize',18);
        handles.trialthresholdcounter = text(790,10,' ','Color','r','HorizontalAlignment','Right',...
            'VerticalAlignment', 'Top', 'Visible', 'Off', 'Tag', 'trialthresholdcounter',...
            'FontSize',18);
    else
        % Camera is on. Stop camera and change button string.
        stopPreview(handles);
    end

    setappdata(0,'metadata',metadata);
    guidata(hObject,handles)


function stopPreview(handles)
    % Pulled this out as a function so it can be called from elsewhere
    vidobj=getappdata(0,'vidobj');

    set(handles.pushbutton_StartStopPreview,'String','Start Preview')
    closepreview(vidobj);

    % vidobj=getappdata(0,'vidobj');
    % metadata=getappdata(0,'metadata');
    %
    % if isfield(metadata.cam,'fullsize')
    %     metadata.cam.fullsize = vidobj.ROIposition;
    % end
    %
    % if strcmp(get(handles.pushbutton_StartStopPreview,'String'),'Start Preview')
    %     % Camera is off. Change button string and start camera.
    %     set(handles.pushbutton_StartStopPreview,'String','Stop Preview')
    %     handles.pwin=image(zeros(480,640),'Parent',handles.cameraAx);
    %     preview(vidobj,handles.pwin);
    % else
    %     % Camera is on. Stop camera and change button string.
    %     set(handles.pushbutton_StartStopPreview,'String','Start Preview')
    %     closepreview(vidobj);
    % end
    % setappdata(0,'metadata',metadata);
    % guidata(hObject,handles)


function pushbutton_quit_Callback(hObject, eventdata, handles)
    vidobj=getappdata(0,'vidobj');
    ghandles=getappdata(0,'ghandles');
    metadata=getappdata(0,'metadata');
    arduino=getappdata(0,'arduino');

    button=questdlg('Are you sure you want to quit?','Quit?');
    if ~strcmpi(button,'Yes')
        return
    end

    set(handles.togglebutton_stream,'Value',0);

    try
        fclose(arduino);
        delete(arduino);
        delete(vidobj);
        rmappdata(0,'src');
        rmappdata(0,'vidobj');
    catch err
        warning(err.identifier,'Problem cleaning up objects. You may need to do it manually.')
    end
    delete(handles.CamFig)

% --- Outputs from this function are returned to the command line.
function varargout = MainWindow_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % Get default command line output from handles structure
    varargout{1} = handles.output;


function CamFig_KeyPressFcn(hObject, eventdata, handles)
    %	Key: name of the key that was pressed, in lower case
    %	Character: character interpretation of the key(s) that was pressed
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
    switch eventdata.Character
        case '`'
            pushbutton_stim_Callback(hObject, eventdata, handles);
        otherwise
            return
    end


% function pushbutton_setROI_Callback(hObject, eventdata, handles)
% 
%     vidobj=getappdata(0,'vidobj');   
%     metadata=getappdata(0,'metadata');
% 
%     if isfield(metadata.cam,'winpos')
%         winpos=metadata.cam.winpos;
%         winpos(1:2)=winpos(1:2)+metadata.cam.vidobj_ROIposition(1:2);
%     else
%         winpos=[0 0 800 600];
%     end
% 
%     % Place rectangle on vidobj
%     % h=imrect(handles.cameraAx,winpos);
%     h=imellipse(handles.cameraAx,winpos);
%     
% 
%     % fcn = makeConstrainToRectFcn('imrect',get(handles.cameraAx,'XLim'),get(handles.cameraAx,'YLim'));
%     fcn = makeConstrainToRectFcn('imellipse',get(handles.cameraAx,'XLim'),get(handles.cameraAx,'YLim'));
%     setPositionConstraintFcn(h,fcn);
% 
%     % metadata.cam.winpos=round(wait(h));
%     XY=round(wait(h));  % only use for imellipse
%     metadata.cam.winpos=round(getPosition(h));
%     metadata.cam.winpos(1:2)=metadata.cam.winpos(1:2)-metadata.cam.vidobj_ROIposition(1:2);
%     metadata.cam.mask=createMask(h);
% 
%     wholeframe=getsnapshot(vidobj);
%     binframe=im2bw(wholeframe,metadata.cam.thresh);
%     eyeframe=binframe.*metadata.cam.mask;
%     metadata.cam.pixelpeak=sum(sum(eyeframe));
% 
%     hp=findobj(handles.cameraAx,'Tag','roipatch');
%     delete(hp)
%     % handles.roipatch=patch([xmin,xmin+width,xmin+width,xmin],[ymin,ymin,ymin+height,ymin+height],'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
%     % XY=getVertices(h);
%     delete(h);
%     handles.roipatch=patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
%     handles.XY=XY;
% 
%     setappdata(0,'metadata',metadata);
%     guidata(hObject,handles)
% 
%     % vidobj=getappdata(0,'vidobj');  metadata=getappdata(0,'metadata');
%     % if isfield(metadata.cam,'winpos')
%     %     winpos=metadata.cam.winpos;
%     % else
%     %     winpos=[0 0 640 480];
%     % end
%     % h=imellipse(handles.cameraAx,winpos);
%     % fcn = makeConstrainToRectFcn('imellipse',get(handles.cameraAx,'XLim'),get(handles.cameraAx,'YLim'));
%     % setPositionConstraintFcn(h,fcn);
%     %
%     % % metadata.cam.winpos=round(wait(h));
%     % XY=round(wait(h));  % only use for imellipse
%     % metadata.cam.winpos=getPosition(h);
%     % metadata.cam.mask=createMask(h);
%     %
%     % wholeframe=getsnapshot(vidobj);
%     % binframe=im2bw(wholeframe,metadata.cam.thresh);
%     % eyeframe=binframe.*metadata.cam.mask;
%     % metadata.cam.pixelpeak=sum(sum(eyeframe));
%     %
%     % hp=findobj(handles.cameraAx,'Tag','roipatch');
%     % delete(hp)
%     %
%     % delete(h);
%     % handles.roipatch=patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','roipatch');
%     %
%     % setappdata(0,'metadata',metadata);
%     % guidata(hObject,handles)


function pushbutton_setROI_Callback(hObject, eventdata, handles)

    vidobj=getappdata(0,'vidobj');   
    metadata=getappdata(0,'metadata');

    if isfield(metadata.cam,'winpos')
        winpos=metadata.cam.winpos;
        winpos(1:2)=winpos(1:2)+metadata.cam.vidobj_ROIposition(1:2);
    else
        winpos=[0 0 800 600];
    end

    % Place elipse on vidobj
    h = drawellipse(handles.cameraAx);
    
    %wait until the user fix the ellipse position
    XY=round(customWait(h));

    x_pos = min(XY(:,1));
    x_size = max(XY(:,1)) - x_pos;
    y_pos = min(XY(:,2));
    y_size = max(XY(:,2)) - y_pos;
    metadata.cam.winpos = [x_pos, y_pos, x_size, y_size] ;
    metadata.cam.winpos(1:2)=metadata.cam.winpos(1:2)-metadata.cam.vidobj_ROIposition(1:2);
    metadata.cam.mask=createMask(h);

    wholeframe=getsnapshot(vidobj);
    binframe=im2bw(wholeframe,metadata.cam.thresh);
    eyeframe=binframe.*metadata.cam.mask;
    metadata.cam.pixelpeak=sum(sum(eyeframe));

    hp=findobj(handles.cameraAx,'Tag','roipatch');
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
    

%Calibration Push Button
function pushbutton_CalbEye_Callback(hObject, eventdata, handles)
    metadata=getappdata(0,'metadata');
    metadata.cam.cal=1;
    setappdata(0,'metadata',metadata);

    refreshPermsA(handles);
    sendto_arduino();

    metadata=getappdata(0,'metadata');
    vidobj=getappdata(0,'vidobj');

    vidobj.FramesPerTrigger = 200;
    vidobj.TriggerRepeat = 0;
    vidobj.StopFcn=@CalbEye;   % this will be executed after timer stop
    flushdata(vidobj);         % Remove any data from buffer before triggering

    % Set camera to hardware trigger mode
    src=getappdata(0,'src');



    src.TriggerSource = 'Line0';
    start(vidobj)

    metadata.cam.cal=0;
    metadata.ts(2)=etime(clock,datevec(metadata.ts(1)));
   
    % --- trigger via arduino --
    arduino=getappdata(0,'arduino');
    fwrite(arduino,1,'int8');
    setappdata(0,'metadata',metadata);
    
    %Calibrate the second camera for the second eye.
    if metadata.multicams.N_eye_cams == 2
        %white 15 second to finish the first eye calibration
        pause(15.0);
        
        metadata.cam_eye_2.cal=1;
        setappdata(0,'metadata',metadata);

        refreshPermsA(handles);
        sendto_arduino();

        metadata=getappdata(0,'metadata');
        vidobj_eye_2=getappdata(0,'vidobj_eye_2');

        vidobj_eye_2.FramesPerTrigger = 200;
        vidobj_eye_2.TriggerRepeat = 0;
        vidobj_eye_2.StopFcn=@CalbEye_2;   % this will be executed after timer stop
        flushdata(vidobj_eye_2);         % Remove any data from buffer before triggering

        % Set camera to hardware trigger mode
        src_eye_2=getappdata(0,'src_eye_2');
        src_eye_2.TriggerSource = 'Line0';
        start(vidobj_eye_2)

        metadata.cam_eye_2.cal=0;
        metadata.ts(2)=etime(clock,datevec(metadata.ts(1)));  %%REVISAR ts
        % --- trigger via arduino --
        arduino=getappdata(0,'arduino');
        fwrite(arduino,1,'int8');

        setappdata(0,'metadata',metadata);
    
    end
    


%Instant replay Push Button
function pushbutton_instantreplay_Callback(hObject, eventdata, handles)
    metadata=getappdata(0,'metadata');
    if metadata.multicams.N_eye_cams == 1
        instantReplay(getappdata(0,'lastdata'),getappdata(0,'lastmetadata'));
    else
        %instantReplay(getappdata(0,'lastdata_eye_2'),getappdata(0,'lastmetadata_eye_2'));
        instantReplayBothEyes(getappdata(0,'lastdata'),getappdata(0,'lastmetadata'),getappdata(0,'lastdata_eye_2'),getappdata(0,'lastmetadata_eye_2'));
    end
    
    
%Toggle Continuous Push Button
function toggle_continuous_Callback(hObject, eventdata, handles)
    %we check if the default parameters have been modified.
    defaultparametersmodified=getappdata(0,'defaultparametersmodified');
    if defaultparametersmodified==0
        %we ask the user if want to run the simulation with the default
        %parameters
        button=questdlg('You have not modified the default parameters. Are you sure you want to run the experiment with the default parameters?');
        %The user abort the execution
        if ~strcmpi(button,'Yes')
            return
        %If the user doesn't abort the execution, we diseble the pop up windows with the warning. 
        else
            setappdata(0,'defaultparametersmodified',1);    
        end
    end



    if get(hObject,'Value'),
        set(hObject,'String','Pause Continuous')
        set(handles.trialtimecounter,'Visible','On')
    else
        set(hObject,'String','Start Continuous')
        set(handles.trialtimecounter,'Visible','Off')
    end

%Trigger a Single Trial
function pushbutton_stim_Callback(hObject, eventdata, handles)
    %we check if the default parameters have been modified.
    defaultparametersmodified=getappdata(0,'defaultparametersmodified');
    if defaultparametersmodified==0
        %we ask the user if want to run the simulation with the default
        %parameters
        button=questdlg('You have not modified the default parameters. Are you sure you want to run the experiment with the default parameters?');
        %The user abort the execution
        if ~strcmpi(button,'Yes')
            return
        %If the user doesn't abort the execution, we diseble the pop up windows with the warning. 
        else
            setappdata(0,'defaultparametersmodified',1);    
        end
    end
    
    setappdata(0,'eyeThreshold',str2double(get(handles.edit_eyethr,'String')));
    setappdata(0,'abort_trial_enabled',1);
    
    %start a new trial.
    TriggerArduino(handles)

%trial type menu
function popupmenu_stimtype_Callback(hObject, eventdata, handles)
    % --- updating metadata ---
    metadata=getappdata(0,'metadata');
    val=get(hObject,'Value');
    str=get(hObject,'String');
    metadata.stim.type=str{val};
    setappdata(0,'metadata',metadata);

    % ------ highlight for uipanel -----
    set(handles.uipanel_puff,'BackgroundColor',[240 240 240]/255);
    set(handles.uipanel_conditioning,'BackgroundColor',[240 240 240]/255);
    switch lower(metadata.stim.type)
        case 'puff'
            set(handles.uipanel_puff,'BackgroundColor',[225 237 248]/255); % light blue
        case 'conditioning'
            set(handles.uipanel_conditioning,'BackgroundColor',[225 237 248]/255); % light blue
    end


%Toggle Streaming push button
function togglebutton_stream_Callback(hObject, eventdata, handles)
    if get(hObject,'Value'),
        set(hObject,'String','Stop Streaming')
%        stream(handles)
        startStreaming(handles)
    else
        set(hObject,'String','Start Streaming')
        stopStreaming(handles)
    end

function stopStreaming(handles)

    set(handles.togglebutton_stream,'String','Start Streaming')
    setappdata(handles.pwin,'UpdatePreviewWindowFcn',[]);


function startStreaming(handles)

    set(handles.togglebutton_stream,'String','Stop Streaming')
    setappdata(handles.pwin,'UpdatePreviewWindowFcn',@newFrameCallback);


function pushbutton_params_Callback(hObject, eventdata, handles)
    ParamsWindow


function pushbutton_oneana_Callback(hObject, eventdata, handles)
    ghandles=getappdata(0,'ghandles');
%    ghandles.onetrialanagui=OneTrialAnaWindow;
    ghandles.onetrialanagui=OneTrialAnaWindowBothEyes;
    setappdata(0,'ghandles',ghandles);

    set(ghandles.onetrialanagui,'units','pixels')
    set(ghandles.onetrialanagui,'position',[ghandles.pos_oneanawin ghandles.size_oneanawin])


function uipanel_TDTMode_SelectionChangeFcn(hObject, eventdata, handles)

    metadata=getappdata(0,'metadata');

    switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
        case 'togglebutton_NewSession'
            dlgans = inputdlg({'Enter session name'},'Create', [1 35],{'S01'});
            if isempty(dlgans)
                ok=0;
            elseif isempty(dlgans{1})
                ok=0;
            else
                ok=1;  session=dlgans{1};
    %             set(handles.checkbox_save_metadata,'Value',0);
            end
        case 'togglebutton_StopSession'
            button=questdlg('Are you sure you want to stop this session?','Stop session?','Yes and compress videos','Yes and DON''T compress videos','No','Yes and compress videos');

            switch button

                case 'Yes and compress videos'
                    session='s00';     ok=1;
                    stopStreaming(handles);
                    stopPreview(handles);

                    makeCompressedVideos(metadata.folder,1);

                case 'Yes and DON''T compress videos'
                    session='s00';     ok=1;
                    stopStreaming(handles);
                    stopPreview(handles);

                otherwise
                    ok=0;

            end
        otherwise
            warndlg('There is something wrong with the mode selection callback','Mode Select Problem!')
            return
    end

    if ok
        set(eventdata.NewValue,'Value',1);
        set(eventdata.OldValue,'Value',0);
        set(handles.uipanel_TDTMode,'SelectedObject',eventdata.NewValue);
    else
        set(eventdata.NewValue,'Value',0);
        set(eventdata.OldValue,'Value',1);
        set(handles.uipanel_TDTMode,'SelectedObject',eventdata.OldValue);
        return
    end
    ResetCamTrials()
    set(handles.text_SessionName,'String',session);
    metadata=getappdata(0,'metadata');
    metadata.TDTblockname=sprintf('%s_%s_%s', metadata.mouse, datestr(now,'yymmdd'),session);
    setappdata(0,'metadata',metadata);


function pushbutton_opentable_Callback(hObject, eventdata, handles)
    paramtable.data=get(handles.uitable_params,'Data');
    paramtable.randomize=get(handles.checkbox_random,'Value');
    paramtable.names=get(handles.uitable_params,'ColumnName');
    % paramtable.tonefreq=str2num(get(handles.edit_tone,'String'));
    % if length(paramtable.tonefreq)<2, paramtable.tonefreq(2)=0; end
    setappdata(0,'paramtable',paramtable);

    ghandles=getappdata(0,'ghandles');
    trialtablegui=TrialTable;
    movegui(trialtablegui,[ghandles.pos_mainwin(1)+ghandles.size_mainwin(1)+20 ghandles.pos_mainwin(2)])
    
%     %Update the number of trial to be executed in the GUI
%     N_trials = size(trialtable, 1);
%     str_N_trials=sprintf('%d', N_trials);
%     set(handles.edit_StopAfterTrial,'String',str_N_trials);


function update_trial_table(hObject, eventdata, handles)
    paramtable.data=get(handles.uitable_params,'Data');
    paramtable.randomize=get(handles.checkbox_random,'Value');
    paramtable.names=get(handles.uitable_params,'ColumnName');
    % paramtable.tonefreq=str2num(get(handles.edit_tone,'String'));
    % if length(paramtable.tonefreq)<2, paramtable.tonefreq(2)=0; end
    setappdata(0,'paramtable',paramtable);
    
    trialtable=makeTrialTable(paramtable.data,paramtable.randomize);
    setappdata(0,'trialtable',trialtable);
    
    %Update the number of trial to be executed in the GUI
    N_trials = size(trialtable, 1);
    str_N_trials=sprintf('%d', N_trials);
    set(handles.edit_StopAfterTrial,'String',str_N_trials);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% user defined functions %%%%%%%%%%%%%%%%%

function refreshPermsA(handles)
    metadata=getappdata(0,'metadata');
    trials=getappdata(0,'trials');

    trials.savematadata=1;
    val=get(handles.popupmenu_stimtype,'Value');
    str=get(handles.popupmenu_stimtype,'String');
    metadata.stim.type=str{val};
    % for Calibrate first eye
    if metadata.cam.cal
        metadata.stim.type='puff';
    end 
    % for Calibrate second eye
    if metadata.multicams.N_eye_cams == 2 && metadata.cam_eye_2.cal
        metadata.stim.type='puff2';
    end 

    metadata.stim.c.csdelay=0;
    metadata.stim.c.csdur=0;
    metadata.stim.c.csnum=0;
    metadata.stim.c.cs2delay=0;
    metadata.stim.c.cs2dur=0;
    metadata.stim.c.cs2num=0;
    metadata.stim.c.isi=0;
    metadata.stim.c.usdur=0;
    metadata.stim.c.usnum=0;
    metadata.stim.c.cstone=[0 0];

    metadata.stim.c.cs_period = 0;
    metadata.stim.c.cs_repeats = 0;
    metadata.stim.c.cs_addreps = 0;
    metadata.stim.c.cs_intensity = 255; %%%ALvaro 05/10/19

    metadata.stim.l.ramp.off.time = 0; %%%Alvaro 10/19/18
    metadata.stim.l.delay=0;
    metadata.stim.l.dur=0;
    metadata.stim.l.amp=0;
    metadata.stim.p.puffdur=str2double(get(handles.edit_puffdur,'String'));
    
    metadata.stim.motor.current = 0;
    metadata.stim.motor.delay = 0;
    metadata.stim.motor.dur = 0;
    metadata.stim.motor.energized_trial = 0;
    metadata.stim.motor.speed_trial = 0;
    metadata.stim.motor.acceleration_trial = 0;
    metadata.stim.motor.energized_intertrial = 0;
    metadata.stim.motor.speed_intertrial = 0;
    metadata.stim.motor.acceleration_intertrial = 0;
    
    metadata.note = getappdata(0,'note_value');
    
    switch lower(metadata.stim.type)
        case 'none'
            metadata.stim.totaltime=0;
        case 'puff'
            metadata.stim.totaltime=metadata.stim.p.puffdur;
            metadata.cam.time(1)=200;
            metadata.cam.time(2)=metadata.stim.totaltime;
            metadata.cam.time(3)=800-metadata.stim.totaltime;
        case 'puff2'
            metadata.stim.totaltime=metadata.stim.p.puffdur;
            metadata.cam_eye_2.time(1)=200;
            metadata.cam_eye_2.time(2)=metadata.stim.totaltime;
            metadata.cam_eye_2.time(3)=800-metadata.stim.totaltime;    
        case 'conditioning'
            trialvars=readTrialTable(metadata.eye.trialnum1);
            %Set Camera Time
            % Set ITI using base time plus optional random range
            base_ITI = trialvars(get_trial_index('ITI_s'));
            rand_ITI = trialvars(get_trial_index('random_ITI_s'));
            metadata.stim.c.ITI = base_ITI + rand(1,1) * rand_ITI;
            metadata.stim.l.ramp.off.time=trialvars(get_trial_index('ramp_off_time_ms')); %%%Alvaro 10/19/18
            metadata.stim.c.cs_intensity=trialvars(get_trial_index('CS_intensity')); %%%Alvaro 05/10/19
            metadata.stim.c.tonecs_intensity=trialvars(get_trial_index('tone_intensity')); %%%Olivia 6/4/2020
            metadata.stim.c.csdelay=trialvars(get_trial_index('CS_delay_ms'));
            metadata.stim.c.csdur=trialvars(get_trial_index('CS_dur_ms'));
            metadata.stim.c.csnum=trialvars(get_trial_index('CS_ch'));
            metadata.stim.c.cs2delay=trialvars(get_trial_index('CS2_delay_ms'));
            metadata.stim.c.cs2dur=trialvars(get_trial_index('CS2_dur_ms'));
            metadata.stim.c.cs2num=trialvars(get_trial_index('CS2_ch'));
            metadata.stim.c.isi=trialvars(get_trial_index('ISI_ms'));
            metadata.stim.c.usdur=trialvars(get_trial_index('US_dur_ms'));
            metadata.stim.c.usnum=trialvars(get_trial_index('US_ch'));
            metadata.stim.c.cstone=str2num(get(handles.edit_tone,'String'))*1000;
            if length(metadata.stim.c.cstone)<2, metadata.stim.c.cstone(2)=0; end
            metadata.stim.totaltime=metadata.stim.c.isi+metadata.stim.c.usdur;
            metadata.cam.time(1)=trialvars(get_trial_index('pre_time_ms'));
            metadata.cam.time(2)=metadata.stim.totaltime;
            metadata.cam.time(3)=trialvars(get_trial_index('post_time_ms'))-metadata.stim.totaltime;
            if metadata.multicams.N_eye_cams == 2
                metadata.cam_eye_2.time(1)=trialvars(get_trial_index('pre_time_ms'));
                metadata.cam_eye_2.time(2)=metadata.stim.totaltime;
                metadata.cam_eye_2.time(3)=trialvars(get_trial_index('post_time_ms'))-metadata.stim.totaltime;
                %%%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%REVISAR
                metadata.stim.c.isi_eye_2=trialvars(get_trial_index('ISI2_ms'));
                metadata.stim.c.usdur_eye_2=trialvars(get_trial_index('US2_dur_ms'));
                metadata.stim.c.usnum_eye_2=trialvars(get_trial_index('US2_ch'));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            metadata.stim.l.delay = trialvars(get_trial_index('laser_delay_ms'));
            metadata.stim.l.dur = trialvars(get_trial_index('laser_dur_ms'));
            metadata.stim.l.amp = trialvars(get_trial_index('laser_power'));
            metadata.stim.c.cs_period = trialvars(get_trial_index('CS_period_ms'));
            metadata.stim.c.cs_repeats = trialvars(get_trial_index('CS_repeats'));
            metadata.stim.c.cs_addreps = randi([0,trialvars(get_trial_index('CS_add_reps'))],1,1);%generates a random integer to be added to cs_repeats, also affects ISI
            
            
            
            %%Variables relevant for repeating stimuli only
            stimnum=metadata.stim.c.cs_repeats+metadata.stim.c.cs_addreps;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%Greg%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
            if metadata.stim.l.delay==6 %laser presentation with every stimulus in sequence
                metadata.stim.l.laserperiod = metadata.stim.c.cs_period;
                metadata.stim.l.lasernumpulses=metadata.stim.c.cs_repeats+metadata.stim.c.cs_addreps;
            elseif metadata.stim.l.delay==7 %laser presentation with every third stimulus in sequence
                metadata.stim.l.laserperiod = metadata.stim.c.cs_period*3;
                metadata.stim.l.lasernumpulses=ceil(stimnum/3);
            elseif metadata.stim.l.delay==8 %laser presentation with every third stimulus in sequence
                metadata.stim.l.laserperiod = metadata.stim.c.cs_period;
                metadata.stim.l.lasernumpulses=3;
            end
            %%%%%%%%%%%%%%%%%%%%% shogo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if metadata.stim.l.delay==9 %% sycn with US (code, not in ms)
                metadata.stim.l.laserperiod = 3; % (ms, inter-pulse interval) e.g. 10 ms <- 100 Hz,  5 ms <- 200 Hz,  3 ms <- 333 Hz,
                metadata.stim.l.lasernumpulses=floor(30/metadata.stim.l.laserperiod)+1; % (in 30 ms)
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%%%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            metadata.protocol.omit_US=trialvars(get_trial_index('omit_US'));
            metadata.protocol.omit_CR_threshold=trialvars(get_trial_index('omit_CR_threshold'));
            metadata.protocol.omit_US2=trialvars(get_trial_index('omit_US2'));
            metadata.protocol.omit_CR2_threshold=trialvars(get_trial_index('omit_CR2_threshold'));
            metadata.protocol.omit_US_or_US2=trialvars(get_trial_index('omit_US_or_US2'));
            
            %Motor configuration
            metadata.stim.motor.current = trialvars(get_trial_index('motor_current_mA'));
            metadata.stim.motor.delay = trialvars(get_trial_index('motor_delay_ms'));
            metadata.stim.motor.dur = trialvars(get_trial_index('motor_dur_ms'));
            metadata.stim.motor.energized_trial = trialvars(get_trial_index('motor_energized_trial'));
            metadata.stim.motor.speed_trial = trialvars(get_trial_index('motor_speed_trial'));
            metadata.stim.motor.acceleration_trial = trialvars(get_trial_index('motor_acceleration_trial'));
            metadata.stim.motor.energized_intertrial = trialvars(get_trial_index('motor_energized_intertrial'));
            metadata.stim.motor.speed_intertrial = trialvars(get_trial_index('motor_speed_intertrial'));
            metadata.stim.motor.acceleration_intertrial = trialvars(get_trial_index('motor_acceleration_intertrial'));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
        otherwise
            metadata.stim.totaltime=0;
            warning('Unknown stimulation mode set.');
    end


    metadata.now=now;

    setappdata(0,'metadata',metadata);
    setappdata(0,'trials',trials);


function sendto_arduino()
    %datatoarduino(1):  start trial
    %datatoarduino(2):  ready to receive encoder information
    
    %datatoarduino(3):  pre_time_ms 
    %datatoarduino(4):  CS channel
    %datatoarduino(5):  CS duration
    %datatoarduino(6):  US/puff duration
    %datatoarduino(7):  ISI?????????????
    %datatoarduino(8):  ????????????????
    %datatoarduino(9):  post_time_ms
    %datatoarduino(10): US channel
    %datatoarduino(11): ??????????
    %datatoarduino(12): laser duration
    %datatoarduino(13): laser amplitude
    %datatoarduino(14): CS_tone_intensity
    %datatoarduino(15): laser period
    %datatoarduino(16): laser num pulse
    %datatoarduino(17): 
    %datatoarduino(18): 
    %datatoarduino(19): 
    %datatoarduino(20): CS period
    %datatoarduino(21): ???????????
    %datatoarduino(22): ramp off time
    %datatoarduino(23): 
    %datatoarduino(24): 
    %datatoarduino(25): 
    %datatoarduino(26): 
    %datatoarduino(27): 
    %datatoarduino(28): 
    %datatoarduino(29): 
    %datatoarduino(30): ISI2
    %datatoarduino(31): US2_duration
    %datatoarduino(32): US2_channel
    %datatoarduino(33): CS_delay
    %datatoarduino(34): CS2_delay
    %datatoarduino(35): CS2_dur
    %datatoarduino(36): CS2_ch
    %datatoarduino(37): motor positive delay
    %datatoarduino(38): motor negative delay (represented with a positive
    %value bacause we are not able to send negative values between matlab and arduino)
    %datatoarduino(39): motor.dur
    %datatoarduino(40): motor.energized_trial
    %datatoarduino(41): motor.speed_trial
    %datatoarduino(42): motor.acceleration_trial
    %datatoarduino(43): motor.energized_intertrial
    %datatoarduino(44): motor.speed_intertrial
    %datatoarduino(45): motor.acceleration_intertrial
    %datatoarduino(46): motor.current
    %datatoarduino(47):
    %datatoarduino(48): 
    %datatoarduino(49): CS intensity
    %triggerArduino
    %datatoarduino(50): abort trial
    %datatoarduino(51): omit US
    %datatoarduino(52): omit US2
    
   

    metadata=getappdata(0,'metadata');
    datatoarduino=zeros(1,55); %REVISAR

    datatoarduino(9)=sum(metadata.cam.time(2:3));
    if strcmpi(metadata.stim.type, 'puff')
        datatoarduino(6)=metadata.stim.p.puffdur;
        datatoarduino(10)=3; %metadata.stim.c.usnum;  %3;% This is the puff channel  %%REVISAR
        datatoarduino(3)=metadata.cam.time(1); %%Alvaro 10/24/18 restablished as a copy after moving to conditioning in a previous version
    elseif strcmpi(metadata.stim.type, 'puff2')
        datatoarduino(6)=metadata.stim.p.puffdur;
        datatoarduino(10)= 2; %metadata.stim.c.usnum2;  %FRANCISCO: REVISAR
        datatoarduino(3)=metadata.cam_eye_2.time(1); %%Alvaro 10/24/18 restablished as a copy after moving to conditioning in a previous version
    elseif  strcmpi(metadata.stim.type, 'conditioning')
        datatoarduino(14) = metadata.stim.c.tonecs_intensity; % Olivia added 6/4/2020 for testing addition of tone to code

        datatoarduino(49)= metadata.stim.c.cs_intensity; %%%Alvaro 05/10/19
        datatoarduino(22)=metadata.stim.l.ramp.off.time;  %%%Alvaro 10/19/18
        datatoarduino(3)=metadata.cam.time(1);
        datatoarduino(9)=sum(metadata.cam.time(2:3));
        datatoarduino(4)=metadata.stim.c.csnum;
        datatoarduino(5)=metadata.stim.c.csdur;
        datatoarduino(33)=metadata.stim.c.csdelay;
        datatoarduino(34)=metadata.stim.c.cs2delay;
        datatoarduino(35)=metadata.stim.c.cs2dur;
        datatoarduino(36)=metadata.stim.c.cs2num;
        
        
        datatoarduino(6)=metadata.stim.c.usdur;
        datatoarduino(7)=(metadata.stim.c.isi+metadata.stim.c.cs_addreps*metadata.stim.c.cs_period); %sets the appropriate ISI for the eventual number of CS repetitions
        if ismember(metadata.stim.c.csnum,[5 6]),
            datatoarduino(8)=metadata.stim.c.cstone(metadata.stim.c.csnum-4);
        end
        if ismember(metadata.stim.c.cs2num,[5 6]),
            datatoarduino(8)=metadata.stim.c.cstone(metadata.stim.c.cs2num-4);
        end
        if ismember(metadata.stim.c.usnum,[5 6]),
            datatoarduino(8)=metadata.stim.c.cstone(metadata.stim.c.usnum-4);
        end
        if metadata.multicams.N_eye_cams == 2
            if ismember(metadata.stim.c.usnum_eye_2,[5 6]),
                datatoarduino(8)=metadata.stim.c.cstone(metadata.stim.c.usnum_eye_2-4);
            end
        end
        datatoarduino(10)=metadata.stim.c.usnum;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Greg%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        trueISI=metadata.stim.c.isi+metadata.stim.c.cs_addreps*metadata.stim.c.cs_period;
        if metadata.stim.l.delay==5 %cr period laser pulse
            datatoarduino(11)=trueISI-70;
        elseif metadata.stim.l.delay==6 %repeats with every flash
            datatoarduino(11)=0;
        elseif metadata.stim.l.delay==7 %repeats with every third flash, coincident with last flash
            if metadata.stim.c.cs_addreps==0 || metadata.stim.c.cs_addreps==3 %different delays to end laser with last flash
                datatoarduino(11)=0;
            elseif metadata.stim.c.cs_addreps==1 || metadata.stim.c.cs_addreps==4
                datatoarduino(11)=metadata.stim.c.cs_period; %delay 1 stimulus
            elseif metadata.stim.c.cs_addreps==2 || metadata.stim.c.cs_addreps==5
                datatoarduino(11)=metadata.stim.c.cs_period*2; %delay 2 stimuli
            end
        elseif metadata.stim.l.delay==3 || metadata.stim.l.delay==8 %%third to last flash
            datatoarduino(11)=trueISI-(1100+metadata.stim.c.csdur);
        elseif metadata.stim.l.delay==4 %%fourth to last flash
            datatoarduino(11)=trueISI-(1400+metadata.stim.c.csdur);
        else
            datatoarduino(11)=metadata.stim.l.delay;
        end

        if metadata.stim.l.delay==6 || metadata.stim.l.delay==7 || metadata.stim.l.delay==8 %set params for repeating lasers
            datatoarduino(15)=metadata.stim.l.laserperiod;
            datatoarduino(16)=metadata.stim.l.lasernumpulses;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%% shogo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if metadata.stim.l.delay==9 % sycn with US (code, not in ms)
            datatoarduino(11)=metadata.stim.c.isi;
            datatoarduino(15)=metadata.stim.l.laserperiod;
            datatoarduino(16)=metadata.stim.l.lasernumpulses;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        datatoarduino(12)=metadata.stim.l.dur;
        datatoarduino(13)=metadata.stim.l.amp;

        datatoarduino(20)=metadata.stim.c.cs_period;
        datatoarduino(21)=metadata.stim.c.cs_repeats+metadata.stim.c.cs_addreps;
        
        %%%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%
        if metadata.multicams.N_eye_cams == 2
            datatoarduino(30)=metadata.stim.c.isi_eye_2;
            datatoarduino(31)=metadata.stim.c.usdur_eye_2;
            datatoarduino(32)=metadata.stim.c.usnum_eye_2;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %Motor configuration parameters
        if (metadata.stim.motor.delay >=0)
            datatoarduino(37)=metadata.stim.motor.delay;
            datatoarduino(38)=0;
        else    
            datatoarduino(37)=0;
            datatoarduino(38)=-metadata.stim.motor.delay;
        end    
        datatoarduino(39)=metadata.stim.motor.dur;
        datatoarduino(40)=metadata.stim.motor.energized_trial;
        datatoarduino(41)=metadata.stim.motor.speed_trial;
        datatoarduino(42)=metadata.stim.motor.acceleration_trial;
        datatoarduino(43)=metadata.stim.motor.energized_intertrial;
        datatoarduino(44)=metadata.stim.motor.speed_intertrial;
        datatoarduino(45)=metadata.stim.motor.acceleration_intertrial;
        datatoarduino(46)=metadata.stim.motor.current;
        
    end

    % ---- send data to arduino ----
    arduino=getappdata(0,'arduino');
    
    %TESTING THE COMMUNICATION WITH ARDUINO, SENDING THE VALUE 110 AND WAITING
    %FOR THE SAME ANSWER.
    fwrite(arduino,110,'int8');
    pause(0.050);
    confirmation = fread(arduino,1,'int8');
    %iF ARDUINO DOESN'T RESPOND WITH THE SAME MESSAGE, THE SERIAL PORT
    %COMMUNICATION AND THE ARDUINO BOARD ARE RESET
    if isempty(confirmation) || (length(confirmation)==1 && confirmation ~=110)
        fclose(arduino);
        pause(0.050);
        fopen(arduino);
        pause(0.500);
        disp('ARDUINO BOARD HAS BEEN RESET BEFOR THE PARAMETER CONFIGURATION DUE TO A PROBLEM WITH THE COMMUNICATION')
    end
        
    
    for i=3:length(datatoarduino),
        fwrite(arduino,i,'int8');                  % header
        fwrite(arduino,datatoarduino(i),'int16');  % data
        if mod(i,4)==0,
            pause(0.010);
        end
    end
    
    
function endOfTrial2(obj,event)


    
function TriggerArduino(handles)
    refreshPermsA(handles)
    sendto_arduino() %finish puff/stimulus

    metadata=getappdata(0,'metadata');
    trialvars=readTrialTable(metadata.eye.trialnum1);
    

    vidobj=getappdata(0,'vidobj');
    src=getappdata(0,'src');
    
    vidobj.TriggerRepeat = 0;

    vidobj.StopFcn=@endOfTrial;

    flushdata(vidobj); % Remove any data from buffer before triggering

    % Set camera to hardware trigger mode
    src.TriggerSource = 'Line0';
    vidobj.FramesPerTrigger=metadata.cam.fps*(sum(metadata.cam.time)/1e3);

    stoppreview(vidobj);
    stop(vidobj);
    src.TriggerMode='On';
    % Now get camera ready for acquisition -- shouldn't start yet
    start(vidobj);
    
    %Configure the parameters for the second eye camera.
    if metadata.multicams.N_eye_cams == 2
        vidobj_eye_2=getappdata(0,'vidobj_eye_2');
        src_eye_2=getappdata(0,'src_eye_2');
        
  
        vidobj_eye_2.TriggerRepeat = 0;

        %the "endOfTrial" function configured with the first camera will
        %process all the trial information, including the one corresponding
        %to this second camera.
        vidobj_eye_2.StopFcn=@endOfTrial2;
        
        flushdata(vidobj_eye_2); % Remove any data from buffer before triggering

        % Set camera to hardware trigger mode
        src_eye_2.TriggerSource = 'Line0';
        vidobj_eye_2.FramesPerTrigger=metadata.cam_eye_2.fps*(sum(metadata.cam_eye_2.time)/1e3);

        % Now get camera ready for acquisition -- shouldn't start yet
        stoppreview(vidobj_eye_2);
        stop(vidobj_eye_2);
        src_eye_2.TriggerMode='On';        
        start(vidobj_eye_2)
    end
    
    
    %Configure the parameters for the body cameras.
    if metadata.multicams.N_body_cams > 0
        for body_cam_index = 1:metadata.multicams.N_body_cams
            vidobj_body_x=getappdata(0,['vidobj_body_' num2str(body_cam_index)]);
            src_body_x=getappdata(0,['src_body_' num2str(body_cam_index)]);


            vidobj_body_x.TriggerRepeat = 0;

            %the "endOfTrial" function configured with the first camera will
            %process all the trial information, including the one corresponding
            %to this second camera.
            vidobj_body_x.StopFcn=@endOfTrial2;

            flushdata(vidobj_body_x); % Remove any data from buffer before triggering

            % Set camera to hardware trigger mode
            src_body_x.TriggerSource = 'Line0';
            vidobj_body_x.FramesPerTrigger=metadata.cam.fps*(sum(metadata.cam.time)/1e3);

            % Now get camera ready for acquisition -- shouldn't start yet
            stoppreview(vidobj_body_x);
            stop(vidobj_body_x);
            src_body_x.TriggerMode='On';        
            start(vidobj_body_x)
        end    
    end


    metadata.ts(2)=etime(clock,datevec(metadata.ts(1)));

    %%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%%
    %CS parameters
    CS_time_ms = metadata.cam.time(1); %precam time
    CS_time_s = CS_time_ms/1000.0;
    previous_CS_time_ms = CS_time_ms - 9;
    previous_CS_time_s = (previous_CS_time_ms)/1000.0;
    previous_CS_frame = ceil(previous_CS_time_ms * metadata.cam.fps);

    %US parameters
    US_time_ms = metadata.cam.time(1)+metadata.stim.c.isi; %precam time + ISI time
    US_time_s = US_time_ms/1000.0;
    previous_US_time_ms = US_time_ms - 9;
    previous_US_time_s = (previous_US_time_ms)/1000.0;
    previous_US_frame = ceil(previous_US_time_ms * metadata.cam.fps);

    %US2 parameters
    if metadata.multicams.N_eye_cams == 2
        US2_time_ms = metadata.cam_eye_2.time(1)+metadata.stim.c.isi_eye_2; %precam time + ISI2 time
        US2_time_s = US2_time_ms/1000.0;
        previous_US2_time_ms = US2_time_ms - 9;
        previous_US2_time_s = (previous_US2_time_ms)/1000.0;
        previous_US2_frame = ceil(previous_US2_time_ms * metadata.cam_eye_2.fps);
    end
    
    %If the motor delay is negative, the trial will start with the motor,
    %but the camera will start later. 
    negative_premotor_delay = 0;
    if metadata.stim.motor.delay < 0
        negative_premotor_delay = abs(metadata.stim.motor.delay)/1000.0;
    end
    
    %Ponderated CR amplitude respect to the CS_eyelidpos baseline required to
    %suppress the US stimulus (between 0 and 1).
    omit_CR_threshold=trialvars(get_trial_index('omit_CR_threshold'));

    %Ponderated CR2 amplitude respect to the CS_eyelidpos baseline required to
    %suppress the US2 stimulus (between 0 and 1).
    omit_CR2_threshold=trialvars(get_trial_index('omit_CR2_threshold'));
    
    
    
    %Number of omitted US (defined as persistent to store the value for all
    %the trials)
    persistent N_first_eye_CRs
    if isempty(N_first_eye_CRs)
        N_first_eye_CRs=0;
    end
    %Number of omitted US (defined as persistent to store the value for all
    %the trials)
    persistent N_second_eye_CRs
    if isempty(N_second_eye_CRs)
        N_second_eye_CRs=0;
    end
    
   
    first_eye_US_trigger = 1;
    second_eye_US_trigger = 1;
    trial_aborted = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %TESTING THE COMMUNICATION WITH ARDUINO, SENDING THE VALUE 0 AND WAITING
    %FOR THE SAME ANSWER.
    arduino=getappdata(0,'arduino');
    fwrite(arduino,110,'int8');
    pause(0.050);
    confirmation = fread(arduino,1,'int8');
    %iF ARDUINO DOESN'T RESPOND WITH THE SAME MESSAGE, THE SERIAL PORT
    %COMMUNICATION AND THE ARDUINO BOARD ARE RESET
    if isempty(confirmation) || (length(confirmation)==1 && confirmation ~=110)
        disp('TRIGGER ERROR: TRIAL ABORTED DUE TO A PROBLEM WITH ARDUINO COMMUNICATION. ARDUINO BOARD HAS BEEN RESET')
        ghandles=getappdata(0,'ghandles');
        handles_maingui=guidata(ghandles.maingui);
        vidobj=getappdata(0,'vidobj');
        src=getappdata(0,'src');
        stoppreview(vidobj);
        stop(vidobj);
        src.TriggerMode='Off';    
        preview(vidobj,handles_maingui.pwin);
        return
    end
    
    
    
    % --- trigger via arduino --
    arduino=getappdata(0,'arduino');
    fwrite(arduino,1,'int8');

%     %%%%%%%%%%%%%%%%%FRANCISCO%%%%%%%%%%%%%%%%%%%%%%%%%
   
%     tStart = tic;
%     while 1
%         tStop = toc(tStart) - negative_premotor_delay; %during the first "negative_premotor_delay" seconds of the trial the cameras are not recording
%         %abort the trial if the eye is to closed befor the start of the CS stimulus
%         if vidobj.FramesAvailable >= previous_CS_frame || tStop > previous_CS_time_s 
%             %First eye
%             data = getsnapshot(vidobj);
%             roi=data.*uint8(metadata.cam.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
%             eyelidpos=sum(roi(:)>=256*metadata.cam.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units
%             previous_CS_eyelidpos = (eyelidpos-metadata.cam.calib_offset)/metadata.cam.calib_scale; % eyelid pos
%             
%             %second eye
%             if metadata.multicams.N_eye_cams == 2
%                 data_eye_2 = getsnapshot(vidobj_eye_2);
%                 roi=data_eye_2.*uint8(metadata.cam_eye_2.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
%                 eyelidpos_eye_2=sum(roi(:)>=256*metadata.cam_eye_2.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units
%                 previous_CS_eyelidpos_eye_2 = (eyelidpos_eye_2-metadata.cam_eye_2.calib_offset)/metadata.cam_eye_2.calib_scale; % eyelid pos
%             end
% 
%             %abort trial if the eyelid pos is larger than the eyelid
%             %threshold + 0.05
%             if getappdata(0,'abort_trial_enabled') && (previous_CS_eyelidpos > (getappdata(0,'eyeThreshold') + 0.05) && get(handles.wait_first_eye,'Value') || (metadata.multicams.N_eye_cams == 2 && previous_CS_eyelidpos_eye_2 > (getappdata(0,'eyeThreshold') + 0.05) && get(handles.wait_second_eye,'Value')))
%                 tStop = toc(tStart);
%                 if tStop<CS_time_s
%                     fwrite(arduino,50,'int8');  % header
%                     fwrite(arduino,1,'int16');  % data
%                     if metadata.multicams.N_eye_cams == 2
%                         fprintf('Trial %d aborter %f ms before CS onset due to first (%f) or second (%f) eyelids are too closed befor CS onset\n', metadata.cam.trialnum, CS_time_s-tStop, previous_CS_eyelidpos, previous_CS_eyelidpos_eye_2)
%                     else
%                         fprintf('Trial %d aborter %f ms before CS onset due to eyelid is too closed befor CS onset: %f\n', metadata.cam.trialnum, CS_time_s-tStop, previous_CS_eyelidpos)
%                     end
% 
%                     trial_aborted = 1;
%                 else
%                     previous_CS_time_ms = previous_CS_time_ms - (tStop-CS_time_s)*1000.0;
%                     previous_CS_time_s = (previous_CS_time_ms)/1000.0;
%                     previous_CS_frame = ceil(previous_CS_time_ms * metadata.cam.fps);
%                 end
%             end
%             break
%         end
%     end
% 
%     if ~trial_aborted
%         omit_US = trialvars(get_trial_index('omit_US'));
%         omit_US2 = trialvars(get_trial_index('omit_US2'));
%         omit_US_or_US2 = trialvars(get_trial_index('omit_US_or_US2'));
%         while 1 
%             %The camera is not recording the first puff
%             if metadata.stim.c.isi > metadata.cam.time(2)+metadata.cam.time(3)
%                 break
%             end            
%             %Omit the US generation if the CR is large enough
%             tStop = toc(tStart) - negative_premotor_delay; %during the first "negative_premotor_delay" seconds of the trial the cameras are not recording 
%             if vidobj.FramesAvailable >= previous_US_frame || tStop > previous_US_time_s
%                 FramesAvailable = vidobj.FramesAvailable;
%                 data = getsnapshot(vidobj);
%                 roi=data.*uint8(metadata.cam.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
%                 eyelidpos=sum(roi(:)>=256*metadata.cam.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units
%                 previous_US_eyelidpos = (eyelidpos-metadata.cam.calib_offset)/metadata.cam.calib_scale; % eyelid pos
% 
%                 CR_value = (previous_US_eyelidpos-previous_CS_eyelidpos)/(1-previous_CS_eyelidpos);
%                 if (omit_US || omit_US_or_US2)
%                     if CR_value > omit_CR_threshold
%                         first_eye_US_trigger = 0;
%                     elseif(omit_US_or_US2)
%                         second_eye_US_trigger = 0;
%                     end
% 
%                     tStop = toc(tStart) - negative_premotor_delay; %during the first "negative_premotor_delay" seconds of the trial the cameras are not recording
%                     %Send to arduino the corresponding order about the abortion
%                     %of the first US (header=51).
%                     fwrite(arduino,51,'int8');          % header
%                     fwrite(arduino,first_eye_US_trigger,'int16');  % data
%                 end
%                 
%                 if CR_value > 0.2
%                     N_first_eye_CRs=N_first_eye_CRs+1;
%                 end
%                 
%                 if tStop>previous_US_frame
%                     previous_US_time_ms = previous_US_time_ms - (tStop-previous_US_time_s)*1000.0;
%                     previous_US_time_s = (previous_US_time_ms)/1000.0;
%                     previous_US_frame = ceil(previous_US_time_ms * metadata.cam.fps);
%                 end
%                 break;
%             end
%         end
% 
%         print_info_omit_US2=0;
%         if metadata.multicams.N_eye_cams == 2
%             if second_eye_US_trigger == 0
%                 %Send to arduino the corresponding order about the abortion
%                 %of the second US (header=52).
%                 fwrite(arduino,52,'int8');          % header
%                 fwrite(arduino,second_eye_US_trigger,'int16');  % data
%             else
%                 while 1 
%                     %The camera is not recording the second puff
%                     if metadata.stim.c.isi_eye_2 > metadata.cam.time(2)+metadata.cam.time(3)
%                         break
%                     end  
%                     %Omit the US generation if the CR is large enough
%                     tStop_eye_2 = toc(tStart) - negative_premotor_delay; %during the first "negative_premotor_delay" seconds of the trial the cameras are not recording
%                     if vidobj_eye_2.FramesAvailable >= previous_US2_frame || tStop_eye_2 > previous_US2_time_s
%                         FramesAvailable_eye_2 = vidobj_eye_2.FramesAvailable;
%                         data_eye_2 = getsnapshot(vidobj_eye_2);
%                         roi=data_eye_2.*uint8(metadata.cam_eye_2.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
%                         eyelidpos_eye_2=sum(roi(:)>=256*metadata.cam_eye_2.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units
%                         previous_US2_eyelidpos = (eyelidpos_eye_2-metadata.cam_eye_2.calib_offset)/metadata.cam_eye_2.calib_scale; % eyelid pos
% 
%                         CR2_value = (previous_US2_eyelidpos-previous_CS_eyelidpos_eye_2)/(1-previous_CS_eyelidpos_eye_2);
%                         if omit_US2
%                             if CR2_value > omit_CR2_threshold
%                                 second_eye_US_trigger = 0;
%                                 N_omitted_US2 = N_omitted_US2 + 1;
%                             end
%                             tStop_eye_2 = toc(tStart) - negative_premotor_delay; %during the first "negative_premotor_delay" seconds of the trial the cameras are not recording
%                             %Send to arduino the corresponding order about the abortion
%                             %of the second US (header=52).
%                             fwrite(arduino,52,'int8');          % header
%                             fwrite(arduino,second_eye_US_trigger,'int16');  % data
%                             
%                             %We must print the info regarding the second eye.
%                             print_info_omit_US2=1;
%                         
%                         end
%                         if CR2_value > 0.2
%                             N_second_eye_CRs=N_second_eye_CRs+1;
%                         end
% 
%                         if tStop_eye_2>previous_US2_frame
%                             previous_US2_time_ms = previous_US2_time_ms - (tStop_eye_2-previous_US2_time_s)*1000.0;
%                             previous_US2_time_s = (previous_US2_time_ms)/1000.0;
%                             previous_US2_frame = ceil(previous_US2_time_ms * metadata.cam_eye_2.fps);
%                         end
% 
%                         break;
%                     end
%                 end
%             end
%         end
% 
%         if omit_US || omit_US_or_US2
%             fprintf('Trial: %d, first eye position: %f, CR value: %f, US_trigger: %d, time to US: %f ms, frames available: %d.\n', metadata.cam.trialnum, previous_US_eyelidpos, CR_value,first_eye_US_trigger, US_time_s-tStop, FramesAvailable)
%         end   
%         if print_info_omit_US2==1 
%             fprintf('Trial: %d, second eye position: %f, CR2 value: %f, US2_trigger: %d, time to US: %f ms, frames available: %d.\n', metadata.cam.trialnum, previous_US2_eyelidpos, CR2_value, second_eye_US_trigger, US2_time_s-tStop_eye_2, FramesAvailable_eye_2)
%         end
%         
%         %set if the first eye US has been generated or ommited
%         metadata.trial_control.first_eye_US_trigger = first_eye_US_trigger;
%         
%         %update the number and rate of CRs in the GUI
%         str_N=sprintf('%d', N_first_eye_CRs);
%         set(handles.value_N_first_eye_CRs,'String',str_N);
%         str_rate=sprintf('%1.2f', (1.0*N_first_eye_CRs)/metadata.eye.trialnum1);
%         set(handles.value_first_eye_CR_rate,'String',str_rate);
% 
%         if metadata.multicams.N_eye_cams == 2
%             %set if the second eye US has been generated or ommited
%             metadata.trial_control.second_eye_US_trigger = second_eye_US_trigger;
%             %update the number and rate of CRs in the GUI
%             str_N=sprintf('%d', N_second_eye_CRs);
%             set(handles.value_N_second_eye_CRs,'String',str_N);
%             str_rate=sprintf('%1.2f', (1.0*N_second_eye_CRs)/metadata.eye.trialnum1);
%             set(handles.value_second_eye_CR_rate,'String',str_rate);
%         end
%     end            
   
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % ---- write status bar ----
    setappdata(0,'trial_aborted',trial_aborted);
    if (trial_aborted==0)
        trials=getappdata(0,'trials');
        set(handles.text_status,'String',sprintf('Total trials: %d\n',metadata.cam.trialnum));
        if strcmpi(metadata.stim.type,'conditioning')
            trialvars=readTrialTable(metadata.eye.trialnum1+1);
            csdur=trialvars(1);
            csnum=trialvars(2);
            isi=trialvars(3);
            usdur=trialvars(4);
            usnum=trialvars(5);
            cstone=str2num(get(handles.edit_tone,'String'));
            if length(cstone)<2, cstone(2)=0; end

            str2=[];
            if ismember(csnum,[5 6]),
                str2=[' (' num2str(cstone(csnum-4)) ' KHz)'];
            end

            str1=sprintf('Next:  No %d,  CS ch %d%s,  ISI %d,  US %d, US ch %d',metadata.eye.trialnum1+1, csnum, str2, isi, usdur, usnum);
            set(handles.text_disp_cond,'String',str1)
        end
        setappdata(0,'metadata',metadata);
    end

    


function newFrameCallback(obj,event,himage)
    ghandles=getappdata(0,'ghandles');
    handles=guidata(ghandles.maingui);
    vidobj=getappdata(0,'vidobj');
    src=getappdata(0,'src');
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
        set(0,'currentfigure',ghandles.maingui)
    %     set(ghandles.maingui,'CurrentAxes',handles.axes_eye)
    %     cla
        eyeTrace=plot(handles.axes_eye,[plt_range 0],[1 1]*0,'k-',[plt_range 0],[1 1]*0.2,'r--'); hold on
        set(handles.axes_eye,'color',[240 240 240]/255,'YAxisLocation','right');
        set(handles.axes_eye,'xlim',[plt_range 0],'ylim',[-0.1 1.1])
        set(handles.axes_eye,'xtick',[-3000:500:0],'box','off')
        set(handles.axes_eye,'ytick',[0:0.5:1],'yticklabel',{'0' '' '1'})
    end


    % --- eye trace ---
    wholeframe = event.Data;
    roi=wholeframe.*uint8(metadata.cam.mask);
    eyelidpos=sum(roi(:)>=256*metadata.cam.thresh);

    % --- eye trace buffer ---
    eyedata(1:end-1,:)=eyedata(2:end,:);
    timeSinceStreamStartMS=round(1000*etime(clock,timeOfStreamStart));
    eyedata(end,1)=timeSinceStreamStartMS;
    eyedata(end,2)=(eyelidpos-metadata.cam.calib_offset)/metadata.cam.calib_scale; % eyelid pos

    %Eyelid trace
    set(eyeTrace(1),'XData',eyedata(:,1)-timeSinceStreamStartMS,'YData',eyedata(:,2))
    
   
    set(himage,'CData',event.Data)
    
    %The abort trial option is enabled by default
    setappdata(0,'abort_trial_enabled',1);
    try
        % --- Check if new trial should be triggered ----
        if get(handles.toggle_continuous,'Value') == 1

            stopTrial = str2double(get(handles.edit_StopAfterTrial,'String'));
            if stopTrial > 0 && metadata.cam.trialnum > stopTrial
                set(handles.toggle_continuous,'Value',0);
                set(handles.toggle_continuous,'String','Start Continuous');
            end

            elapsedTimeSinceLastTrial=etime(clock,timeSinceLastTrial);
            timeLeft = metadata.stim.c.ITI - elapsedTimeSinceLastTrial;

            set(handles.trialtimecounter,'String',num2str(round(timeLeft)))

            trialvars=readTrialTable(metadata.eye.trialnum1);
            post_ITI_thr_inc_start_s=trialvars(get_trial_index('post_ITI_thr_inc_start_s'));
            post_ITI_thr_inc_dur_s=trialvars(get_trial_index('post_ITI_thr_inc_dur_s'));
            post_ITI_thr_inc=trialvars(get_trial_index('post_ITI_thr_inc'));
            
            
            timeLeftThreshold=metadata.stim.c.ITI + post_ITI_thr_inc_start_s + post_ITI_thr_inc_dur_s - elapsedTimeSinceLastTrial;
            eyeThreshold=str2double(get(handles.edit_eyethr,'String'));
            
            if timeLeftThreshold<post_ITI_thr_inc_dur_s && post_ITI_thr_inc_dur_s > 0
                set(handles.trialthresholdcounter,'String',num2str(round(timeLeftThreshold)))
                set(handles.trialthresholdcounter,'Visible','On')
                eyeThreshold=eyeThreshold + (1 - timeLeftThreshold/post_ITI_thr_inc_dur_s) * post_ITI_thr_inc;
                if timeLeftThreshold < 0
                    %The abort trial option is disabled due to we are going to force the trial to start. 
                    setappdata(0,'abort_trial_enabled',0); 
                end
                
            else    
                set(handles.trialthresholdcounter,'Visible','Off')
            end
            
            %Eyelid threshold
            set(eyeTrace(2),'XData',eyedata(:,1)-timeSinceStreamStartMS,'YData',ones(1,length(eyedata))*eyeThreshold)
            setappdata(0,'eyeThreshold',eyeThreshold);
            
            if timeLeft <= 0
                eyeok=checkeye(handles, eyedata, eyeThreshold);
                if eyeok || (timeLeftThreshold<0 && post_ITI_thr_inc_dur_s > 0)
                    TriggerArduino(handles)
                    timeSinceLastTrial=clock;
                end
            end
        end
    catch
        try % If it's a dropped frame, see if we can recover
            handles.pwin=image(zeros(600,800),'Parent',handles.cameraAx);
            pause(0.5)
            vidobj=getappdata(0,'vidobj');
            stoppreview(vidobj);
            stop(vidobj);
            src.TriggerMode='Off';
            closepreview(vidobj);
            pause(0.2)
            preview(vidobj,handles.pwin);
        %     guidata(handles.cameraAx,handles)
        %    stream(handles)
            disp('Caught camera error')
        catch
            disp('Aborted eye streaming.')
            set(handles.togglebutton_stream,'Value',0);
        %     set(handles.pushbutton_StartStopPreview,'String','Start Preview')
        %     closepreview(vidobj);
            return
        end
    end


% function stream(handles)
%     ghandles=getappdata(0,'ghandles');
%     vidobj=getappdata(0,'vidobj');
%     src=getappdata(0,'src');
%     % updaterate=0.017;   % ~67 Hz
%     % updaterate=0.1;   % 10 Hz
%     if ~exist('t1','var')
%         t1=clock;
%     end
%     t0=clock;
% 
%     eyedata=NaN*ones(500,2);
%     plt_range=-2100;
% 
%     if get(handles.togglebutton_stream,'Value')
%         set(0,'currentfigure',ghandles.maingui)
%         set(ghandles.maingui,'CurrentAxes',handles.axes_eye)
%         cla
%         pl1=plot([plt_range 0],[1 1]*0,'k-'); hold on
%         set(gca,'color',[240 240 240]/255,'YAxisLocation','right');
%         set(gca,'xlim',[plt_range 0],'ylim',[-0.1 1.1])
%         set(gca,'xtick',[-3000:500:0],'box','off')
%         set(gca,'ytick',[0:0.5:1],'yticklabel',{'0' '' '1'})
%     end
% 
%     try
%         while get(handles.togglebutton_stream,'Value') == 1
%             t2=clock;
%             metadata=getappdata(0,'metadata');  % get updated metadata within this loop, otherwise we'll be using stale data
% 
%             % --- eye trace ---
%             wholeframe=getsnapshot(vidobj);
%             roi=wholeframe.*uint8(metadata.cam.mask); % multiply the frame by the mask --> everything outside of the ROI becomes 0 and everything inside the ROI remains the same (is multiplied by 1)
%             eyelidpos=sum(roi(:)>=256*metadata.cam.thresh); % find everywhere in roi that is > your threshold value converted into 8-bit-integer units
% 
%             % --- eye trace buffer ---
%             etime0=round(1000*etime(clock,t0));
%             eyedata(1:end-1,:)=eyedata(2:end,:);
%             eyedata(end,1)=etime0;
%             eyedata(end,2)=(eyelidpos-metadata.cam.calib_offset)/metadata.cam.calib_scale; % eyelid pos
% 
%             set(pl1,'XData',eyedata(:,1)-etime0,'YData',eyedata(:,2))
% 
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
%     %             etime1=t2-t1;
%     %             etime1=etime1(6);
%                 if etime1>metadata.stim.c.ITI,
%                     eyeok=checkeye(handles,eyedata);
%                     if eyeok
%                         TriggerArduino(handles)
%                         t1=clock;
%                     end
%                 end
%             end
% 
%     %         t=round(1000*etime(clock,t2))/1000;
%             % -- pause in the left time -----
%     %         d=updaterate-t;
%     %         if d>0
%     %             pause(d)        %   java.lang.Thread.sleep(d*1000);     %     drawnow
%     %         else
%     %             if get(handles.checkbox_verbose,'Value') == 1
%     %                 disp(sprintf('%s: Unable to sustain requested stream rate! Loop required %f seconds.',datestr(now,'HH:MM:SS'),t))
%     %             end
%     %         end
% 
%             % Try to deal with dropped frames silently
%             % if strcmp(src.TriggerSource,'Software') & strcmp(vidobj.Previewing,'off')
%             %     handles.pwin=image(zeros(480,640),'Parent',handles.cameraAx);
%             %     preview(vidobj,handles.pwin);
%             % end
% 
%             % if strcmp(src.TriggerSource,'Line0') & strcmp(vidobj.Running,'off')
%             %     start(vidobj);
%             % end
% 
%         end
%     catch
%         if isvalid(handles.togglebutton_stream) %if we are quitting, don't try to restart the stream
%             try % If it's a dropped frame, see if we can recover
%                 handles.pwin=image(zeros(600,800),'Parent',handles.cameraAx);
%                 pause(0.5)
%                 closepreview(vidobj);
%                 pause(0.2)
%                 preview(vidobj,handles.pwin);
%                 %     guidata(handles.cameraAx,handles)
%                 stream(handles)
%                 disp('Caught camera error')
%             catch
%                 disp('Aborted eye streaming.')
%                 set(handles.togglebutton_stream,'Value',0);
%                 %     set(handles.pushbutton_StartStopPreview,'String','Start Preview')
%                 %     closepreview(vidobj);
%                 return
%             end
%         end
%     end


function eyeok=checkeye(handles, eyedata, eyeThreshold)
    eyeok = true;

    %We check if we must wait or not until the first eye is ready
%     if get(handles.wait_first_eye,'Value')
%         eyethrok = (eyedata(end,2)<str2double(get(handles.edit_eyethr,'String')));
%         eyedata(:,1)=eyedata(:,1)-eyedata(end,1);
%         recenteye=eyedata(eyedata(:,1)>-1000*str2double(get(handles.edit_stabletime,'String')), 2);
%         eyestableok = ((max(recenteye)-min(recenteye))<str2double(get(handles.edit_stableeye,'String')));
%         eyeok = eyethrok && eyestableok; 
%     end
    
    if get(handles.wait_first_eye,'Value')
        eyedata(:,1)=eyedata(:,1)-eyedata(end,1);
        recenteye=eyedata(eyedata(:,1)>-1000*str2double(get(handles.edit_stabletime,'String')), 2);
        eyestableok = ((max(recenteye)-min(recenteye))<str2double(get(handles.edit_stableeye,'String')));
        eyethrok = (eyedata(end,2)<eyeThreshold);
        eyemeanthrok = (mean(recenteye)<eyeThreshold);
        
        eyeok = eyestableok && eyethrok && eyemeanthrok; 
    end
    
    %We check if the second eye is also ready for the new trial
    if eyeok && get(handles.wait_second_eye,'Value')
        metadata = getappdata(0,'metadata');
        if metadata.multicams.N_eye_cams > 1
            eyedata_2 = getappdata(0,'eyedata_2');
            eyedata_2(:,1)=eyedata_2(:,1)-eyedata_2(end,1);
            recenteye=eyedata_2(eyedata_2(:,1)>-1000*str2double(get(handles.edit_stabletime,'String')), 2);
            eyestableok = ((max(recenteye)-min(recenteye))<str2double(get(handles.edit_stableeye,'String')));
            eyethrok = (eyedata_2(end,2)<eyeThreshold);
            eyemeanthrok = (mean(recenteye)<eyeThreshold);
            
            eyeok = eyeok && eyestableok && eyethrok && eyemeanthrok; 
        end
    end
    

    %%%%%%%%%% end of user functions %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







% --- Executes on button press in checkbox_random.
function checkbox_random_Callback(hObject, eventdata, handles)
    % hObject    handle to checkbox_random (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hint: get(hObject,'Value') returns toggle state of checkbox_random


function edit_tone_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_tone (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of edit_tone as text
    %        str2double(get(hObject,'String')) returns contents of edit_tone as a double


% --- Executes during object creation, after setting all properties.
function edit_tone_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_tone (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end




% --- Executes during object creation, after setting all properties.
function popupmenu_stimtype_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to popupmenu_stimtype (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function edit_puffdur_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_puffdur (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_puffdur as text
    %        str2double(get(hObject,'String')) returns contents of edit_puffdur as a double


% --- Executes during object creation, after setting all properties.
function edit_puffdur_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_puffdur (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes during object creation, after setting all properties.
function text_SessionName_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to text_SessionName (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called





function edit_stabletime_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_stabletime (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_stabletime as text
    %        str2double(get(hObject,'String')) returns contents of edit_stabletime as a double


% --- Executes during object creation, after setting all properties.
function edit_stabletime_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_stabletime (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function edit_stableeye_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_stableeye (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_stableeye as text
    %        str2double(get(hObject,'String')) returns contents of edit_stableeye as a double


% --- Executes during object creation, after setting all properties.
function edit_stableeye_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_stableeye (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function edit_eyethr_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_eyethr (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_eyethr as text
    %        str2double(get(hObject,'String')) returns contents of edit_eyethr as a double


% --- Executes during object creation, after setting all properties.
function edit_eyethr_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_eyethr (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in checkbox_verbose.
function checkbox_verbose_Callback(hObject, eventdata, handles)
    % hObject    handle to checkbox_verbose (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of checkbox_verbose



    % function edit_posttime_Callback(hObject, eventdata, handles)
    % % hObject    handle to edit_posttime (see GCBO)
    % % eventdata  reserved - to be defined in a future version of MATLAB
    % % handles    structure with handles and user data (see GUIDATA)
    % 
    % % Hints: get(hObject,'String') returns contents of edit_posttime as text
    % %        str2double(get(hObject,'String')) returns contents of edit_posttime as a double


    % % --- Executes during object creation, after setting all properties.
    % function edit_posttime_CreateFcn(hObject, eventdata, handles)
    % % hObject    handle to edit_posttime (see GCBO)
    % % eventdata  reserved - to be defined in a future version of MATLAB
    % % handles    empty - handles not created until after all CreateFcns called
    % 
    % % Hint: edit controls usually have a white background on Windows.
    % %       See ISPC and COMPUTER.
    % if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    %     set(hObject,'BackgroundColor','white');
    % end


% --- Executes on button press in pushbutton_abort.
function pushbutton_abort_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton_abort (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % If camera gets hung up for any reason, this button can be pressed to
    % reset it.

    vidobj = getappdata(0,'vidobj');
    src = getappdata(0,'src');

    stop(vidobj);
    flushdata(vidobj);

    src.TriggerSource = 'Software';




    % function edit_ITI_rand_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_ITI_rand (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_ITI_rand as text
    %        str2double(get(hObject,'String')) returns contents of edit_ITI_rand as a double


    % --- Executes during object creation, after setting all properties.
    % function edit_ITI_rand_CreateFcn(hObject, eventdata, handles)
    % % hObject    handle to edit_ITI_rand (see GCBO)
    % % eventdata  reserved - to be defined in a future version of MATLAB
    % % handles    empty - handles not created until after all CreateFcns called
    % 
    % % Hint: edit controls usually have a white background on Windows.
    % %       See ISPC and COMPUTER.
    % if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    %     set(hObject,'BackgroundColor','white');
    % end



function edit_StopAfterTrial_Callback(hObject, eventdata, handles)
    % hObject    handle to edit_StopAfterTrial (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of edit_StopAfterTrial as text
    %        str2double(get(hObject,'String')) returns contents of edit_StopAfterTrial as a double


% --- Executes during object creation, after setting all properties.
function edit_StopAfterTrial_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to edit_StopAfterTrial (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes on button press in pushbutton_loadParams.
function pushbutton_loadParams_Callback(hObject, eventdata, handles)
    % hObject    handle to pushbutton_loadParams (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    paramtable = getappdata(0,'paramtable');

    [paramfile,paramfilepath,filteridx] = uigetfile('*.csv');

    if paramfile & filteridx == 1 % The filterindex thing is a hack to make sure it's a csv file
        paramtable.data=load_params(fullfile(paramfilepath,paramfile));
        set(handles.uitable_params,'Data',paramtable.data);
        setappdata(0,'paramtable',paramtable);
    end
    
    %update the trial table
    update_trial_table(hObject, eventdata, handles);
    
    %The default parameters have been modified.
    setappdata(0,'defaultparametersmodified', 1);


% --- Executes on key press with focus on pushbutton_opentable and none of its controls.
function pushbutton_opentable_KeyPressFcn(hObject, eventdata, handles)
    % hObject    handle to pushbutton_opentable (see GCBO)
    % eventdata  structure with the following fields (see UICONTROL)
    %	Key: name of the key that was pressed, in lower case
    %	Character: character interpretation of the key(s) that was pressed
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
    % handles    structure with handles and user data (see GUIDATA)


% --- Executes when entered data in editable cell(s) in uitable_params.
function uitable_params_CellEditCallback(hObject, eventdata, handles)
    % hObject    handle to uitable_params (see GCBO)
    % eventdata  structure with the following fields (see UITABLE)
    %	Indices: row and column indices of the cell(s) edited
    %	PreviousData: previous data for the cell(s) edited
    %	EditData: string(s) entered by the user
    %	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
    %	Error: error string when failed to convert EditData to appropriate value for Data
    % handles    structure with handles and user data (see GUIDATA)
    
    %update the trial table if some parameter is modified.
    update_trial_table(hObject, eventdata, handles);
    
    %The default parameters have been modified.
    setappdata(0,'defaultparametersmodified', 1);


% --- Executes on button press in wait_first_eye.
function wait_first_eye_Callback(hObject, eventdata, handles)
    % hObject    handle to wait_first_eye (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of wait_first_eye
    
    paramtable = getappdata(0, 'paramtable');
    paramtable.WaitFirstEye=get(handles.wait_first_eye,'Value');
    setappdata(0,'paramtable',paramtable);


% --- Executes on button press in wait_second_eye.
function wait_second_eye_Callback(hObject, eventdata, handles)
    % hObject    handle to wait_second_eye (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of wait_second_eye

    paramtable = getappdata(0, 'paramtable');
    paramtable.WaitSeconEye=get(handles.wait_second_eye,'Value');
    setappdata(0,'paramtable',paramtable);



function first_eye_US_generation_rate_Callback(hObject, eventdata, handles)
% hObject    handle to first_eye_US_generation_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of first_eye_US_generation_rate as text
%        str2double(get(hObject,'String')) returns contents of first_eye_US_generation_rate as a double


% --- Executes during object creation, after setting all properties.
function first_eye_US_generation_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to first_eye_US_generation_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_first_eye_US_generation_rate.
function checkbox_first_eye_US_generation_rate_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_first_eye_US_generation_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_first_eye_US_generation_rate


% --- Executes on button press in fast_saving_box.
function fast_saving_box_Callback(hObject, eventdata, handles)
% hObject    handle to fast_saving_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    
    fast_saving_option=get(handles.fast_saving_box,'Value');
    setappdata(0,'fast_saving_option',fast_saving_option);



function note_value_Callback(hObject, eventdata, handles)
% hObject    handle to note_value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of note_value as text
%        str2double(get(hObject,'String')) returns contents of note_value as a double

    note_value=get(handles.note_value, 'String');
    setappdata(0,'note_value', note_value);


% --- Executes during object creation, after setting all properties.
function note_value_CreateFcn(hObject, eventdata, handles)
% hObject    handle to note_value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
