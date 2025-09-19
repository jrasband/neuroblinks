function stopCamera2Callback(vidobj2,event)

src = getselectedsource(vidobj2);

metadata = getappdata(0,'metadata');
TDT = getappdata(0,'tdt');
cam2 = getappdata(0,'cam2');
tmp=getappdata(0,'tmp');

if isprop(src,'FrameStartTriggerSource')
    src.FrameStartTriggerSource = 'Freerun';  % Switch from TTL to free run mode
else
    src.TriggerSource = 'Freerun';
end

basename = sprintf('%s\\%s_cam2',metadata.folder,metadata.TDTblockname);

if ~strcmp(cam2.triggermode,'Manual to disk')
    vid = getdata(vidobj2,vidobj2.FramesAvailable);

    videoname=sprintf('%s_%03d', basename, cam2.trialnum);

    save(videoname,'vid','-v6')
    
    setappdata(0,'lastvideo2',vid);
else
    % Wait for logging to finish
    while (vidobj2.FramesAcquired ~= vidobj2.DiskLoggerFrameCount) 
        pause(.1)
    end
end

fprintf('Data from camera 2 trial %03d successfully written to disk.\n',cam2.trialnum)


% Save trial number and time of trial to CSV 
fid = fopen([basename '.csv'],'a');

% We use the tmp.current_trial instead of metadata.cam.trialnum because
% metadata.cam.trialnum could be off by one if the camera 1 end of trial 
% callback fires before the camera2 callback. 
if strcmp(cam2.triggermode,'Sync trials')
   cam1_trialnum = tmp.current_trial;
else
    cam1_trialnum = -1;    
end

if fid > 0
    fprintf(fid, '%d, %d, %.4f\n', cam2.trialnum, cam1_trialnum, cam2.time);
end

fclose(fid);

cam2.trialnum = cam2.trialnum + 1;

% Tell TDT to stop trigger
TDT.setParameterValue('RZ5(1)','StartCam2',0);

setappdata(0,'cam2',cam2);