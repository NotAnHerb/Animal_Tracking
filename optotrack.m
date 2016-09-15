function varargout = optotrack(varargin)
%% optotrack.m - Optogenetics and Behavioral Assay Toolbox
%{
% 
% Syntax
% -----------------------------------------------------
%     optotrack()
% 
% 
% Description
% -----------------------------------------------------
% 
%     neuromorph() is run with no arguments passed in. The user
%     will be prompted to select a directory which contains the image data
%     tif stack along with the corresponding xls file.
%     
% 
% Useage Definitions
% -----------------------------------------------------
% 
%     neuromorph()
%         launches a GUI to process image stack data from GRIN lens
%         experiments
%  
% 
% 
% Example
% -----------------------------------------------------
% 
%     TBD
% 
% 
% See Also
% -----------------------------------------------------
% >> web('http://bradleymonk.com/neuromorph')
% >> web('http://imagej.net/Miji')
% >> web('http://bigwww.epfl.ch/sage/soft/mij/')
% 
% 
% Attribution
% -----------------------------------------------------
% % Created by: Bradley Monk
% % email: brad.monk@gmail.com
% % website: bradleymonk.com
% % 2016.07.04
%}
%----------------------------------------------------

%This program allows users to import video data from an infrared camera and
%track an animal within that video. Input is the filename of a video in
%the MATLAB path and it outputs into a data structure:
%  xy -- x and y coordinates
%  dL -- speed
%  image -- matrix of first frame for ROI analysis later on

%Example: [Arena_Data.AUG09.LH1] = IRheattracking_3('080916_LHALHB_1.mp4')

%It takes some time to run (minutes) so it is best to run in batches. 


%% ESTABLISH STARTING PATHS
clc; close all; clear all; clear java;

disp('WELCOME TO OPTOTRACK - Optogenetics and Behavioral Assay Toolbox')


global thisfilepath
thisfile = 'optotrack.m';
thisfilepath = fileparts(which(thisfile));
cd(thisfilepath);

fprintf('\n\n Current working path set to: \n % s \n', thisfilepath)

    
pathdir0 = thisfilepath;
pathdir1 = [thisfilepath '/media'];
gpath = [pathdir0 ':' pathdir1];
addpath(gpath)

fprintf('\n\n Added folders to path: \n % s \n % s \n\n',pathdir0,pathdir1)




%% GET PATHS AND FILES

global datapath datafile mediapath VID outputstructure
datapath = '';
datafile = '';
mediapath = '';


 

%% ESTABLISH GLOBALS AND SET STARTING VALUES

global haxMAIN haxMINI memos memoboxH

global mainsliderh


%########################################################################
%%              MAIN ANALYSIS GUI WINDOW SETUP 
%########################################################################


% mainguih.CurrentCharacter = '+';
mainguih = figure('Units', 'normalized','Position', [.1 .1 .8 .7], 'BusyAction',...
    'cancel', 'Name', 'OptoTrack', 'Tag', 'OptoTrack','Visible', 'Off'); %, ...
    %'KeyPressFcn', {@keypresszoom,1});

haxMAIN = axes('Parent', mainguih, 'NextPlot', 'Add',...
    'Position', [0.01 0.01 0.60 0.95], ...
    'XColor','none','YColor','none'); % 'PlotBoxAspectRatio', [1 1 1],




mainsliderh = uicontrol('Parent', mainguih, 'Units', 'normalized','Style','slider',...
	'Max',50,'Min',1,'Value',10,'SliderStep',[.1 .2],...
	'Position', [0.01 0.96 0.60 0.03], 'Callback', @mainslider);



haxMINI = axes('Parent', mainguih, 'NextPlot', 'replacechildren',...
    'Position', [0.63 0.03 0.35 0.25]); 

axes(haxMAIN)



%----------------------------------------------------
%           IMAGE PROCESSING PANEL
%----------------------------------------------------
IPpanelH = uipanel('Title','Video Processing','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.62 0.60 0.20 0.39]); % 'Visible', 'Off',


getvidh = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.05 0.80 0.90 0.15], 'FontSize', 11, 'String', 'Import Video',...
    'Callback', @getvid); 

getframesh = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.05 0.60 0.90 0.15], 'FontSize', 11, 'String', 'Get Frames',...
    'Callback', @getframes); 

runtrackingh = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.05 0.40 0.90 0.15], 'FontSize', 11, 'String', 'Perform Tracking',...
    'Callback', @runtracking); 

runcustomh = uicontrol('Parent', IPpanelH, 'Units', 'normalized', ...
    'Position', [0.05 0.20 0.90 0.15], 'FontSize', 11, 'String', 'Custom Function',...
    'Callback', @runcustom); 


%----------------------------------------------------
%           MEMO CONSOLE GUI WINDOW
%----------------------------------------------------

