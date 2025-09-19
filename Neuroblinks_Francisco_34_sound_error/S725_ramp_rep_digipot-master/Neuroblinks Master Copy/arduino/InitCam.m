function InitCam(cams)

    % First delete any existing image acquisition objects
    imaqreset

    %get metadata
    metadata=getappdata(0,'metadata');

    for i=1:length(cams)

        msg = ['Creating video object ', num2str(i)];
        disp(msg)
        vidobj = videoinput('gentl', cams(i), 'Mono8');
 

        src = getselectedsource(vidobj);
        
        src.ExposureTime = metadata.cam.init_ExposureTime;
        src.AcquisitionFrameRateMode='Basic'; %must be set to basic to change frame rate later
        %New option required for the alvion cameras.
        if isprop(src,'AcquisitionFrameRateEnable')
            src.AcquisitionFrameRateEnable='true';
        end
        % src.AllGain=12;				% Tweak this based on IR light illumination (lower values preferred due to less noise)
        % src.StreamBytesPerSecond=124e6; % Set based on AVT's suggestion
        % src.StreamBytesPerSecond=80e6; % Set based on AVT's suggestion

        % src.PacketSize = 9014;		% Use Jumbo packets (ethernet card must support them) -- apparently not supported in VIMBA
        % src.PacketSize = 8228;		% Use Jumbo packets (ethernet card must support them) -- apparently not supported in VIMBA
        % src.PacketDelay = 2000;		% Calculated based on frame rate and image size using Mathworks helper function
        vidobj.LoggingMode = 'memory'; 
        src.AcquisitionFrameRate=200.000080000032; %%exactly 200 not available, camera auto switches to this value
        % vidobj.Fr

        %FramesPerTrigger=ceil(metadata.cam.recdurA/(1000/200));
        % vidobj.FramesPerTrigger=20;
        % vidobj.FramesPerTrigger=ceil(recdur/(1000/49.7604));
        %vidobj.FramesPerTrigger=FramesPerTrigger;

        % triggerconfig(vidobj, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
        % set(src,'AcquisitionStartTriggerMode','on')
        % set(src,'FrameStartTriggerSource','Freerun')
        % set(src,'AcquisitionStartTriggerActivation','RisingEdge')

        triggerconfig(vidobj, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
 %       triggerconfig(vidobj, 'immediate');
       
        % src.FrameStartTriggerActivation = 'LevelHigh';
        src.TriggerActivation = 'LevelHigh';
        % This needs to be toggled to switch between preview and acquisition mode
        % It is changed to 'Line0' in MainWindow just before triggering Arduino and then
        % back to 'Software' in 'endOfTrial' function
        % src.FrameStartTriggerSource = 'Line1';
        src.TriggerSource = 'Line0';
 %       src.TriggerSource = 'Software';
%src.TriggerSelector='AcquisitionStart';
    
        src.TriggerMode='Off';
%src.TriggerMode='On';

        % src.TriggerSelector='FrameStart';
        src.TriggerSelector='AcquisitionStart';
        % src.TriggerSource='Freerun';

        %% Save objects to root app data
        % First eye camera 
        if i == 1
            %Save the first eye camera objects as "vidobj" and "src"
            setappdata(0,'vidobj',vidobj)
            setappdata(0,'src',src)
        end
        %Second eye camera
        if metadata.multicams.N_eye_cams > 1 && i == metadata.multicams.N_eye_cams
            %Save the second eye camera objects as "vidobj_eye_2" and "src_eye_2"
            setappdata(0,'vidobj_eye_2',vidobj)
            setappdata(0,'src_eye_2',src)
        end
        
        %Body cameras
        if i > metadata.multicams.N_eye_cams
            %Save the body camera objects as "vidobj_body_x" and
            %"src_body_x", where x represent the body cam index
            setappdata(0,['vidobj_body_',num2str(i - metadata.multicams.N_eye_cams)],vidobj)
            setappdata(0,['src_body_',num2str(i - metadata.multicams.N_eye_cams)],src)
        end
    end
