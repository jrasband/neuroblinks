% Set up environment and launch app based on which version you want to use
function neuroblinks(varargin)
    % set this variable to 1 if you are going to use more than one camera
    % and neuroblink is not able to initialise (in this case you must switch
    % on the cameras in this order (first eye, second eye, body 1, body 2, etc.)
    camera_problem = 1;
    
    %disable the warning.
    warning('off','all') %turn off warning messages
    
    % Allowed devices to control the system
    ALLOWEDDEVICES = {'arduino','tdt'};

    % Default camera parameters (THIS PARAMETER CAN BE MODIFIED IN THE
    % NEUROBLINKS_CONFIG FILE
    metadata.multicams.N_eye_cams=1;
    metadata.multicams.eye_cam_index=[1];
    metadata.multicams.N_body_cams=0;
    metadata.multicams.body_cam_index=[];
    metadata.multicams.N_cams = metadata.multicams.N_eye_cams + metadata.multicams.N_body_cams;
    
    % Load local configuration for cameras and controllers
    % Should be somewhere in path but not "neuroblinks" directory or subdirectory
    neuroblinks_config
    
    % Check the cam number and their "positions" defined in "neuroblinks_config" file.
    % The number of eye cameras must be 1 or 2.
    if metadata.multicams.N_eye_cams < 1 || metadata.multicams.N_eye_cams > 2
        error(sprintf('The number of eye cams (metadata.multicams.N_eye_cams=%d) must be 1 or 2', metadata.multicams.N_eye_cams));
    end
    
    if metadata.multicams.N_eye_cams>length(metadata.multicams.eye_cam_index)
        error(sprintf('The number of eye cams (metadata.multicams.N_eye_cams=%d) must be smaller than or equal to the length of the eye cam index array (metadata.multicams.eye_cam_index), which is: %d', metadata.multicams.N_eye_cams, length(metadata.multicams.eye_cam_index)));
    end
    
    %The number of body cameras must be 0 or positive
    if metadata.multicams.N_body_cams < 0 || metadata.multicams.N_body_cams > 4
        error(sprintf('The number of body cams (metadata.multicams.N_body_cams=%d) must be between zero and four', metadata.multicams.N_body_cams));
    end
    
    if metadata.multicams.N_body_cams>length(metadata.multicams.body_cam_index)
        error(sprintf('The number of body cams (metadata.multicams.N_body_cams=%d) must be smaller than or equal to the length of the body cam index array (metadata.multicams.body_cam_index), which is: %d', metadata.multicams.N_body_cams, length(metadata.multicams.body_cam_index)));
    end
    
    % The number of used cameras must be smaller or equal to the number of defined serial
    % numbers.
    if metadata.multicams.N_cams > length(ALLOWEDCAMS)
        error(sprintf('The number of used cameras must be smaller or equal to the number of defined serial numbers.'));
    end
    
    %The camera index must be in between 1 and the number of defined serial numbers for cameras
    eye_and_body_cam_index = [metadata.multicams.eye_cam_index, metadata.multicams.body_cam_index];
    sorted_index = sort(eye_and_body_cam_index);
    if sorted_index(1) < 1 || sorted_index(end) > length(ALLOWEDCAMS)
        error(sprintf('The eye and body cam index values (metadata.multicams.eye_cam_index or metadata.multicams.body_cam_index) must take values between 1 and %d',length(ALLOWEDCAMS)));
    end
    
    for j=2:metadata.multicams.N_cams
       if sorted_index(j-1)==sorted_index(j)
            error(sprintf('All the eye and body cam index values must be different'));
       end
    end
    
    
    %We create an array with the serial number of the used cameras
    USEDCAMS = {};
    for j=1:metadata.multicams.N_eye_cams
        USEDCAMS{length(USEDCAMS)+1} = ALLOWEDCAMS{metadata.multicams.eye_cam_index(j)};
    end
    for j=1:metadata.multicams.N_body_cams
        USEDCAMS{length(USEDCAMS)+1} = ALLOWEDCAMS{metadata.multicams.body_cam_index(j)};
    end
   
    

    % Set up defaults in case user doesn't specify all options
    device = DEFAULTDEVICE;
    

    % Input parsing
    if nargin > 0
        for i=1:nargin
            if any(strcmpi(varargin{i},ALLOWEDDEVICES))
                device = varargin{i};
            end
        end
    end

    % Matlab is inconsistent in how it numbers cameras so we need to explicitely search for the right one
    disp('Finding camera...')

    if camera_problem == 1
        cams = 1:metadata.multicams.N_cams;
    else
        cams = zeros(1, metadata.multicams.N_cams);

        % Get list of configured cameras
        foundcams = imaqhwinfo('gentl');
        founddeviceids = cell2mat(foundcams.DeviceIDs);

        if isempty(founddeviceids)
            error('No cameras found')
        end

        if ~isempty(USEDCAMS)
            % This code doesn't work on some versions of Matlab so it's not working for you, you can
            % set ALLOWEDCAMS to an empty cell array in "neuroblinks_config"
            % and it will default to camera 1 (but then you can only have one
            % gige camera connected to your computer.
            for i=1:length(founddeviceids)
                vidobj = videoinput('gentl', founddeviceids(i), 'Mono8');
                src = getselectedsource(vidobj);
                for j=1:length(USEDCAMS)
                    if strcmp(src.DeviceSerialNumber,USEDCAMS{j})
                        cams(j) = founddeviceids(i);
                    end
                end
                delete(vidobj)
            end


            cams_error_index = 0;
            for i=1:length(USEDCAMS)
                if cams(i)==0
                    cams_error_index = i;
                end
            end
            if cams_error_index
                error(sprintf('The camera you specified (%d) could not be found',cams_error_index));
            end

        else
            cams = ones(1,1);
        end
    end
    
    try
        switch lower(device)
            case 'tdt'
                % TDT version
                % Set up path for this session
                [basedir,mfile,ext]=fileparts(mfilename('fullpath'));
                oldpath=addpath(genpath(fullfile(basedir,'tdt')));
                addpath(genpath(fullfile(basedir,'shared')));

            case 'arduino'

                % % Arduino version
                % % Set up path for this session
                [basedir,mfile,ext]=fileparts(mfilename('fullpath'));
                oldpath=addpath(genpath(fullfile(basedir,'arduino')));
                addpath(genpath(fullfile(basedir,'shared')));

            otherwise
                error(sprintf('Device %s not found', device))

        end
    catch
        error('You did not specify a valid device');
    end
    
    setappdata(0,'metadata',metadata)

    % A different "launch" function should be called depending on whether we're using TDT or Arduino
    % and will be determined by what's in the path generated above
    Launch(cams)
