% function [] = camsetup(varargin)

clc; close all; clear;

total_trials = 10;

framesPerTrial = 3;


%% PREALLOCATE DATA COLLECTORS

imSizeX = 1280;
imSizeY = 720;


trial_data.tone_start = [];
trial_data.tone_end = [];

FramesTS = {};
ff = 1;

% Frames{1} = uint8(zeros(imSizeY,imSizeX,3));
% for nn = 1:length(trial_data)*8
%     Frames{nn} = uint8(zeros(imSizeY,imSizeX));
% end


Frames{1} = zeros(imSizeY,imSizeX,3);
for nn = 1:length(trial_data)*8
    Frames{nn} = zeros(imSizeY,imSizeX,3);
end

%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);

vidObj.LoggingMode = 'memory';

vidObj.ReturnedColorspace = 'rgb';
% vidObj.ReturnedColorspace = 'grayscale';


vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);



%% START IMAGE ACQUISITION LOOP

% threshmask = .50;

threshmask = 200;


xy=[0 0];

tic
for trial = 1:total_trials
    
    fprintf('\n Starting trial: %d \n', trial);
        
    % Get timing of trial start
    trial_data.tone_start(trial,1) = toc;
    
    for nn = 1:framesPerTrial
        
        pause(.5)
        trigger(vidObj);
        [frame, ts] = getdata(vidObj, vidObj.FramesPerTrigger);
        
        FramesTS{end+1} = ts;
        
        
        IMG = rgb2gray(frame);
        IMG = im2double(IMG);
        
        Frames{ff} = IMG; 
        
        		
        [ii,jj,val] = find(IMG); 
        IJV = [ii,jj,val];
        
        [E, index] = sortrows(IJV,-3);

        xy(ff,:) = [mean(E(1:50,2)) imSizeY-mean(E(1:50,1))];
        
        ff=ff+1;
    end
    

    % send_to_daq('solenoid_1',.015);

    % Get timing of trial end
    trial_data.tone_end(trial,1) = toc;
    
    fprintf('\n Ending trial: %d \n', trial);
    
end

stop(vidObj); 
wait(vidObj);

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end

%% Save data

% outfile=sprintf('FC_Day1_s%s_%s.mat', subject_id, date);
% save([sub_dir, '/' outfile],'trial_data', 'Frames', 'FramesTS', 'FrameOrd');

%% PLAYBACK THERMAL VIDEO FRAMES & SAVE DATA
close all
for nn = 1:numel(Frames)
    figure(2)
    imagesc(Frames{nn})
    axis image
    drawnow
    pause(.1)
end


%% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy
close all

fh1=figure('Units','normalized','OuterPosition',[.1 .1 .6 .7],'Color','w','MenuBar','none');

hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[]);
hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren');
axis off; hold on;


% hax1=axes('Position',[.07 .1 .8 .8],'Color','none','NextPlot','replacechildren');
% hax2=axes('Position',[.07 .1 .8 .8],'Color','none','NextPlot','replacechildren');


    axes(hax1)
    imagesc(Frames{2})
    set(gca,'YDir','reverse')
    hold on
    
    axLims = axis;
    
    axes(hax2)
    scatter(xy(1,1),xy(1,2),100,'filled','MarkerFaceColor',[.9 .1 .1]);
    axis(axLims)
    hold on
    


for nn=1:numel(Frames)
    
    delete(hax1.Children); delete(hax2.Children);
    
    imagesc(Frames{nn},'Parent', hax1)
    
    scatter(hax2, xy(nn,1),xy(nn,2),100,'filled','MarkerFaceColor',[.9 .1 .1]);
    axis(axLims)
    % hold on
    
    pause(.2)
    
end

%%
% end


% SAVE IMAGE ACQUISITION NOTES
%{

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
% src.AnalogVideoFormat = 'ntsc_m_j';

% vidObj.FramesPerTrigger = 1;
% preview(vidObj);
% start(vidObj);
% pause(5)
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vid src
% vidsrc = getselectedsource(vidObj);
% diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'memory';
% vidObj.DiskLogger = file;
% vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
% main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');












% imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID

utilpath = fullfile(matlabroot, 'toolbox', 'imaq', 'imaqdemos', 'helper');
addpath(utilpath);
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720');
vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
% src.AnalogVideoFormat = 'ntsc_m_j';

% vidObj.FramesPerTrigger = 1;
% preview(vidObj);
% start(vidObj);
% pause(5)
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vid src
% vidsrc = getselectedsource(vidObj);
% diskLogger = VideoWriter([thisFolder '/thermalVid1.avi'],'Uncompressed AVI');
vidObj.LoggingMode = 'memory';
% vidObj.DiskLogger = file;
% vidObj.ROIPosition = [488 95 397 507];
vidObj.ReturnedColorspace = 'rgb';
% vidObjSource = vidObj.Source;
% preview(vidObj);    pause(3);   stoppreview(vidObj);
% TriggerRepeat is zero-based
vidObj.TriggerRepeat = total_trials * 6 + 6;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);
% stop(vidObj);
% stoppreview(vidObj);
% delete(vidObj);
% clear vidObj

% Once a key is pressed, the experiment will begin
% main_keyboard_index = input_device_by_prompt('Please press any key on the main keyboard\n', 'keyboard');
disp('Starting experiment now...');


Frames{1} = uint8(zeros(480,720,3));
for nn = 1:length(trial_data)*8
    Frames{nn} = uint8(zeros(480,720,3));
end

Frames = {};            % create thermal vid frame container
FramesTS = {};          % create thermal vid timestamp container
startTime = GetSecs;
ff=1;

%}























