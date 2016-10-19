function [CMOS, CTIME] = fiberphotometry()

clc; close all; clear; clear java;

%% ACQUIRE DAQ OBJECT CLASS

global lbj
lbj=labJackU6; pause(.2);
% devInfo = getInfo(lbj);
open(lbj); pause(.2);
lbj.SampleRateHz = 1000;
lbj.verbose = 0;
addChannel(lbj,[0 1],[10 10],['s' 's']);
streamConfigure(lbj); pause(.2);
startStream(lbj);

analogOut(lbj,0,5); pause(.5);
analogOut(lbj,0,0); pause(.5);

analogOut(lbj,1,5); pause(.5);
analogOut(lbj,1,0); pause(.5);

% stopStream(lbj);
% clear lbj


%% ACQUIRE IMAGE ACQUISITION DEVICE (CAMERA) OBJECT


%% ACQUIRE IMAGE ACQUISITION DEVICE (CAMERA) OBJECT
total_trials = 1;
framesPerTrial = 1000;

vidPos = [320 130 640 460];
imageType = 'rgb';
% imageType = 'grayscale';

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end

vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);
vidObj.LoggingMode = 'memory';
vidObj.ReturnedColorspace = imageType;
vidObj.ROIPosition = vidPos;
vidObj.ReturnedColorspace = imageType;
vidObj.ROIPosition = vidPos;
vidObj.TriggerRepeat = total_trials * framesPerTrial + 1;
vidObj.FramesPerTrigger = 1;
triggerconfig(vidObj, 'manual');
start(vidObj);
trigger(vidObj);
[frame, ~] = getdata(vidObj, vidObj.FramesPerTrigger);        
IMG = rgb2gray(frame);
IMG = im2double(IMG);
frameSize = size(IMG);
pause(1);



% cam = webcam();
% frame = snapshot(cam);
% frameSize = size(frame);
% frameGray = rgb2gray(frame);
% pause(1);

TrialTimeInSeconds = 10;
Hz = 10;
sec = 1000/Hz/1000;

CMOS = zeros(frameSize(1),frameSize(2),TrialTimeInSeconds*Hz*10,2);
CTIME = zeros(2,TrialTimeInSeconds*Hz*10);

ff = 1;
tt = 0;


% et = tic;
% while tt < TrialTimeInSeconds
% ti = tic;    
% 
%     tt = toc(et);
%     waitT = sec-toc(ti);
%     pause(waitT)
%     disp(tt); disp(waitT)
%     ff = ff+1;
% 
% end



et = tic;
while tt < TrialTimeInSeconds
ti = tic;    
    
    % TURN ON LEDa
    analogOut(lbj,0,5);
    
    % CAPTURE LEDa CMOS FRAME
    trigger(vidObj);
    [frame, ~] = getdata(vidObj, vidObj.FramesPerTrigger);        
    IMG = rgb2gray(frame);
    IMG = im2double(IMG);
    % videoFrame = snapshot(cam);
    % IMG = rgb2gray(videoFrame);
    CMOS(:,:,ff,1) = IMG;
    CTIME(1,ff) = toc(et);
    
    % TURN OFF LEDa - TURN ON LEDb
    analogOut(lbj,0,0);
    analogOut(lbj,1,5);
    
    
    % CAPTURE LEDb CMOS FRAME
    trigger(vidObj);
    [frame, ~] = getdata(vidObj, vidObj.FramesPerTrigger);        
    IMG = rgb2gray(frame);
    IMG = im2double(IMG);
    % videoFrame = snapshot(cam);
    % IMG = rgb2gray(videoFrame);
    CMOS(:,:,ff,2) = IMG;
    CTIME(2,ff) = toc(et);
    
    % TURN OFF LEDb
    analogOut(lbj,1,0);
    
    tt = toc(et);
    pause(sec-toc(ti))
    disp(tt)
    ff = ff+1;
end

%% Clean up.
clear cam;

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end


analogOut(lbj,0,0);
analogOut(lbj,1,0);
stopStream(lbj);
clear lbj

