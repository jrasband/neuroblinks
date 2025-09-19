function savetrial()
% 4096 counts = 1 revolution = 15.24*pi cm for 6 inch diameter cylinder
counts2cm = @(count) double(count) ./ 4096 .* 20.30 .* pi; %Wheel diameter in cm
%counts2cm = @(count) double(count) ./ 4096 .* 20.30 .* pi; %Wheel diameter in cm


% Load objects from root app data
vidobj=getappdata(0,'vidobj');

pause(1e-3)
% data=getdata(vidobj,vidobj.TriggerRepeat+1);
data=getdata(vidobj,vidobj.FramesPerTrigger*(vidobj.TriggerRepeat + 1));
% videoname=sprintf('%s\\%s_%s_%03d',metadata.folder,metadata.mouse,datestr(now,'yy-mm-dd'),metadata.trialnum);
pause(1e-3)

online_bhvana(data);
setappdata(0,'lastdata',data);


%Save the data from the second eye camera
metadata = getappdata(0,'metadata');
if metadata.multicams.N_eye_cams == 2
    % Load objects from root app data
    vidobj_eye_2=getappdata(0,'vidobj_eye_2');

    pause(1e-3)
    % data=getdata(vidobj,vidobj.TriggerRepeat+1);
    data_eye_2=getdata(vidobj_eye_2,vidobj_eye_2.FramesPerTrigger*(vidobj_eye_2.TriggerRepeat + 1));
    % videoname=sprintf('%s\\%s_%s_%03d',metadata.folder,metadata.mouse,datestr(now,'yy-mm-dd'),metadata.trialnum);
    pause(1e-3)

    online_bhvana_2(data_eye_2);
    setappdata(0,'lastdata_eye_2',data_eye_2);

end

%Save the data from the body cameras
if metadata.multicams.N_body_cams > 0
    for body_cam_index = 1:metadata.multicams.N_body_cams
        % Load objects from root app data
        vidobj_body_x{body_cam_index}=getappdata(0,['vidobj_body_' num2str(body_cam_index)]);

        pause(1e-3)
        % data=getdata(vidobj,vidobj.TriggerRepeat+1);
        data_body_x{body_cam_index}=getdata( vidobj_body_x{body_cam_index},  vidobj_body_x{body_cam_index}.FramesPerTrigger*( vidobj_body_x{body_cam_index}.TriggerRepeat + 1));
        % videoname=sprintf('%s\\%s_%s_%03d',metadata.folder,metadata.mouse,datestr(now,'yy-mm-dd'),metadata.trialnum);
        pause(1e-3)

        setappdata(0,['lastdata_body_' num2str(body_cam_index)],data_body_x{body_cam_index});
    end
end


metadata = getappdata(0,'metadata');
setappdata(0,'lastmetadata',metadata);
if metadata.multicams.N_eye_cams == 2
      setappdata(0,'lastmetadata_eye_2',metadata);
end


% Get encoder data from Arduino
if isappdata(0,'arduino')
  arduino = getappdata(0,'arduino');
  metadata=getappdata(0,'metadata');

  %this function is executed when the camara finishs the recording, but the trial
  %duration could be longer due to the motor. In that case, we must wait
  %until the motor finishes to read the encoder data from arduino.
  total_cam_time = sum(metadata.cam.time);
  motor_finish = metadata.stim.motor.delay + metadata.stim.motor.dur;
  waiting_time = motor_finish - total_cam_time;
  if waiting_time > 0
     pause(waiting_time/1000.0)
  end


  if arduino.BytesAvailable > 0
    fread(arduino, arduino.BytesAvailable); % Clear input buffer
  end

  %TESTING THE COMMUNICATION WITH ARDUINO, SENDING THE VALUE 0 AND WAITING
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
      disp('ARDUINO BOARD HAS BEEN RESET AFTER THE TRIALS DUE TO A PROBLEM WITH THE COMMUNICATION')
  end

  %SEND THE MESSAGE TO RECIVE THE ENCODER INFORMATION
  fwrite(arduino,2,'int8');

  %Encoder (DIFFERENTIAL ENCODER)
  data_header=(fread(arduino,1,'uint8'));
  while isempty(data_header)
      data_header=(fread(arduino,1,'uint8')); %wait until arduino send the encoder.
  end

  if data_header == 100
      %Number of values that arduino is going to send
     N_data_values = fread(arduino,1,'int16');
     %first global value used to reconstruct the final values
     first_data_value = fread(arduino,1,'int32');
     %Array containing the encoder values codified with a differential method. Each value is
     %codified as the difference with respect to the previous value, including the first value,
     %which will be always 0. Using these values and the first global value is possible to
     %reconstruct the original values (THIS STRUCTURE ALLOW TO ARDUINO TO USE LESS RAM MEMORY
     %TO STORE THE SAME NUMBER OF ENCODER VALUES)
     differential_counts = fread(arduino,N_data_values,'int8');%differential values (including the first sample, which will be always 0)
     %The final encoder values are reconstructed.
     encoder.counts=cumsum(differential_counts)+first_data_value;
     encoder.displacement=counts2cm(encoder.counts-encoder.counts(1));
  end

  time_header=(fread(arduino,1,'uint8'));
  if time_header == 101
     N_time_values = fread(arduino,1,'int16');
     first_time_value = fread(arduino,1,'int32');
     differential_time = fread(arduino,N_time_values,'int8');
     encoder.time = cumsum(differential_time) + first_time_value;
     encoder.time=encoder.time-encoder.time(1);
  end

