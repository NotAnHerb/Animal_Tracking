function [outputstructure] = IRframes(varargin)
    

%This program allos user to import video data from an infrared camera and
%track an animal within that video. Input is the filename of a video in
%the MATLAB path and it outputs into a data structure:
%  xy -- x and y coordinates
%  dL -- speed
%  image -- matrix of first frame for ROI analysis later on

%Example: [Arena_Data.AUG09.LH1] = IRheattracking_3('080916_LHALHB_1.mp4')

%It takes some time to run (minutes) so it is best to run in batches. 


%% -- DEAL ARGS

    if nargin < 1
    
        [datafile, datapath, ~] = uigetfile({'*.mp4; *.mov'}, 'Select video.');
        mediapath = [datapath datafile];
        
        f = VideoReader(mediapath);				% import vid
        
        SkpFrm = 1; %reads every 30 frames

    elseif nargin == 1
        
        f = varargin{1};
        
        [datafile, datapath, ~] = uigetfile({'*.mp4; *.mov'}, 'Select video.');
        mediapath = [datapath datafile];

        SkpFrm = 1; %reads every 30 frames
        
    elseif nargin == 2
        
        [f, mediapath] = deal(varargin{:});
        
        SkpFrm = 1; %reads every 30 frames
        
    elseif nargin == 3
        
        [f, mediapath, SkpFrm] = deal(varargin{:});

    else
        warning('Too many inputs')
    end



%% GET VIDEO FILENAME USING GUI PROMPT


% READ VIDEO INTO FRAME DATA
nf = get(f, 'NumberOfFrames');			% get total number of vid frames

f1 = mean(read(f, 1),3);				% get frame-1 data
szf = size(f1);

nFrms = numel(1:SkpFrm:nf) - 1;

f1dat = {zeros(szf)};
framedat = repmat(f1dat,1,nFrms);


% GET FRAME DATA

clear f

ff = VideoReader(mediapath);

mm=1;
for nn=1:SkpFrm:(nf-1)

    framedat{mm} = mean(read(ff, nn), 3);

    if ~mod(mm,100); disp(nn); end

mm = mm+1;
end



NumMasks = 1; %vestigial from previous iteration -- creates a matrix of 1s the size of a given frame
mask{1} = zeros(size(f1));
mask{1} = mask{1} + 1;

threshmask = 100; %again -- vestigial -- as program picks the hottest pixel values irrespective of threshold


% MAIN DATA ACQUISITION LOOP

% nFrms = numel(1:SkpFrm:nf);

n_pixels = zeros(nFrms,NumMasks); %initializes
% mu = n_pixels;
% sd = n_pixels;
% mupix = n_pixels;
% 
% pixelvals{nFrms,NumMasks} = [];

imgsz = size(f1);
imgszY = imgsz(1)+1;



xloc = zeros(numel(1:numel(framedat)),1); % 479x1 double
yloc = zeros(numel(1:numel(framedat)),1); % 479x1 double


pp = 1;
% for every frame
for mm = 1:numel(framedat)
	
    % load the frame data from the movie
    framedata = framedat{mm};
    
    % for every mask (subregion of image)
	for nn = 1:NumMasks
		
        % find where the hot thing is in the subregion; anything over threshold
        % corresponds to the hot thing in the given image subregion
        subjpixels = framedata.*mask{nn} > threshmask(nn);
        
        rawpixelvals = framedata .* subjpixels;
        		
        [ii,jj,val] = find(rawpixelvals); 
        IJV = [ii,jj,val];
        [E, index] = sortrows(IJV,-3);
        % where are the hot pixels?
		% save mean x and y position of the hot thing -- for motion detection.   
        n_hotpixels = 50; %finds the n hottest pixels
        yloc(mm,nn) = imgszY-mean(E(1:n_hotpixels,1));
        xloc(mm,nn) = mean(E(1:n_hotpixels,2));
	end

end

xy = [xloc yloc]; %saves data

%% COMPUTE TOTAL DISTANCE 

% 'xloc' contains vector of x-coordinate positions
% 'yloc' contains vector of y-coordinate positions

for dt = 1:numel(xloc)-1

    Xa = dt;
    Ya = dt;
    Xb = Xa+1;
    Yb = Ya+1;
    
    dL(dt) = sqrt((xloc(Xb) - xloc(Xa))^2 + (yloc(Yb) - yloc(Ya))^2);

end

outputstructure.dL = dL;
outputstructure.xy = xy;
outputstructure.image = framedat;

end