function [outputstructure] = IRheattracking_3(InputFileName)
    

%This program allos user to import video data from an infrared camera and
%track an animal within that video. Input is the filename of a video in
%the MATLAB path and it outputs into a data structure:
%  xy -- x and y coordinates
%  dL -- speed
%  image -- matrix of first frame for ROI analysis later on

%Example: [Arena_Data.AUG09.LH1] = IRheattracking_3('080916_LHALHB_1.mp4')

%It takes some time to run (minutes) so it is best to run in batches. 



%% GET VIDEO FILENAME USING GUI PROMPT

close all; 
scsz = get(0,'ScreenSize');

vidname = InputFileName; %video name is InputFileName

SkpFrm = 30; %reads every 30 frames



% READ VIDEO INTO FRAME DATA

f = VideoReader(vidname);				% import vid
nf = get(f, 'NumberOfFrames');			% get total number of vid frames

f1 = mean(read(f, 1),3);				% get frame-1 data
szf = size(f1);

nFrms = numel(1:SkpFrm:nf) - 1;

f1dat = {zeros(szf)};
framedat = repmat(f1dat,1,nFrms);

%figure(1); imagesc(f1);				% plot frame-1 data



% GET FRAME DATA

clear f

ff = VideoReader(vidname);

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
mu = n_pixels;
sd = n_pixels;
mupix = n_pixels;

pixelvals{nFrms,NumMasks} = [];

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% OPTIONAL: Play VIDEO overlaying tracking position over rat to check accuracy
% close all
% 
% fh1 = figure(1);
% set(fh1,'Position',[100 200 600 500],'Color','w');
% hax1=axes('Position',[.07 .1 .8 .8],'Color','none','NextPlot','replacechildren');
% hax2=axes('Position',[.07 .1 .8 .8],'Color','none','NextPlot','replacechildren');
% 
% 
%     axes(hax1)
%     imagesc(framedat{nn})
%     set(gca,'YDir','reverse')
%     hold on
%     
%     axLims = axis;
%     
%     axes(hax2)
%     scatter(xloc(nn),yloc(nn),100,'filled','MarkerFaceColor',[.9 .1 .1]);
%     axis(axLims)
%     hold on
% 
% for nn=1:numel(framedat)
%     
%     delete(hax1.Children); delete(hax2.Children);
%     
%     imagesc(framedat{nn},'Parent', hax1)
%     
%     scatter(hax2, xloc(nn),yloc(nn),250,'filled','r');
%     
%     pause(.1)
%     
%     nn/60
%     
% end



% COMPUTE TOTAL DISTANCE 

% 'xloc' contains vector of x-coordinate positions
% 'yloc' contains vector of y-coordinate positions

for dt = 1:numel(xloc)-1

    Xa = dt;
    Ya = dt;
    Xb = Xa+1;
    Yb = Ya+1;
    
    dL(dt) = sqrt((xloc(Xb) - xloc(Xa))^2 + (yloc(Yb) - yloc(Ya))^2);

end

bigL = dL > 10;

bdL = dL(bigL);

sdL = dL(~bigL);



% 
% totalDist = sum(dL);
% meanDist = mean(dL);
% stdDist = std(dL);
% semDist = stdDist / sqrt(numel(dL));
% 
% SPF1 = sprintf('  TOTAL AMBULATORY DISTANCE: % 5.6g au \r',totalDist);
% SPF2 = sprintf('  MEAN AMBULATORY DISTANCE: % 5.4g au \r',meanDist);
% SPF3 = sprintf('  STDEV AMBULATORY DISTANCE: % 5.4g au \r',stdDist);
% SPF4 = sprintf('  SEM AMBULATORY DISTANCE: % 5.4g au \r',semDist);
% 
% disp(' ')
% disp([SPF1, SPF2, SPF3, SPF4])


% BIN DATA - COMPUTE SUM AND MEAN FOR EACH BIN

% nbins = 40;
% subs = round(linspace(1,nbins,numel(dL))); % subs(end) = nbins;
% BinSumD = accumarray(subs',dL,[],@sum);
% BinAveD = accumarray(subs',dL,[],@mean);
% 
% 
% 



% PLOT DATA

% fh1=figure('Position',[100 200 1100 500],'Color','w');
% hax1=axes('Position',[.07 .1 .4 .8],'Color','none');
% hax2=axes('Position',[.55 .1 .4 .8],'Color','none');
% 
%     axes(hax1)
% ph1 = plot(xloc,yloc);
%     set(ph1,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
% 
%     axes(hax2)
% ph2 = plot(BinSumD);
%     set(ph1,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
%     axis tight
% % 
% % 
% %     fh2=figure('Position',[100 200 1100 500],'Color','w');
% % hax3=axes('Position',[.07 .1 .4 .8],'Color','none');
% % hax4=axes('Position',[.55 .1 .4 .8],'Color','none');
% % 
% %     axes(hax3)
% % ph3 = plot(bdL);
% %     set(ph3,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
% % 
%     axes(hax4)
% ph4 = plot(sdL);
%     set(ph4,'LineStyle','-','Color',[.9 .2 .2],'LineWidth',2);
%     %axis tight
% 


% % ADDITIONAL PLOTS
% 
% % Moving average wts = [1/10;repmat(1/5,4,1);1/10]; L =
% conv(dL,wts,'valid'); plot(L,'r','LineWidth',2);
% 



% Save into structure

outputstructure.dL = dL;
outputstructure.xy = xy;
outputstructure.image = framedat{1};

%
% figure
% gkde2(xy(360:end,:))


