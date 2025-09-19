function ResetCamTrials()

metadata=getappdata(0,'metadata');
trials=getappdata(0,'trials');

metadata.cam.trialnum=1;
metadata.eye.trialnum1=1;
metadata.eye.trialnum2=1;
% trials.tnum=1;

if metadata.multicams.N_eye_cams == 2
    metadata.cam_eye_2.trialnum=1;
    metadata.eye_2.trialnum1=1;
    metadata.eye_2.trialnum2=1;   
end

trials.stimnum=0;

setappdata(0,'metadata',metadata);
setappdata(0,'trials',trials);