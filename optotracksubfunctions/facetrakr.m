function [] = facetrakr()

global lbj
lbj=labJackU6; pause(.2);
% devInfo = getInfo(lbj);
open(lbj); pause(.2);
lbj.SampleRateHz = 1000;
lbj.verbose = 0;
addChannel(lbj,[0 1],[10 10],['s' 's']);
streamConfigure(lbj); pause(.2);
startStream(lbj);

analogOut(lbj,1,5); pause(1);
analogOut(lbj,1,0); pause(1);


%% CREATE TIMER OBJECTS FOR DAQ PULSE GENERATION

ta = DAQtimerA(lbj);
tb = DAQtimerB(lbj);

pause(1)

for n = 1:100

    if n == 1
        start(ta); pause(.01)
    end

    if n == 40
        stop(ta); pause(.1)
        analogOut(lbj,1,0);
        start(tb); pause(.1)
    end

    if n == 60
        stop(tb); pause(.1)
        analogOut(lbj,1,0);
        start(ta); pause(.1)
    end

    pause(.1)
end
stop(ta); pause(.1)
analogOut(lbj,1,0);

%%

fh1=figure('Units','normalized','OuterPosition',[.1 .1 .6 .8],'Color','w','MenuBar','none');
haxes = axes('Position',[.05 .05 .9 .9],'Color','none','NextPlot','replacechildren','YDir','reverse');

[masks, IMG] = getROIf(2, haxes);

pause(.5)

close all

% imagesc(masks(1).STIM_region)


%% Overview
% Object detection and tracking are important in many computer vision
% applications including activity recognition, automotive safety, and
% surveillance.  In this example you will develop a simple system for
% tracking a single face in a live video stream captured by a webcam.
% MATLAB provides webcam support through a Hardware Support Package,
% which you will need to download and install in order to run this example. 
% The support package is available via the 
% <matlab:supportPackageInstaller Support Package Installer>.
%
% The face tracking system in this example can be in one of two modes:
% detection or tracking. In the detection mode you can use a
% |vision.CascadeObjectDetector| object to detect a face in the current
% frame. If a face is detected, then you must detect corner points on the 
% face, initialize a |vision.PointTracker| object, and then switch to the 
% tracking mode. 
%
% In the tracking mode, you must track the points using the point tracker.
% As you track the points, some of them will be lost because of occlusion. 
% If the number of points being tracked falls below a threshold, that means
% that the face is no longer being tracked. You must then switch back to the
% detection mode to try to re-acquire the face.

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
videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);

%% Detection and Tracking
% Capture and process video frames from the webcam in a loop to detect and
% track a face. The loop will run for 400 frames or until the video player
% window is closed.

runLoop = true;
numPts = 0;
frameCount = 0;
daqA = 0;
daqB = 0;

while runLoop && frameCount < 2000
    
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
            analogOut(lbj,1,0);
            start(ta);
            daqA = 1;
        end

        if daqB ~= 1 && masks(2).STIM_region(xyloc(2),xyloc(1))
            if daqA == 1
                stop(ta);
                daqA = 0;
            end
            analogOut(lbj,1,0);
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

analogOut(lbj,1,0);
stopStream(lbj);
clear lbj

% lbj = labJackU6;
% reset(lbj,'hard')

end






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

