function vidobj = addCam(serialNum)
% Create camera object for camera with given serial number
adaptor = 'gentl';

disp('Finding cameras...')

    % Get list of configured cameras
%     foundcams = imaqhwinfo('gige');
    foundcams = imaqhwinfo(adaptor);
    founddeviceids = cell2mat(foundcams.DeviceIDs); 

    if isempty(founddeviceids)
        error('No cameras found')
    end
    
    %====== Getting camera ID  =====
    match=0;
    
    for i=1:length(founddeviceids)
        vidobj = videoinput(adaptor, founddeviceids(i), 'Mono8');
        src = getselectedsource(vidobj);
        if strcmp(src.DeviceSerialNumber,serialNum)
            match=1;
            break
        end
        % If we get here the current camera didn't match
        delete(vidobj)
    end

    if ~match
        error('The camera you specified (%s) could not be found',serialNum);
    end