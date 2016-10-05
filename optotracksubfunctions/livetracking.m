function [memos] = livetracking(mainguih, haxMAIN, tri, fpt, pxt, np, headrad, trackhead, memos, memoboxH)
% clc; close all; clear;






%% NAMEING THIS SECTION HEADER

ta = createDAQtimerA;
tb = createDAQtimerB;





for n = 1:100

    start(ta);

    if n >= 40 && n < 60
        stop(ta);
        start(tb);
    end

    if n >= 60
        stop(tb);
        start(ta);
    end

    pause(.1)
end


%% USER-ENTERED PARAMETERS

total_trials = tri;

framesPerTrial = fpt;

threshmask = pxt;

npixels = np;  % Number of 'hot' pixels to average to find center

nmasks = 2;

%% GET SINGLE CAMERA FRAME TO SET ROI MASKS

[masks, IMG, memos] = setROIframe(nmasks, haxMAIN, memos, memoboxH);


%% MAKE PULSE PATTERNS

% PP(1).Pnum   = 2;          % (int) number of different pulse patterns to generate
% PP(1).ResHz  = 250;        % (ms)  pulse sampling rate
% PP(1).Type   = 'square';   % (str) wave type: 'square' or 'sine'
% PP(1).FreqHz = 10;         % (int) number of pulses per second
% PP(1).Time   = 5;          % (sec) total length of time pulses are generated
% PP(1).Volts  = 5;          % (dub) output voltage maximum pulse amplitude
% PP(1).Phase  = 0;          % (rad) phase to start sine wave pulse
% PP(1).PLen   = 0;          % (ms)  single square wave pulse on-duration (< 1/FreqHz)
% PP(1).PDelay = 0;          % (ms)  delay between square wave pulse bursts (< FreqHz*PLen)
% PP(1).xT = [];             % generated: X-axis timepoints
% PP(1).yV = [];             % generated: Y-axis voltage amplitude values

global PP

PP(1).Pnum     = 2;
PP(1).ResHz    = 250;
PP(1).Type     = 'square';
PP(1).FreqHz   = 10;
PP(1).Time     = 5;
PP(1).Volts    = 5;
PP(1).Phase    = 0;
PP(1).PLen     = 1 / PP(1).FreqHz / 2 * 1000;
PP(1).PDelay   = 0;
PP(1).xT       = [];
PP(1).yV       = [];

PP(2).Pnum     = 2;
PP(2).ResHz    = 250;
PP(2).Type     = 'sine';
PP(2).FreqHz   = 10;
PP(2).Time     = 5;
PP(2).Volts    = 5;
PP(2).Phase    = 0;
PP(2).PLen     = 0;
PP(2).PDelay   = 0;
PP(2).xT       = [];
PP(2).yV       = [];


[Pulses] = makePulses(PP);




%% ACQUIRE DAQ OBJECT AND TEST

global lbj

lbj=labJackU6;

% devInfo = getInfo(lbj);
% disp(lbj); disp(devInfo);
% pause(.2)

open(lbj); pause(.2);

lbj.SampleRateHz = Pulses(1).ResHz * 4;

lbj.verbose = 0; % 0 or 1

addChannel(lbj,[0 1],[10 10],['s' 's']);
channel = 1; % 0 or 1

streamConfigure(lbj); pause(.2);
startStream(lbj);

analogOut(lbj,channel,0)

for t = 1 : Pulses(1).Time * Pulses(1).ResHz

    analogOut(lbj,channel,Pulses(1).yV(t));

    pause(1/Pulses(1).ResHz)

end


for t = 1 : Pulses(2).Time * Pulses(2).ResHz

    analogOut(lbj,channel,Pulses(2).yV(t));

    pause(1/Pulses(2).ResHz)

end

voltageSet = 0;
analogOut(lbj,channel,voltageSet)
% stopStream(lbj);
% clear lbj

% x = 1;
% while t > 0
% 
%     
%     analogOut(lbj,channel,Pulses(2).yV(x));
% 
%     pause(1/Pulses(2).ResHz)
%     x = x+1;
%     
%     if x == numel(Pulses(2).yV)
%         x = 1;
%     end
%     
% end
% 
% 
% analogOut(lbj,channel,0);



