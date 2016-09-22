function varargout = optotrack(varargin)
%% optotrack.m - Optogenetics and Live Tracking Toolbox
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
%     optotrack() The optotrack program is run from optotrack.m that initializes 
%     a GUI interface, and strings together to several video processing functions. 
%     First it runs the IRframes() function to perform basic tracking. This involves 
%     finding the nth hottest pixels and takes their centroid as the location of the 
%     animal. Despite its simplicity, it works fairly well -- mostly tracking the 
%     animal's head due to the heat radiating off the headcap. It outputs tracking 
%     data (xy), speed (dL), as well as the first frame of the video (image) to draw 
%     ROIs. After that, IRtrack() function is called, which tracks the animal using 
%     some tools from MATLAB's image analysis toolbox.
%
%     This program allows users to import video data from an infrared camera and
%     track an animal within that video. Input is the filename of a video in
%     the MATLAB path and it outputs into a data structure:
%       xy -- x and y coordinates
%       dL -- speed
%       image -- matrix of first frame for ROI analysis later on
%     
% 
% Useage Definitions
% -----------------------------------------------------
% 
%     optotrack()
%         launches a GUI to perform live open field animal tracking
%  
% 
% 
% Example
% -----------------------------------------------------
% 
%    [Arena_Data.AUG09.LH1] = IRheattracking_3('080916_LHALHB_1.mp4')
%       It takes some time to run (minutes) so it is best to run in batches. 
% 
% 
% See Also
% -----------------------------------------------------
% >> web('https://github.com/NotAnHerb/Animal_Tracking')
% >> web('http://bradleymonk.com/optotrack')
% >> web('http://malinowlab.com')
% 
% 
% Attribution
% -----------------------------------------------------
% % Created by: Sage Aronson & Bradley Monk
% % Malinow Lab - UC San Diego
% % email: sage.r.aronson@gmail.com
% % brad.monk@gmail.com
% % website: malinowlab.com
% % 2016.09.01
%}
%----------------------------------------------------




%% ESTABLISH STARTING PATHS
clc; close all; clear; clear java;

disp('WELCOME TO OPTOTRACK - Optogenetics and Live Tracking Toolbox.')


global thisfilepath
thisfile = 'optotrack.m';
thisfilepath = fileparts(which(thisfile));
cd(thisfilepath);

fprintf('\n\n Current working path set to: \n % s \n', thisfilepath)

    
pathdir0 = thisfilepath;
pathdir1 = [thisfilepath '/optotrackmedia'];
pathdir2 = [thisfilepath '/optotracksubfunctions'];
gpath = [pathdir0 ':' pathdir1 ':' pathdir2];
addpath(gpath)

fprintf('\n\n Added folders to path: \n % s \n % s \n\n',pathdir0,pathdir1)


%% GET PATHS AND FILES

global datapath datafile mediapath VID outputstructure
datapath = '';
datafile = '';
mediapath = '';


 

%% ESTABLISH GLOBALS AND SET STARTING VALUES

global haxMAIN haxMINI memos memoboxH

global mainsliderh LTtrials LTframespertrial LTpixelthresh LTnpixels


%########################################################################
%%              MAIN ANALYSIS GUI WINDOW SETUP 
%########################################################################


%----------------------------------------------------
%           MAIN GUI WINDOW
%----------------------------------------------------

% mainguih.CurrentCharacter = '+';
mainguih = figure('Units', 'normalized','Position', [.05 .05 .9 .82], 'BusyAction',...
    'cancel', 'Name', 'OptoTrack', 'Tag', 'OptoTrack','Visible', 'Off'); %, ...
    %'KeyPressFcn', {@keypresszoom,1});
    
set(mainguih, 'Visible', 'Off');    
    
%----------------------------------------------------
%           MAIN IMAGE AXES PANEL
%----------------------------------------------------

