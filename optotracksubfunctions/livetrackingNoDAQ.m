function [] = livetrackingNoDAQ()
% function [memos] = livetrackingNoDAQ(mainguih, haxMAIN, tri, fpt, pxt, np, headrad, trackhead, memos, memoboxH)
clc; close all; clear; clear java;


%% USER-ENTERED PARAMETERS

framesPerTrial = 2000;

npixels = 10;  % Number of 'hot' pixels to average to find center

nmasks = 2;


%% GET SINGLE CAMERA FRAME TO SET ROI MASKS

[masks, IMG] = getROIframes(nmasks);

close all;


%% ACQUIRE DAQ OBJECT CLASS

cam = webcam();
frame = snapshot(cam);
frameSize = size(frame);
clear cam


Time      = 30;
Hz        = 250;
FreqHz    = 10;
Volts     = 5;
T         = linspace(0, 1, Hz);
PA        = (sin(2*pi*FreqHz*T) +1) .* (Volts/2);
PB        = (square(2*pi*FreqHz*T) + 1) .* (Volts/2);

voltMatrixA = repmat(PA, 1, Time)';
voltMatrixA(end) = 0;

voltMatrixB = repmat(PB, 1, Time)';
voltMatrixB(end) = 0;


fhDAQ = figure('Units','normalized','OuterPosition',[.01 .05 .95 .5],'Color','w','MenuBar','none');
haxCAM  = axes('Position',[.01 .01 .45 .9],'Color','none','NextPlot','replacechildren','YDir','reverse');
haxCAM.XLim = [1, size(frame,2)];
haxCAM.YLim = [1, size(frame,1)];
hold on;
haxPIN  = axes('Position',[.01 .01 .45 .9],'Color','none','NextPlot','replacechildren','YDir','reverse');
haxPIN.XLim = [1, size(frame,2)];
haxPIN.YLim = [1, size(frame,1)];
hold on;


haxDAQ  = axes('Position',[.51 .01 .45 .9],'Color','none','NextPlot','replacechildren');
haxDAQ.XLim = [1, length(PA)];
haxDAQ.YLim = [0, max(PA)];
hold on;


axes(haxCAM);
phCAM = imagesc(frame);
axes(haxPIN);
phPIN = scatter(10,10,60,'r','filled');


axes(haxDAQ);
phWavA = plot([PA', PB']);
% phWavB = plot(voltMatrixB);
phDAQ = scatter(1,voltMatrixA(1),60,'k','filled');
% phDotB = scatter(10,10,60,'r','filled');

% nvMx = length(voltMatrixA);
% nvPA = length(PA);
% mm = 1;
% for nn = 1:nvMx
%     
%     phDAQ.XData = mm;
%     phDAQ.YData = PB(mm);
%     
%     mm = mm + 1;
%     if mm == nvPA; mm = 1; end;
% 
%     pause(.01)
% end

%% CREATE TIMER OBJECTS FOR DAQ PULSE GENERATION

ta = TESTtimerA(phDAQ);
tb = TESTtimerB(phDAQ);

pause(1)

for n = 1:100

    if n == 1
        start(ta); pause(.01)
    end

    if n == 40
        stop(ta); pause(.1)
        start(tb); pause(.1)
    end

    if n == 60
        stop(tb); pause(.1)
        start(ta); pause(.1)
    end

    pause(.1)
end
stop(ta); pause(.1)

% delete(ta)
% delete(tb)


%% ACQUIRE IMAGE ACQUISITION DEVICE (CAMERA) OBJECT

cam = webcam();
frame = snapshot(cam);
frameSize = size(frame);
frameGray = rgb2gray(frame);

% videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);


%% PREALLOCATE DATA COLLECTORS

imSizeX = size(frame,2);
imSizeY = size(frame,1);

FramesTS = [];
Frames = zeros(imSizeY,imSizeX,framesPerTrial);




%% CREATE FIGURE WINDOW FOR LIVE IMAGE
% fh1=figure('Units','normalized','OuterPosition',[.1 .1 .6 .8],'Color','w','MenuBar','none');
% hax1 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren','YDir','reverse');
% hax1.XLim = [1, size(frame,2)];
% hax1.YLim = [1, size(frame,1)];
% hold on;
% hax2 = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren','YDir','reverse');
% hax2.XLim = [1, size(frame,2)];
% hax2.YLim = [1, size(frame,1)];
% hold on;
% 
% axes(hax1);
% ph1 = imagesc(frame);
% 
% axes(hax2);
% ph2 = scatter(10,10,60,'r','filled');

axes(haxCAM);
phCAM = imagesc(frame);
axes(haxPIN);
phPIN = scatter(10,10,60,'r','filled');


%% SET PRE-LOOP PARAMETERS

framesPerTrial = 2000;

xy = zeros(framesPerTrial,2);

tictoc = zeros(framesPerTrial,1);

runLoop = true;
frameCount = 0;

daqA = 0;
daqB = 0;

tic