end

% --- saved in HDD ---

%with the -v6 option, the saved file is compressed and smaller, but the CPU requires more time
%to generate the output file
fast_saving_option = getappdata(0,'fast_saving_option');
if fast_saving_option == 1
    saving_option = '-v6';
else
    saving_option = '';
end

videoname=sprintf('%s\\%s_%03d',metadata.folder,metadata.TDTblockname,metadata.cam.trialnum);

save(videoname,'data','metadata', saving_option)
if exist('encoder','var')
    save(videoname,'encoder','-append', saving_option)
end

if metadata.multicams.N_eye_cams == 2
    save(videoname,'data_eye_2','-append', saving_option)
end


if metadata.multicams.N_body_cams > 0
    for body_cam_index = 1:metadata.multicams.N_body_cams
        switch(body_cam_index)
            case 1
                data_body_1 = data_body_x{body_cam_index};
                save(videoname,'data_body_1','-append', saving_option)
            case 2
                data_body_2 = data_body_x{body_cam_index};
                save(videoname,'data_body_2','-append', saving_option)
            case 3
                data_body_3 = data_body_x{body_cam_index};
                save(videoname,'data_body_3','-append', saving_option)
            case 4
                data_body_4 = data_body_x{body_cam_index};
                save(videoname,'data_body_4','-append', saving_option)
            case 5
                data_body_5 = data_body_x{body_cam_index};
                save(videoname,'data_body_5','-append', saving_option)
        end
    end
end

% save(videoname,'metadata')
% if exist('encoder','var')
%     save(videoname,'data','metadata','encoder','-v6')
% else
%     save(videoname,'data','metadata','-v6')
% end
%
% if metadata.multicams.N_eye_cams == 2
%     videoname2=sprintf('%s\\%s_%03d_second_eye',metadata.folder,metadata.TDTblockname,metadata.cam.trialnum);
%     save(videoname2,'data_2','-v6')
% end

fprintf('Data from trial %03d successfully written to disk.\n',metadata.cam.trialnum)


% --- trial counter updated and saved in memory ---
metadata.cam.trialnum=metadata.cam.trialnum+1;
if strcmpi(metadata.stim.type,'conditioning') | strcmpi(metadata.stim.type,'electrocondition')
    metadata.eye.trialnum1=metadata.eye.trialnum1+1;
end
metadata.eye.trialnum2=metadata.eye.trialnum2+1;

if metadata.multicams.N_eye_cams == 2
    metadata.cam_eye_2.trialnum=metadata.cam_eye_2.trialnum+1;
    if strcmpi(metadata.stim.type,'conditioning') | strcmpi(metadata.stim.type,'electrocondition')
        metadata.eye_2.trialnum1=metadata.eye_2.trialnum1+1;
    end
    metadata.eye_2.trialnum2=metadata.eye_2.trialnum2+1;
end

setappdata(0,'metadata',metadata);
%
% % --- online spike saving, executed by timer ---
% etime1=round(1000*etime(clock,t0))/1000;
% tm1 = timer('TimerFcn',@online_savespk_to_memory, 'startdelay', max(0, 4-etime1));
% start(tm1);
%