%% 

job = batch('evokedaq');

s = 'Hi Reddit! Look I can still run this loop while the pulse loop is executing.';

for t = 1:numel(s)
    
    fprintf('% s', s(t))
    
    pause(.1)

end
disp(' ')




NumFncOutputs = 1;
daqjob = batch('evokedaq',NumFncOutputs,{lbj,Pulses(1)});

delete(daqjob)
clear('daqjob')
cancel(daqjob)
cancel(job)

%% PREALLOCATE DATA COLLECTORS

FpS = 10;
ExpLengthSeconds = 60;
TotalFrames = ExpLengthSeconds*FpS;

imSizeX = size(IMG,2);
imSizeY = size(IMG,1);

FramesTS = [];

Frames = zeros(imSizeY,imSizeX,TotalFrames);

ff = 1;

%% ACQUIRE IMAGE ACQUISITION DEVICE (THERMAL CAMERA) OBJECT

vidPos = [320 130 640 460];
imageType = 'rgb';
% imageType = 'grayscale';

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
vidObj.ReturnedColorspace = imageType;
vidObj.ROIPosition = vidPos;

vidObj.ReturnedColorspace = imageType;
vidObj.ROIPosition = vidPos;

vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');

start(vidObj);


%% START IMAGE ACQUISITION LOOP

xy=[0 0];

tictoc = (1:framesPerTrial) .* 0;

% profile on

tic
memos = memologs(memos, memoboxH, ['tic: ' num2str(toc)]);
for trial = 1:total_trials
    
    % fprintf('\n Starting trial: %d \n', trial);
        
    % Get timing of trial start
    % trial_data.tone_start(trial,1) = toc;
    
    for nn = 1:framesPerTrial
        

        % pause(.001)

        trigger(vidObj);
        [frame, ~] = getdata(vidObj, vidObj.FramesPerTrigger);
        
        % FramesTS(end+1) = ts;
        
        
        IMG = rgb2gray(frame);
        IMG = im2double(IMG);
        
        
        % Frames(:,:,ff) = IMG;
        
        
        % GET HEAD PIXELS OF SUBJECT
        if trackhead
            
            headmask = findsubject(IMG, threshmask, headrad, imsz);
        

            
            
            
%             % ---- Delete this after we get everything working
%              anypixels = sum(sum(headmask .* STIM_region));
%             ph1.CData = IMG .* STIM_region;
%             
%             [row,col,val] = find(headmask); 
%             RCV = [row,col,val];
%             [YXv, index] = sortrows(RCV,-3);
%             xcol = mean( YXv(:,2) );
%             yrow = mean( imSizeY - YXv(:,1) );
%             
%             ph2.XData = xcol;
%             ph2.YData = yrow;
%             memos = memologs(memos, memoboxH, ['Any pixels in ROI?: ' num2str(anypixels)]);
%             drawnow
%             pause(.001)
%             % ----
                                
        else
            
            % FIND ALL NON-ZERO PIXELS (PIXELS ABOVE THRESHOLD)
            [row,col,val] = find(IMG); 
            RCV = [row,col,val];
            
        
            % SORT BY PIXEL BRIGHTNESS (HIGH TO LOW)
            [YXv, index] = sortrows(RCV,-3); 

            % GET THE COLUMN (X) AND ROW (Y) INDEX OF THE HOTTEST PIXELS
            % MEAN OF THOSE PIXEL COORDINATES IS GEOMETRIC CENTER
            xcol = mean( YXv(1:npixels,2) );

            yrow = mean( imSizeY - YXv(1:npixels,1) );
            % yrow = mean( YXv(1:npixels,1) );

            xy(ff,:) = [xcol yrow];
            
        end
        
        
        
        evokedaq(ROIn, lbj, channel, SampleRateHz, yv)
        
        
        
        % memos = memologs(memos, memoboxH, ['toc: ' num2str(toc)]);
        % disp(num2str(toc))
        
        tictoc(nn) = toc;
        
        ff=ff+1;
    end
    

    % send_to_daq('solenoid_1',.015);    
    % fprintf('\n Ending trial: %d \n', trial);
    