memopanelH = uipanel('Title','Memo Log ','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.62 0.30 0.35 0.29]); % 'Visible', 'Off',


memos = {' Welcome to OptoTrack', ' ',...
         ' Import video media to start', ' ', ...
         ' ', ' ', ...
         ' ', ' ', ...
         ' ', ' '};

memoboxH = uicontrol('Parent',memopanelH,'Style','listbox','Units','normalized',...
        'Max',10,'Min',0,'Value',[],'FontSize', 13,'FontName', 'FixedWidth',...
        'String',memos,'FontWeight', 'bold',...
        'Position',[.02 .02 .96 .96]);  






%%
%----------------------------------------------------
%     INITIALIZE TOOLBOX PARAMETERS
%----------------------------------------------------

OPTOTRACKgo()











% -----------------------------------------------------------------------------
%%                     GUI TOOLBOX FUNCTIONS
% -----------------------------------------------------------------------------





function OPTOTRACKgo()
    
    
    set(mainguih, 'Visible', 'On');
    
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Welcome to OptoTrack';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Optogenetics & Behavior Analysis Toolbox';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Loading GUI interface...';
    memoboxH.String = memos;
    pause(.02)
    % ------

    
    iminfo = imfinfo('optotracklogo.png');
    [im, map] = imread('optotracklogo.png');
    
    im_size = size(im);
    im_nmap = numel(map);
    im_ctype = iminfo.ColorType;
    
    
    
    

    if numel(im_size) > 3
        im = im(:,:,1,207);
        im_size = 2;
    end

    if strcmp(im_ctype, 'truecolor') || numel(im_size) > 2
        IMG = rgb2gray(im);
        IMG = im2double(IMG);
    elseif strcmp(im_ctype, 'indexed')
        IMG = ind2gray(im,map);
        IMG = im2double(IMG);
    elseif strcmp(im_ctype, 'grayscale')
        IMG = im2double(im);
    else
        IMG = im;
    end
    
    axes(haxMAIN)
    colormap(haxMAIN,jet); % parula
    phMAIN = imagesc(IMG , 'Parent', haxMAIN);
              pause(.5)
    
    % imXlim = haxCCD.XLim;
    % imYlim = haxCCD.YLim;

    xdim = size(IMG,2); 
    ydim = size(IMG,1);

    
    
    %----------------------------------------------------
    %           SET USER-EDITABLE GUI VALUES
    %----------------------------------------------------
    % set(mainguih, 'Name', datafile);
    set(mainguih, 'Name', 'OptoTrack');
    % set(ROIIDh, 'String', int2str(1));
    set(haxMAIN, 'XLim', [1 xdim]);
    set(haxMAIN, 'YLim', [1 ydim]);
    %----------------------------------------------------
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'OptoTrack is ready!';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    %%
end




%----------------------------------------------------
%        IMPORT VIDEO PATH INFORMATION
%----------------------------------------------------
function getvid(boxidselecth, eventdata)
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Select video to import';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    if numel(mediapath) < 1
        [datafile, datapath, ~] = uigetfile({'*.mp4; *.mov'}, 'Select video.');
    end

    mediapath = [datapath datafile];    


    % READ VIDEO INTO FRAME DATA
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Reading video data...';
    memoboxH.String = memos;
    pause(.02)
    % ------

    VID = VideoReader(mediapath);				% import vid
    nf = get(VID, 'NumberOfFrames');			% get total number of vid frames

    v1 = read(VID, 1);

    f1 = mean(v1,3);				% get frame-1 data

    phVID = imagesc(f1 , 'Parent', haxMAIN);


    xdim = size(v1,2); 
    ydim = size(v1,1);
    set(haxMAIN, 'XLim', [1 xdim]);
    set(haxMAIN, 'YLim', [1 ydim]);
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Done.';
    memoboxH.String = memos;
    pause(.02)
    % ------


end




%----------------------------------------------------
%        GET FRAMES OUTPUT STRUCTURE FROM IRframes()
%----------------------------------------------------
function getframes(boxidselecth, eventdata)
    
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Running IRframes() function...';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    [outputstructure] = IRframes(VID, mediapath);
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Retrieved output structure.';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    disp(outputstructure)

end





%----------------------------------------------------
%        RUN TRACKING FUNCTION IRtrack()
%----------------------------------------------------
function runtracking(boxidselecth, eventdata)
    
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Running IRtrack() function...';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    IRtrack(outputstructure);

end




%----------------------------------------------------
%        RUN CUSTOM FUNCTION IRtrack()
%----------------------------------------------------
function runcustom(boxidselecth, eventdata)
    
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Running IRtrack() function...';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    IRtrack(VID, mediapath);

end









%----------------------------------------------------
%        IMAGE SIDER CALLBACK
%----------------------------------------------------
function mainslider(hObject, eventdata)

    slideVal = ceil(cmapsliderH.Value);

    ccmap = parula;
    
    % cmmap = [zeros(slideVal,3); ccmap(end-40:end,:)];
    cmmap = [zeros(slideVal,3); ccmap(slideVal:end,:)];
    
    colormap(haxMAIN,cmmap)

    drawnow
end







%% GET VIDEO FILENAME USING GUI PROMPT
%{


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

%}
end
%% EOF