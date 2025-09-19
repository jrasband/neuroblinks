function discardtrial()

    %Clear the data from the first eye camera
    % Load objects from root app data
    vidobj=getappdata(0,'vidobj');
    

    pause(1e-3)
    % Clear data from the camera
    %getdata(vidobj,vidobj.FramesPerTrigger*(vidobj.TriggerRepeat + 1));
    if vidobj.FramesAvailable > 0        
        getdata(vidobj,vidobj.FramesAvailable);
    end
    pause(1e-3)
    
    %Clear the data from the second eye camera
    metadata = getappdata(0,'metadata');
    if metadata.multicams.N_eye_cams == 2
        % Load objects from root app data
        vidobj_eye_2=getappdata(0,'vidobj_eye_2');
 
        pause(1e-3)
        % Clear data from the camera
        %getdata(vidobj_eye_2,vidobj_eye_2.FramesPerTrigger*(vidobj_eye_2.TriggerRepeat + 1));
        if vidobj_eye_2.FramesAvailable > 0        
            getdata(vidobj_eye_2,vidobj.FramesAvailable);
        end
        pause(1e-3)
    end
    
    %Clear the data from the body cameras
    if metadata.multicams.N_body_cams > 0
        for body_cam_index = 1:metadata.multicams.N_body_cams
            % Load objects from root app data
            vidobj_body_x=getappdata(0,['vidobj_body_' num2str(body_cam_index)]);

            pause(1e-3)
            % Clear data from the camera
            %getdata(vidobj_body_x,vidobj_body_x.FramesPerTrigger*(vidobj_body_x.TriggerRepeat + 1));
            if vidobj_body_x.FramesAvailable > 0        
                getdata(vidobj_body_x,vidobj.FramesAvailable);
            end
            pause(1e-3)
        end
    end

    % clear encoder data from Arduino
    if isappdata(0,'arduino')
      arduino = getappdata(0,'arduino');

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

      %sEND THE MESSAGE TO RECIVE THE ENCODER INFORMATION
      fwrite(arduino,2,'int8');

	  %Second encoder (DIFFERENTIAL ENCODER)
	  data_header=(fread(arduino,1,'uint8'));
	  if data_header == 100
	     N_data_values = fread(arduino,1,'int16');
	     fread(arduino,1,'int32');
	     fread(arduino,N_data_values,'int8');%differential values (including the first sample, which will be always 0)
	  end

	  time_header=(fread(arduino,1,'uint8'));
	  if time_header == 101
	     N_time_values = fread(arduino,1,'int16');
	     fread(arduino,1,'int32');
	     fread(arduino,N_time_values,'int8');
	  end
    end
    
    
    fprintf('Data from aborted trial %03d discarded.\n',metadata.cam.trialnum)
