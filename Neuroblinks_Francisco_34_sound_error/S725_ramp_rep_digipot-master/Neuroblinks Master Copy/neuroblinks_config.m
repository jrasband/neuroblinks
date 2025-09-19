% Configuration settings that might be different for different users/computers
% Should be somewhere in path but not "neuroblinks" directory or subdirectory

metadata.multicams.N_eye_cams=1;
metadata.multicams.eye_cam_index=[1];
metadata.multicams.N_body_cams=0;
metadata.multicams.body_cam_index=[2];
metadata.multicams.N_cams = metadata.multicams.N_eye_cams + metadata.multicams.N_body_cams;


%Seial number of all the cameras that are going to be used. 
%ALLOWEDCAMS = {'671089396'}; %serial number for cameras S025
%ALLOWEDCAMS = {'671093011'}; %serial number for cameras S022
%ALLOWEDCAMS = {'671093011', '671094318'}; %serial number for cameras S022
ALLOWEDCAMS = {'671093019', '671094315', '14158', '14159'}; %serial number for cameras S022


%default device used to control de system
DEFAULTDEVICE = 'arduino';



%% END MODIFICATION
%ARDUINO_IDS = {'75735303431351607231','757353034313518030C0'};
%ARDUINO_IDS = {'757353034313518030C0','75735303431351A0C100'}; % temp test S025
%ARDUINO_IDS = {'550373130373516051F2'}; % temp test S022
%ARDUINO_IDS = {'550373130373516051F2'}; % board in box JR02 2024-08-14
ARDUINO_IDS = {'34239313335351F021B2'}; % board in box JR02 2025-05-22
%ARDUINO_IDS = {'7573530343135140A052'}; % board used for testing tone generation
% COM4 - Arduino LLC (www.arduino.cc) - USB VID:PID=2341:003D
% COM15 - Arduino Srl (www.arduino.org) - USB\VID_2A03&PID_003D\7&1F0EA464&0&3
% COM14 - Arduino LLC (www.arduino.cc) - USB\VID_2341&PID_003D\7&1F0EA464&0&2

% COM2 - Arduino Srl (www.arduino.org) - USB\VID_2A03&PID_003D\FFFFFFFFFFFF513B2506
% COM5 - Arduino LLC (www.arduino.cc) - USB\VID_2341&PID_003D\75330303035351B061B2

% NOTE: In the future this should be dynamically set based on pre and post time
%metadata.cam.recdurA=1000;
%metadata.cam_eye_2.recdurA=1000; %%%%%%BORRAR

% --- camera settings ----
metadata.cam.init_ExposureTime=4840.0;
%metadata.cam_eye_2.init_ExposureTime=4899.997000; %%%%%%BORRAR




% TDT tank -- not necessary for Arduino version
tank='optoelectrophys'; % The tank should be registered using TankMon (really only matters for TDT version)

% GUI
% -- specify the location of bottomleft corner of MainWindow & AnalysisWindow  --
ghandles.pos_mainwin=[5 50];      ghandles.size_mainwin=[840 650];
ghandles.pos_secondeye=[5 680];   ghandles.size_secondeye=[750 310];
ghandles.pos_bodycamera{1}=[845 50];   ghandles.size_bodycamera{1}=[375 350];
ghandles.pos_bodycamera{2}=[845 450];   ghandles.size_bodycamera{2}=[375 350];
ghandles.pos_bodycamera{3}=[1220 50];   ghandles.size_bodycamera{3}=[375 350];
ghandles.pos_bodycamera{4}=[1220 450];   ghandles.size_bodycamera{4}=[375 350];
ghandles.pos_anawin= [570 45];    ghandles.size_anawin=[1030 840]; 
ghandles.pos_oneanawin=[5 45];    ghandles.size_oneanawin=[560 380];   
ghandles.pos_lfpwin= [570 45];    ghandles.size_lfpwin=[600 380];