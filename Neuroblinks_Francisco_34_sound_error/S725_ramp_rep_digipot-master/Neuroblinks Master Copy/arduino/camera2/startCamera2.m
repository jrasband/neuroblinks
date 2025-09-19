function startCamera2()

TDT = getappdata(0,'tdt');
cam2 = getappdata(0,'cam2');
metadata = getappdata(0,'metadata');

vidobj2 = getappdata(0,'vidobj2');
src = getselectedsource(vidobj2);

if isprop(src,'FrameStartTriggerSource')
    src.FrameStartTriggerSource = 'FixedRate';  % Switch from free run to TTL mode
else
    src.TriggerSource = 'FixedRate';
end

if strcmp(cam2.triggermode,'Manual to disk')
    % We have to set up the video writer object here 
    basename = sprintf('%s\\%s_cam2',metadata.folder,metadata.TDTblockname);
    videoname=sprintf('%s_%03d.mp4', basename, cam2.trialnum);
    diskLogger = VideoWriter(videoname,'MPEG-4');
    set(diskLogger,'FrameRate',20);
    vidobj2.DiskLogger = diskLogger;
else
    vidobj2.DiskLogger = [];
end

TDT.setParameterValue('RZ5(1)','Cam2Trial',cam2.trialnum);

vidobj2.StopFcn = @stopCamera2Callback;

flushdata(vidobj2)
start(vidobj2)

% Trigger TDT
TDT.setParameterValue('RZ5(1)','StartCam2',1);

cam2.time = etime(clock,datevec(metadata.ts(1)));
setappdata(0,'cam2',cam2);