end

stop(vidObj); 
wait(vidObj);

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end


disp(tictoc')

memos = memologs(memos, memoboxH, ['tic: ' num2str(tictoc(end))]);


%% Save data

% outfile=sprintf('FC_Day1_s%s_%s.mat', subject_id, date);
% save([sub_dir, '/' outfile],'trial_data', 'Frames', 'FramesTS', 'FrameOrd');

% profile viewer






%% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy

if ~trackhead

    figure(mainguih);

    % hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren');
    % hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
    % hax3 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
    % axis off; hold on;

    axes(haxMAIN)
    ph1 = imagesc(Frames(:,:,1));
    set(gca,'YDir','reverse')
    haxMAIN.XLim = [1 size(IMG,2)];
    haxMAIN.YLim = [1 size(IMG,1)];
    hold on

    axLims = axis;

    % axes(hax2)
    ph2 = scatter(xy(1,1),xy(1,2),100,'filled','MarkerFaceColor',[.9 .1 .1]);
    axis(axLims)
    hold on


    % axes(hax3)
    ph3 = plot(xy(1,1),xy(1,2),'r');
    axis(axLims)
    hold on


    t = (1:size(xy,1));
    ts = linspace(1, size(xy,1), size(xy,1)*100 );
    xys = spline(t,xy',ts)';

    mm=1;
    for nn=1:size(Frames,3)

        ph1.CData = Frames(:,:,nn);
        ph2.XData = xy(nn,1);
        ph2.YData = xy(nn,2);
        % ph3.XData = xy(1:nn,1);
        % ph3.YData = xy(1:nn,2);
        ph3.XData = xys(1:mm,1);
        ph3.YData = xys(1:mm,2);

        pause(.001)

        mm = nn*100-1;
    end

    % axes(hax3)
    ph3 = plot(xys(:,1)+2,xys(:,2)+.5,'Color',[.99 .6 .90],'LineWidth',5);
    ph3 = plot(xys(:,1),xys(:,2),'Color',[.99 .1 .75],'LineWidth',2);

    axis(axLims)

end


% fh1=figure('Units','normalized','OuterPosition',[.1 .1 .6 .7],'Color','w','MenuBar','none');
% 
% hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren');
% hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
% hax3 = axes('Position',[.05 .05 .9 .9],'Color','none','XTick',[],'YTick',[],'NextPlot','replacechildren');
% axis off; hold on;
% 
% axes(hax1)
% ph1 = imagesc(Frames(:,:,1));
% set(gca,'YDir','reverse')
% hax1.XLim = [1 size(IMG,2)];
% hax1.YLim = [1 size(IMG,1)];
% hold on
% 
% axLims = axis;
% 
% axes(hax2)
% ph2 = scatter(xy(1,1),xy(1,2),100,'filled','MarkerFaceColor',[.9 .1 .1]);
% axis(axLims)
% hold on
% 
% 
% axes(hax3)
% ph3 = plot(xy(1,1),xy(1,2),'r');
% axis(axLims)
% hold on
%     
% 
% t = (1:size(xy,1));
% ts = linspace(1, size(xy,1), size(xy,1)*100 );
% xys = spline(t,xy',ts)';
% 
% mm=1;
% for nn=1:size(Frames,3)
% 
%     ph1.CData = Frames(:,:,nn);
%     ph2.XData = xy(nn,1);
%     ph2.YData = xy(nn,2);
%     % ph3.XData = xy(1:nn,1);
%     % ph3.YData = xy(1:nn,2);
%     ph3.XData = xys(1:mm,1);
%     ph3.YData = xys(1:mm,2);
%     
%     pause(.2)
% 
%     mm = nn*100-1;
% end
% 
% axes(hax3)
% ph3 = plot(xys(:,1)+2,xys(:,2)+.5,'Color',[.99 .6 .90],'LineWidth',5);
% ph3 = plot(xys(:,1),xys(:,2),'Color',[.99 .1 .75],'LineWidth',2);
% 
% axis(axLims)


end
%% EOF



function stopevoq(hObject, eventdata, handles)
    
    disp('Stopping Daq')

end

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

