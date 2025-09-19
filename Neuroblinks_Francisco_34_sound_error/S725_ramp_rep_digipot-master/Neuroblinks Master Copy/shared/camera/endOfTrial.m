function endOfTrial(obj,event)
% This function is run when the camera is done collecting frames, then it calls the appropriate
% function depending on whether or not data should be saved

trial_aborted = getappdata(0,'trial_aborted');
if (trial_aborted)
    discardtrial();
else
    incrementStimTrial();
    savetrial();
end


% Set the second eye camera to freerun mode so we can preview
metadata = getappdata(0,'metadata');
if metadata.multicams.N_eye_cams == 2
    ghandles=getappdata(0,'ghandles');
    handles_secondeyegui=guidata(ghandles.secondeyegui);
    vidobj_eye_2=getappdata(0,'vidobj_eye_2');
    src_eye_2=getappdata(0,'src_eye_2');
    %%%%%%%%%%%%%%%%%%%%%%%
    stoppreview(vidobj_eye_2);
    stop(vidobj_eye_2);
    %%%%%%%%%%%%%%%%%%%%%%%
    src_eye_2.TriggerMode='Off';
    preview(vidobj_eye_2,handles_secondeyegui.pwin2);
end

% Set the first body camera to freerun mode so we can preview
if metadata.multicams.N_body_cams > 0
    for body_cam_index = 1:metadata.multicams.N_body_cams
        ghandles=getappdata(0,'ghandles');
        handles_bodycameragui=guidata(ghandles.bodycameragui{body_cam_index});
        vidobj_body_x=getappdata(0,['vidobj_body_' num2str(body_cam_index)]);
        src_body_x=getappdata(0,['src_body_' num2str(body_cam_index)]);
        %%%%%%%%%%%%%%%%%%%%%%%
        stoppreview(vidobj_body_x);
        stop(vidobj_body_x);
        %%%%%%%%%%%%%%%%%%%%%%%
        src_body_x.TriggerMode='Off';
        preview(vidobj_body_x,handles_bodycameragui.pwin3);
    end
end



% Set the first eye camera to freerun mode so we can preview
%Restore the preview configuration in the main windows.
ghandles=getappdata(0,'ghandles');
handles_maingui=guidata(ghandles.maingui);
vidobj=getappdata(0,'vidobj');
src=getappdata(0,'src');

%%%%%%%%%%%%%%%%%%%%%%%
stoppreview(vidobj);
stop(vidobj);
%%%%%%%%%%%%%%%%%%%%%%%
src.TriggerMode='Off';
preview(vidobj,handles_maingui.pwin);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%autoupdate the "OneTrialAnaWindowsBothEyes" with the new trial
ghandles=getappdata(0,'ghandles');
if isfield(ghandles,'onetrialanagui') && isvalid(ghandles.onetrialanagui)
    handles=guidata(ghandles.onetrialanagui);
    if get(handles.autoupdate, 'value')
        trials=getappdata(0,'trials');
        set(handles.edit_trialnum,'String',num2str(trials.stimnum))
        figure(handles.figure1)
        handles.edit_trialnum_Callback(handles.output, 0, handles)
    end
end



function incrementStimTrial()
trials=getappdata(0,'trials');
trials.stimnum=trials.stimnum+1;
setappdata(0,'trials',trials);
