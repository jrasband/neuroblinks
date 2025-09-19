function Launch(cams)

    % Load local configuration 
    % Should be somewhere in path but not "neuroblinks" directory or subdirectory
    neuroblinks_config;	% Per user settings
%    configure; % Configuration script

    %% Initialize cameras
    InitCam(cams); % src and vidobj are now saved as root app data so no global vars

        
    %% -- start serial communication to arduino ---
    disp('Finding Arduino...')
    com_ports = findArduinos(ARDUINO_IDS);

    if isempty(com_ports{1}),
        error('No Arduino found for requested rig (%d)', rig);
    end

    arduino=serial(com_ports{1},'BaudRate',115200);
    arduino.InputBufferSize = 60000 * 4; % up to 300 s of encoder data
    % arduino.DataTerminalReady='off';	% to prevent resetting Arduino on connect
    try
        fopen(arduino);
    catch %%if the port wasn't cleared earlier, close ports and try again
        s=instrfind('Status','Open');    
        if ~isempty(s)
            fclose(s);
        end
        fopen(arduino);
    end
    setappdata(0,'arduino',arduino);


    %% Open GUI for main windows (first eye)
    clear MainWindow;    % Need to do this to clear persistent variables defined within MainWindow and subfunctions
    ghandles.maingui=MainWindow;
    set(ghandles.maingui,'units','pixels')
    set(ghandles.maingui,'position',[ghandles.pos_mainwin ghandles.size_mainwin])

    % Open GUI for second eye window (second eye)
    if  metadata.multicams.N_eye_cams == 2
        ghandles.secondeyegui=SecondEyeWindows;
        set(ghandles.secondeyegui,'units','pixels')
        set(ghandles.secondeyegui,'position',[ghandles.pos_secondeye ghandles.size_secondeye])
    end
    
    % Open GUI for additional body window (body cameras)
    for j=1:metadata.multicams.N_body_cams
        ghandles.bodycameragui{j}=BodyCamWindow(j);
        set(ghandles.bodycameragui{j},'units','pixels')
        set(ghandles.bodycameragui{j},'position',[ghandles.pos_bodycamera{j} ghandles.size_bodycamera{j}])
        
    end
    
   
    % Save handles to root app data
    setappdata(0,'ghandles',ghandles)



function com_ports = findArduinos(ids)
    com_ports = cell(size(ids));

    % Call external function 'wmicGet' to pull in PnP info
    infostruct = wmicGet('Win32_PnPEntity');

    names={infostruct.Name};  % roll struct field into cell array for easy searching
    device_ids={infostruct.DeviceID};  % roll struct field into cell array for easy searching

    %match = strfind(names,'Arduino');   % All devices with "Arduino" in the name field
    match = strfind(device_ids,ids);
    idx = find(~cellfun(@isempty,match));

    if isempty(idx)
        return
    end

    arduino_names = names(idx);
    arduino_device_ids = device_ids(idx);

    for i=1:length(ids)
        % Figure out which line the ID appears on...
        match = strfind(arduino_device_ids,ids{i});
        idx = find(~cellfun(@isempty,match));
        if ~isempty(idx)
            %...and find the corresponding COM port on that line
            com_ports{i} = regexp(arduino_names(idx),'(COM\d+)','match','once');
        end
    end