% lbj = labJackU6;
% reset(lbj,'hard')
%{.
end



% ---------------------------------------------------------------------
%                   TEST TIMER A FUNCTIONS
% ---------------------------------------------------------------------
function ta = TESTtimerA(phDAQ)

    Time      = 30;
    Hz        = 250;
    TimeHz    = Time*Hz;
    FreqHz    = 10;
    Volts     = 5;
    T         = linspace(0, 1, Hz);
    P        = (sin(2*pi*FreqHz*T) +1) .* (Volts/2);

    voltMatrix   = repmat(P, 1, Time);
    voltMatrix(end) = 0;

    

    nt = 1;

    ta = timer;
    ta.UserData = {voltMatrix, nt, phDAQ};
    ta.StartFcn = @TESTTimerStartA;
    ta.TimerFcn = @genTESToutputA;
    ta.StopFcn = @TESTTimerCleanupA;
    ta.Period = 1/Hz;
    ta.StartDelay = 0;
    ta.TasksToExecute = TimeHz;
    ta.ExecutionMode = 'fixedSpacing';

end 

function TESTTimerStartA(mTimerA,~)
    disp('Starting TEST timer A.');
end

function genTESToutputA(mTimerA,~)

    uData = mTimerA.UserData;
    vMx = uData{1};
    nt = uData{2};
    % disp( vMx(1,nt) )
    
    uData{3}.XData = nt;
    uData{3}.YData = vMx(1,nt);
    
    % analogOut(uData{3},1,vMx(1,nt))
    nt = nt+1;
    if nt == 250; nt = 1; end;
    mTimerA.UserData = {vMx, nt, uData{3}};

end

function TESTTimerCleanupA(mTimerA,~)
    disp('Stopping TEST timer A.')
    % delete(mTimer)
end


% ---------------------------------------------------------------------
%                   TEST TIMER B FUNCTIONS
% ---------------------------------------------------------------------

function tb = TESTtimerB(phDAQ)

    Time      = 30;
    Hz        = 250;
    TimeHz    = Time*Hz;
    FreqHz    = 10;
    Volts     = 5;
    T         = linspace(0, 1, Hz);
    P        = (square(2*pi*FreqHz*T) + 1) .* (Volts/2);

    voltMatrix   = repmat(P, 1, Time);
    voltMatrix(end) = 0;
    
    nt = 1;

    tb = timer;
    tb.UserData = {voltMatrix, nt, phDAQ};
    tb.StartFcn = @TESTTimerStartB;
    tb.TimerFcn = @genTESToutputB;
    tb.StopFcn = @TESTTimerCleanupB;
    tb.Period = 1/Hz;
    tb.StartDelay = 0;
    tb.TasksToExecute = TimeHz;
    tb.ExecutionMode = 'fixedSpacing';

end 

function TESTTimerStartB(mTimerB,~)
    disp('Starting TEST timer B.');
end

function genTESToutputB(mTimerB,~)

    uData = mTimerB.UserData;
    vMx = uData{1};
    nt = uData{2};

    uData{3}.XData = nt;
    uData{3}.YData = vMx(1,nt);
    
    nt = nt+1;
    if nt == 250; nt = 1; end;
    mTimerB.UserData = {vMx, nt, uData{3}};

end

function TESTTimerCleanupB(mTimerB,~)
    disp('Stopping TEST timer B.')
    % delete(mTimer)
end











%% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy
function [masks, IMG] = getROIframes(nmasks)


cam = webcam();
frame = snapshot(cam);
frameSize = size(frame);

IMG = rgb2gray(frame(:,:,:,1));
IMG = im2double(IMG);


clear cam

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end



% SET ROI MASK FROM SINGLE CAM IMAGE

imsz = size(IMG);


fhIMG = figure('Units','normalized','OuterPosition',[.05 .05 .75 .8],'Color','w','MenuBar','none');
haxIMG  = axes('Position',[.01 .01 .95 .95],'Color','none','NextPlot','replacechildren','YDir','reverse');
haxIMG.XLim = [1, size(IMG,2)];
haxIMG.YLim = [1, size(IMG,1)];
hold on;


axes(haxIMG)
ph1 = imagesc(IMG);
set(gca,'YDir','reverse')
haxIMG.XLim = [1 size(IMG,2)];
haxIMG.YLim = [1 size(IMG,1)];
hold on

axLims = axis;

% axes(hax2)
ph2 = scatter(1,1,100,'filled','MarkerFaceColor',[.9 .1 .1]);
axis(axLims)
hold on


masks = struct;
masks.allmasks = [];

for mm = 1:nmasks

    
    [STIM_region, STIM_region_x, STIM_region_y] = roipoly; %allows user to plot polygonal ROI

    masks(mm).STIM_region   = STIM_region;
    masks(mm).STIM_region_x = STIM_region_x;
    masks(mm).STIM_region_y = STIM_region_y;
    
    
    plot(STIM_region_x, STIM_region_y,'linewidth',6); %show ROI on plot
    
    hold on

    

end
pause(.5)

allmasks = masks(1).STIM_region;
for mm = 1:nmasks

    allmasks = allmasks + masks(mm).STIM_region;

end
allmasks(allmasks>0) = 1;

masks(1).allmasks = allmasks;

axes(haxIMG)
ph3 = imagesc(allmasks .* IMG);
set(gca,'YDir','reverse')
haxIMG.XLim = [1 size(IMG,2)];
haxIMG.YLim = [1 size(IMG,1)];
hold on


for mm = 1:nmasks

    ph4{mm} = plot(masks(mm).STIM_region_x, masks(mm).STIM_region_y,'linewidth',6);

end


pause(.001)
varargout = {ph1, ph2, ph3, ph4};

end

%}

