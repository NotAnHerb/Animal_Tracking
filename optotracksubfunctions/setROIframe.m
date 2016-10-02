function [masks, IMG, memos, varargout] = setROIframe(nmasks, haxMAIN, memos, memoboxH)




%% GET SINGLE CAMERA FRAME TO SET ROI MASKS

vidPos = [320 130 640 460];
imageType = 'rgb';

% out = imaqfind;
% for nn = 1:length(out)
%     stop(out(nn))
%     wait(out(nn));
%     delete(out(nn));
% end

% imaqtool
vidObj = videoinput('macvideo', 1, 'YCbCr422_1280x720'); % CHANGE THIS TO THERMAL DEVICE ID
% vidObj = videoinput('winvideo', 1, 'UYVY_720x480'); % default
src = getselectedsource(vidObj);


vidObj.LoggingMode = 'memory';
vidObj.ReturnedColorspace = imageType;
vidObj.ROIPosition = vidPos;


vidObj.TriggerRepeat = 1;
vidObj.FramesPerTrigger = 2;
triggerconfig(vidObj, 'manual');

start(vidObj);

trigger(vidObj);
[f1, ~] = getdata(vidObj, vidObj.FramesPerTrigger);

pause(.05)

trigger(vidObj);
[f2, ~] = getdata(vidObj, vidObj.FramesPerTrigger);

IMG = rgb2gray(f2(:,:,:,1));
IMG = im2double(IMG);


stop(vidObj); 
wait(vidObj);

out = imaqfind;
for nn = 1:length(out)
    stop(out(nn))
    wait(out(nn));
    delete(out(nn));
end



%% SET ROI MASK FROM SINGLE CAM IMAGE

imsz = size(IMG);

axes(haxMAIN)
ph1 = imagesc(IMG);
set(gca,'YDir','reverse')
haxMAIN.XLim = [1 size(IMG,2)];
haxMAIN.YLim = [1 size(IMG,1)];
hold on

axLims = axis;

% axes(hax2)
ph2 = scatter(1,1,100,'filled','MarkerFaceColor',[.9 .1 .1]);
axis(axLims)
hold on



memos = memologs(memos, memoboxH, 'Click on image to create polygon area.');
memos = memologs(memos, memoboxH, 'Right click and create mask to continue.');


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

memos = memologs(memos, memoboxH, 'Mask(s) set.');

axes(haxMAIN)
ph3 = imagesc(allmasks .* IMG);
set(gca,'YDir','reverse')
haxMAIN.XLim = [1 size(IMG,2)];
haxMAIN.YLim = [1 size(IMG,1)];
hold on


for mm = 1:nmasks

    ph4{mm} = plot(masks(mm).STIM_region_x, masks(mm).STIM_region_y,'linewidth',6);

end


pause(.001)
varargout = {ph1, ph2, ph3, ph4};

end