ff = 1;
%% MAIN LOOP
while runLoop && frameCount < framesPerTrial
    
    frame = snapshot(cam);     % videoFrameGray = rgb2gray(videoFrame);
    
    frameCount = frameCount + 1;

    IMG = rgb2gray(frame);
    IMG = im2double(IMG);

    % FramesTS(end+1) = ts;
    % Frames(:,:,ff) = IMG;         % store frame data


    % headmask = findsubject(IMG, threshmask, headrad, frameSize);


    % FIND ALL NON-ZERO PIXELS (PIXELS ABOVE THRESHOLD)
    % pctIMG = prctile(IMG(:),95);
    % [row,col,val] = find(IMG>pctIMG); 
    [row,col,val] = find(IMG); 
    RCV = [row,col,val];


    % SORT BY PIXEL BRIGHTNESS (HIGH TO LOW)
    [YXv, index] = sortrows(RCV,-3); 

    % GET THE COLUMN (X) AND ROW (Y) INDEX OF THE HOTTEST PIXELS
    % MEAN OF THOSE PIXEL COORDINATES IS GEOMETRIC CENTER
    xcol = round(mean( YXv(1:npixels,2) ));

    % yrow = mean( imSizeY - YXv(1:npixels,1) );
    yrow = round(mean( YXv(1:npixels,1) ));




    if daqA ~= 1 && masks(1).STIM_region(yrow,xcol)
        if daqB == 1
            stop(tb);
            daqB = 0;
        end
        start(ta);
        daqA = 1;
    end

    if daqB ~= 1 && masks(2).STIM_region(yrow,xcol)
        if daqA == 1
            stop(ta);
            daqA = 0;
        end
        start(tb); 
        daqB = 1;
    end


    
    % imshow(frame,'Parent',hax1)
    phCAM.CData = IMG;
    phPIN.XData = xcol;
    phPIN.YData = yrow;
    

    xy(ff,:) = [xcol yrow];
    % tictoc(nn) = toc;        
    ff=ff+1;
    pause(.001)

    
    % fprintf('\n Ending trial: %d \n', trial);
    
end


%% CLEAN UP DEVICE OBJECTS

clear cam

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end


stop(ta); pause(.01)
stop(tb); pause(.01)
delete(ta); pause(.01)
delete(tb); pause(.01)

% analogOut(lbj,1,0);
% stopStream(lbj);
% clear lbj
% lbj = labJackU6;
% reset(lbj,'hard')

disp(tictoc')


end
%% EOF











% ---------------------------------------------------------------------
%                   DAQ TIMER A FUNCTIONS
% ---------------------------------------------------------------------
function ta = DAQtimerA(lbj)

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
    ta.UserData = {voltMatrix, nt, lbj};
    ta.StartFcn = @DAQTimerStartA;
    ta.TimerFcn = @genDAQoutputA;
    ta.StopFcn = @DAQTimerCleanupA;
    ta.Period = 1/Hz;
    ta.StartDelay = 0;
    ta.TasksToExecute = TimeHz;
    ta.ExecutionMode = 'fixedSpacing';

end 

function DAQTimerStartA(mTimerA,~)
    disp('Starting DAQ timer A.');
end

function genDAQoutputA(mTimerA,~)

    uData = mTimerA.UserData;
    vMx = uData{1};
    nt = uData{2};
    % disp( vMx(1,nt) )
    analogOut(uData{3},1,vMx(1,nt))
    nt = nt+1;
    mTimerA.UserData = {vMx, nt, uData{3}};

end

function DAQTimerCleanupA(mTimerA,~)
    disp('Stopping DAQ timer A.')
    % delete(mTimer)
end


% ---------------------------------------------------------------------
%                   DAQ TIMER B FUNCTIONS
% ---------------------------------------------------------------------

function tb = DAQtimerB(lbj)

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
    tb.UserData = {voltMatrix, nt, lbj};
    tb.StartFcn = @DAQTimerStartB;
    tb.TimerFcn = @genDAQoutputB;
    tb.StopFcn = @DAQTimerCleanupB;
    tb.Period = 1/Hz;
    tb.StartDelay = 0;
    tb.TasksToExecute = TimeHz;
    tb.ExecutionMode = 'fixedSpacing';

end 

function DAQTimerStartB(mTimerB,~)
    disp('Starting DAQ timer B.');
end

function genDAQoutputB(mTimerB,~)

    uData = mTimerB.UserData;
    vMx = uData{1};
    nt = uData{2};
    % disp( vMx(1,nt) )
    analogOut(uData{3},1,vMx(1,nt))
    nt = nt+1;
    mTimerB.UserData = {vMx, nt, uData{3}};

end

function DAQTimerCleanupB(mTimerB,~)
    disp('Stopping DAQ timer B.')
    % delete(mTimer)
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







%% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy
%{

% LIVE PLOTTING FOR LOOP

            
            
            
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
%}



% DAQ & PARALLEL NOTES
%{
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

%}


% SAVE IMAGE ACQUISITION NOTES
%{


%% ACQUIRE IMAGE ACQUISITION DEVICE (CAMERA) OBJECT
% total_trials = 1;
% framesPerTrial = 100;

% vidPos = [320 130 640 460];
% imageType = 'rgb';
% % imageType = 'grayscale';
% 
% out = imaqfind;
% for nn = 1:length(out)
%     stop(out(nn))
%     wait(out(nn));
%     delete(out(nn));
% end
% 
% % imaqtool
% vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% % vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
% src = getselectedsource(vidObj);
% 
% vidObj.LoggingMode = 'memory';
% vidObj.ReturnedColorspace = imageType;
% vidObj.ROIPosition = vidPos;
% 
% vidObj.ReturnedColorspace = imageType;
% vidObj.ROIPosition = vidPos;
% 
% vidObj.TriggerRepeat = total_trials * framesPerTrial + framesPerTrial;
% vidObj.FramesPerTrigger = 1;
% triggerconfig(vidObj, 'manual');
% 
% start(vidObj);


















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