MAXpanelH = uipanel('Title','Viewer','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.01 0.01 0.45 0.80]); % 'Visible', 'Off',

haxMAIN = axes('Parent', MAXpanelH, 'NextPlot', 'Add',...
    'Position', [0.01 0.02 0.95 0.93], 'PlotBoxAspectRatio', [1 1 1],...
    'XColor','none','YColor','none');

mainsliderh = uicontrol('Parent', MAXpanelH, 'Units', 'normalized','Style','slider',...
	'Max',50,'Min',1,'Value',10,'SliderStep',[.1 .2],...
	'Position', [0.01 0.96 0.95 0.03], 'Callback', @mainslider);



%----------------------------------------------------
%           MEMO CONSOLE GUI WINDOW
%----------------------------------------------------

memopanelH = uipanel('Title','Memo Log ','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.01 0.82 0.45 0.17]); % 'Visible', 'Off',


memos = {' Welcome to OptoTrack', ' ',...
         ' Import video media to start', ' ', ...
         ' ', ' ', ...
         ' ', ' '};

memoboxH = uicontrol('Parent',memopanelH,'Style','listbox','Units','normalized',...
        'Max',8,'Min',0,'Value',8,'FontSize', 13,'FontName', 'FixedWidth',...
        'String',memos,'FontWeight', 'bold',...
        'Position',[.02 .02 .96 .96]);  



%----------------------------------------------------
%           MINI DATA AXES PANEL
%----------------------------------------------------

DATApanelH = uipanel('Title','Data Viewer','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.47 0.01 0.52 0.23]); % 'Visible', 'Off',

haxMINI = axes('Parent', DATApanelH, 'NextPlot', 'replacechildren',...
    'FontSize', 8,'Color','none',...
    'Position', [0.03 0.08 0.47 0.90]); 

haxMINIL = axes('Parent', DATApanelH, 'NextPlot', 'replacechildren',...
    'FontSize', 8,'Color','none',...
    'Position', [0.52 0.08 0.47 0.90]); 



%----------------------------------------------------
%           LIVE VIDEO TRACKING PANEL
%----------------------------------------------------
LivePanelH = uipanel('Title','Live Tracking','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.47 0.25 0.17 0.36]); % 'Visible', 'Off',


livetrackh = uicontrol('Parent', LivePanelH, 'Units', 'normalized', ...
    'Position', [0.05 0.80 0.90 0.15], 'FontSize', 11, 'String', 'Live Tracking Test',...
    'Callback', @livetracktest); 


uicontrol('Parent', LivePanelH, 'Style', 'Text', 'Units', 'normalized', 'HorizontalAlignment','right',...
    'Position', [0.01 0.69 0.48 0.09], 'FontSize', 11,'String', 'Total Trials:');
LTtrials = uicontrol('Parent', LivePanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.55 0.70 0.35 0.09], 'FontSize', 11); 

uicontrol('Parent', LivePanelH, 'Style', 'Text', 'Units', 'normalized','HorizontalAlignment','right',...
    'Position', [0.01 0.59 0.48 0.09], 'FontSize', 11,'String', 'Frames per Trial:');
LTframespertrial = uicontrol('Parent', LivePanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.55 0.60 0.35 0.09], 'FontSize', 11); 

uicontrol('Parent', LivePanelH, 'Style', 'Text', 'Units', 'normalized', 'HorizontalAlignment','right',...
    'Position', [0.01 0.49 0.48 0.09], 'FontSize', 11,'String', 'Pixel Threshold:');
LTpixelthresh = uicontrol('Parent', LivePanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.55 0.50 0.35 0.09], 'FontSize', 11);

uicontrol('Parent', LivePanelH, 'Style', 'Text', 'Units', 'normalized', 'HorizontalAlignment','right',...
    'Position', [0.01 0.39 0.48 0.09], 'FontSize', 11,'String', 'Pixels to Average:');
LTnpixels = uicontrol('Parent', LivePanelH, 'Style', 'Edit', 'Units', 'normalized', ...
    'Position', [0.55 0.40 0.35 0.09], 'FontSize', 11);


set(LTtrials, 'String', int2str(5));
set(LTframespertrial, 'String', int2str(3));
set(LTpixelthresh, 'String', int2str(0.05));
set(LTnpixels, 'String', int2str(100));


%----------------------------------------------------
%           IMPORTED VIDEO PROCESSING PANEL
%----------------------------------------------------
IPpanelH = uipanel('Title','Video Processing','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.47 0.62 0.17 0.36]); % 'Visible', 'Off',


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
%          GUI PANEL 4
%----------------------------------------------------
GUIpanel4H = uipanel('Title','GUI PANEL 4','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.65 0.25 0.17 0.36]); % 'Visible', 'Off',




%----------------------------------------------------
%           GUI PANEL 5
%----------------------------------------------------
GUIpanel5H = uipanel('Title','GUI PANEL 5','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.65 0.62 0.17 0.36]); % 'Visible', 'Off',




%----------------------------------------------------
%          GUI PANEL 6
%----------------------------------------------------
GUIpanel6H = uipanel('Title','GUI PANEL 6','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.83 0.25 0.16 0.36]); % 'Visible', 'Off',




%----------------------------------------------------
%           GUI PANEL 7
%----------------------------------------------------
GUIpanel7H = uipanel('Title','GUI PANEL 7','FontSize',10,...
    'BackgroundColor',[.95 .95 .95],...
    'Position', [0.83 0.62 0.16 0.36]); % 'Visible', 'Off',






%%
%----------------------------------------------------
%     INITIALIZE TOOLBOX PARAMETERS
%----------------------------------------------------


axes(haxMAIN)

OPTOTRACKgo()


pause(.5)
set(mainguih, 'Visible', 'On');








% -----------------------------------------------------------------------------
%%                     GUI TOOLBOX FUNCTIONS
% -----------------------------------------------------------------------------




%----------------------------------------------------
%        OPTOTRACK GO!
%----------------------------------------------------
function OPTOTRACKgo()
    
    
    % set(mainguih, 'Visible', 'On');
    
    
    memolog('Welcome to OptoTrack')
    memolog('Optogenetics & Behavior Analysis Toolbox')
    memolog('Loading GUI interface...')
    
    
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
    imshow(im , 'Parent', haxMAIN);
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
        
    memolog('OptoTrack is ready!')
    
    drawnow
    
    %%
end




%----------------------------------------------------
%        MEMO LOG UPDATE
%----------------------------------------------------
function memolog(spf)

    memos(1:end-1) = memos(2:end);
    memos{end} = spf;
    memoboxH.String = memos;
    pause(.02)

end


%----------------------------------------------------
%        IMPORT VIDEO PATH INFORMATION
%----------------------------------------------------
function getvid(boxidselecth, eventdata)
        
    memolog('Select video to import')
    
    if numel(mediapath) < 1
        [datafile, datapath, ~] = uigetfile({'*.mp4; *.mov'}, 'Select video.');
    end

    mediapath = [datapath datafile];    


    % READ VIDEO INTO FRAME DATA    
    memolog('Reading video data...')

    VID = VideoReader(mediapath);				% import vid
    nf = get(VID, 'NumberOfFrames');			% get total number of vid frames

    v1 = read(VID, 1);

    f1 = mean(v1,3);				% get frame-1 data

    phVID = imagesc(f1 , 'Parent', haxMAIN);


    xdim = size(v1,2); 
    ydim = size(v1,1);
    set(haxMAIN, 'XLim', [1 xdim]);
    set(haxMAIN, 'YLim', [1 ydim]);
        
    memolog('Done reading video data.')


end




%----------------------------------------------------
%        GET FRAMES OUTPUT STRUCTURE FROM IRframes()
%----------------------------------------------------
function getframes(boxidselecth, eventdata)
        
    memolog('Running IRframes() function.')
    memolog('Please wait...')
    
    
    
    [outputstructure] = IRframes(VID, mediapath);
    
    fnams = fieldnames(outputstructure);

    
    
    % ---- This is all just memo log stuff ---
    memolog('Retrieved output structure.')

    disp(outputstructure)
    
    spf0 = 'outputstructure.';
    spf1 = ['  '... 
    fnams{1} '     '...
    num2str(size(outputstructure.(fnams{1}))) '  '...
    class(outputstructure.(fnams{1}))...
    ];
    spf2 = ['  '... 
    fnams{2} '     '...
    num2str(size(outputstructure.(fnams{2}))) '  '...
    class(outputstructure.(fnams{2}))...
    ];
    spf3 = ['  '... 
    fnams{3} '  '...
    num2str(size(outputstructure.(fnams{3}))) '  '...
    class(outputstructure.(fnams{3}))...
    ];

    memolog('  ')
    memolog(spf0)
    memolog(spf1)
    memolog(spf2)
    memolog(spf3)
    memolog('  ')
    memolog('Done!')
    % -----------------------------------------
    
end





%----------------------------------------------------
%        RUN TRACKING FUNCTION IRtrack()
%----------------------------------------------------
function runtracking(boxidselecth, eventdata)
    
    
    memolog('Running IRtrack() function.')
    memolog('Please wait...')
    
    IRtrack(outputstructure);
    
    
    memolog('Done!')

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

    slideVal = ceil(mainsliderh.Value);

    ccmap = parula;
    
    % cmmap = [zeros(slideVal,3); ccmap(end-40:end,:)];
    cmmap = [zeros(slideVal,3); ccmap(slideVal:end,:)];
    
    colormap(haxMAIN,cmmap)

    drawnow
end





%----------------------------------------------------
%        GET FRAMES OUTPUT STRUCTURE FROM IRframes()
%----------------------------------------------------
function livetracktest(boxidselecth, eventdata)
    
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Running livetracking() function test...';
    memoboxH.String = memos;
    pause(.02)
    % ------
    
    
    trials = str2num(LTtrials.String);
    framespertrial = str2num(LTframespertrial.String);
    pixelthresh = str2num(LTpixelthresh.String);
    npixels = str2num(LTnpixels.String);
     

    livetracking(mainguih, haxMAIN, trials, framespertrial, pixelthresh, npixels);
    
    % ------  
    memos(1:end-1) = memos(2:end);
    memos{end} = 'Finished running livetracking test.';
    memoboxH.String = memos;
    pause(.02)
    % ------

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