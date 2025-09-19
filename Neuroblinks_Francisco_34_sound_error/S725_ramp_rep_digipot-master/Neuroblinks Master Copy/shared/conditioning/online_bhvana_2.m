function online_bhvana_2(data_2)
% Eyelid trace is saved to memory (trials and metadata) even in no-save trial.

metadata=getappdata(0,'metadata');
trials=getappdata(0,'trials');
if isfield(trials,'eye_2'), if length(trials.eye_2)>metadata.eye_2.trialnum2+1, trials.eye_2=[]; end, end
if metadata.eye_2.trialnum2==1, trials.eye_2=[]; end

% ------ eyelid trace, which will be saved to 'trials' ---- 
[trace,time]=vid2eyetrace_2(data_2,metadata,metadata.cam_eye_2.thresh);
trace=(trace-metadata.cam_eye_2.calib_offset)/metadata.cam_eye_2.calib_scale;

trials.eye_2(metadata.eye_2.trialnum2).time=time*1e3;
trials.eye_2(metadata.eye_2.trialnum2).trace=trace;
trials.eye_2(metadata.eye_2.trialnum2).stimtype=lower(metadata.stim.type);
trials.eye_2(metadata.eye_2.trialnum2).isi=NaN;


trials.eye_2(metadata.eye_2.trialnum2).stimtime.st{1}=0; % for CS
trials.eye_2(metadata.eye_2.trialnum2).stimtime.en{1}=metadata.stim.c.csdur;
trials.eye_2(metadata.eye_2.trialnum2).stimtime.cchan(1)=3;
trials.eye_2(metadata.eye_2.trialnum2).stimtime.st{2}=metadata.stim.c.isi_eye_2+(metadata.stim.c.cs_addreps*metadata.stim.c.cs_period);
trials.eye_2(metadata.eye_2.trialnum2).stimtime.en{2}=metadata.stim.c.usdur_eye_2; % for US
trials.eye_2(metadata.eye_2.trialnum2).stimtime.cchan(2)=1;
trials.eye_2(metadata.eye_2.trialnum2).isi=metadata.stim.c.isi_eye_2+(metadata.stim.c.cs_addreps*metadata.stim.c.cs_period);
    

% --- this may be useful for offline analysis ----
metadata.eye_2.ts0=time(1)*1e3;
metadata.eye_2.ts_interval=mode(diff(time*1e3));
metadata.eye_2.trace=trace;


% --- save results to memory ----
setappdata(0,'trials',trials);
setappdata(0,'metadata',metadata);




