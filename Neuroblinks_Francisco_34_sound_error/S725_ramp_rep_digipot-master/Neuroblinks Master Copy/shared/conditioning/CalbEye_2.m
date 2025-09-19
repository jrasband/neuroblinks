function CalbEye_2(obj,event)
%  callback function by video(timer) obj
disp('Delivering puff and saving calibration data.')

vidobj_eye_2=getappdata(0,'vidobj_eye_2');
metadata=getappdata(0,'metadata');
src_eye_2=getappdata(0,'src_eye_2');

data=getdata(vidobj_eye_2,vidobj_eye_2.FramesPerTrigger*(vidobj_eye_2.TriggerRepeat + 1));

% Set camera to freerun mode so we can preview
%     src.TriggerMode = 'On';
src_eye_2.TriggerSource = 'Software';
%     src.TriggerSource = 'Line0';

% --- save data to root app ---
% Keep data from last trial in memory even if we don't save it to disk
setappdata(0,'lastdata_eye_2',data);
setappdata(0,'lastmetadata_eye_2',metadata);
setappdata(0,'calb_data_eye_2',data);
setappdata(0,'calb_metadata_eye_2',metadata);
fprintf('Data from last trial saved to memory for review.\n')

% metadata.stim.type='None';


% --- setting threshold ---
ghandles=getappdata(0,'ghandles');
ghandles.threshgui_eye_2=ThreshWindowWithPuff2; %REVISAR
setappdata(0,'ghandles',ghandles);
% 
% % Need to allow some time for GUI to draw before we call the lines below
% pause(2)

% Have to do the following 2 lines because we can't call drawhist and
% drawbinary directly from the ThreshWindow opening function since the
% ghandles struct doesn't exist yet. 
% threshguihandles=guidata(ghandles.threshgui2);
% ThreshWindowWithPuff('drawbinary',threshguihandles);


