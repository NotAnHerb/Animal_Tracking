function [] = facetrak()

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

clear cam

%% PREALLOCATE DATA COLLECTORS

imSizeX = size(frame,2);
imSizeY = size(frame,1);

FramesTS = [];
Frames = zeros(imSizeY,imSizeX,framesPerTrial);




%% CREATE FIGURE WINDOW FOR LIVE IMAGE

axes(haxCAM);
phCAM = imagesc(frame);
axes(haxPIN);
phPIN = scatter(10,10,60,'r','filled');


%% Setup
% Create objects for detecting faces, tracking points, acquiring and
% displaying video frames.

% Create the face detector object.
faceDetector = vision.CascadeObjectDetector();

% Create the point tracker object.
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Create the webcam object.
cam = webcam();

% Capture one frame to get its size.
videoFrame = snapshot(cam);
frameSize = size(videoFrame);

% Create the video player object. 
% videoPlayer = vision.VideoPlayer('Position', [10 10 [frameSize(2), frameSize(1)]+30]);
videoPlayer = vision.VideoPlayer('Position', [10 10 [frameSize(2), frameSize(1)]./2]);

%% Detection and Tracking
% Capture and process video frames from the webcam in a loop to detect and
% track a face. The loop will run for 400 frames or until the video player
% window is closed.

runLoop = true;
numPts = 0;
frameCount = 0;

framesPerTrial = 2000;

daqA = 0;
daqB = 0;

tic

ff = 1;

while runLoop && frameCount < framesPerTrial
    
    % Get the next frame.
    videoFrame = snapshot(cam);
    videoFrameGray = rgb2gray(videoFrame);
    frameCount = frameCount + 1;
    
    if numPts < 10
        % Detection mode.
        bbox = faceDetector.step(videoFrameGray);
        
        if ~isempty(bbox)
            % Find corner points inside the detected region.
            points = detectMinEigenFeatures(videoFrameGray, 'ROI', bbox(1, :));
            
            % Re-initialize the point tracker.
            xyPoints = points.Location;
            numPts = size(xyPoints,1);
            release(pointTracker);
            initialize(pointTracker, xyPoints, videoFrameGray);
            
            % Save a copy of the points.
            oldPoints = xyPoints;
            
            % Convert the rectangle represented as [x, y, w, h] into an
            % M-by-2 matrix of [x,y] coordinates of the four corners. This
            % is needed to be able to transform the bounding box to display
            % the orientation of the face.
            bboxPoints = bbox2points(bbox(1, :));  
            
            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4] 
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);
            
            % Display a bounding box around the detected face.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);
            
            % Display detected corners.
            videoFrame = insertMarker(videoFrame, xyPoints, '+', 'Color', 'white');
        end
        
    else
        % Tracking mode.
        [xyPoints, isFound] = step(pointTracker, videoFrameGray);
        visiblePoints = xyPoints(isFound, :);
        oldInliers = oldPoints(isFound, :);
                
        numPts = size(visiblePoints, 1);       
        
        if numPts >= 10
            % Estimate the geometric transformation between the old points
            % and the new points.
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);            
            
            % Apply the transformation to the bounding box.
            bboxPoints = transformPointsForward(xform, bboxPoints);
            
            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4] 
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);            
            
            % Display a bounding box around the face being tracked.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);
            
            % Display tracked points.
            videoFrame = insertMarker(videoFrame, visiblePoints, '+', 'Color', 'white');
            
            % Reset the points.
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
        end
        
        
        
        xmean = round(mean(xyPoints(:,1)));
        ymean = round(mean(xyPoints(:,2)));
        xyloc = [xmean ymean];
        videoFrame = insertMarker(videoFrame, xyloc, 'o', 'Color', 'red');
        
        
        
        if daqA ~= 1 && masks(1).STIM_region(xyloc(2),xyloc(1))
            if daqB == 1
                stop(tb);
                daqB = 0;
            end
        start(ta);
        daqA = 1;
        end

        if daqB ~= 1 && masks(2).STIM_region(xyloc(2),xyloc(1))
            if daqA == 1
                stop(ta);
                daqA = 0;
            end
            start(tb); 
            daqB = 1;
        end
        
        
        

    end
        
    % Display the annotated video frame using the video player object.
    step(videoPlayer, videoFrame);

    % Check whether the video player window has been closed.
    runLoop = isOpen(videoPlayer);
end

% Clean up.
clear cam;
release(videoPlayer);
release(pointTracker);
release(faceDetector);


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



