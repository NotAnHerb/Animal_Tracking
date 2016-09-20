function [] = IRtrack_outline(outputstructure)
%TRACK'S OUTLINE of ANIMAL


%%
%makes figure of image and allows user to draw an ROI over that image

%inputs into GUI -- ROI number, rule (fx) associated with each ROI -- it
%would also be nice if the program didn't crash if you had to redraw the
%roi -- ie you could redo this function for each ROI if necessary (this
%will be useful moving between animals where the testing arena might move
%ever so slightly) -- in this case, you could plot previous ROIs and move
%them a little bit

imagesc(outputstructure.image{1}) %plots first image from a recorded file

[STIM_region, STIM_region_x, STIM_region_y] = roipoly; %allows user to plot polygonal ROI
hold on
plot(STIM_region_x, STIM_region_y,'linewidth',10) %show ROI on plot
pause
close all

%%

close all

%this won't be necessary with live video
n_frames = length(outputstructure.xy); 



%size of image -- this could be inputed in the gui
[iy, ix] = size(outputstructure.image{1}); 

%radius to consider around centerpoint
r = 10;

%this can be a value that we can set before the livetrack begins -- 
%will be different for different cameras / setups -- should be inputed into GUI
threshold = 98; 

%other inputs into GUI -- how to track the animal (ie head, centerpoint,
%and point of the animal, etcetera -- we can have different functions for
%all of these)



for i = 1:2:n_frames

    %thresholds image
    image = outputstructure.image{i};
    image(image<(prctile(reshape(image,[],1),threshold))) = 0; 
    image(image>=(prctile(reshape(image,[],1),threshold))) = 1;
   
    %find regions with contiguous pixels and makes 'objects'
    CC = bwconncomp(image);
    temp = regionprops(CC, 'Area','centroid',...
        'majoraxislength','minoraxislength',...
        'Orientation');
    %and picks only the largest one
    L = labelmatrix(CC);
    [M I] = max([temp.Area]);
    BW2 = ismember(L,I);
    

    BW{i} = BW2; %saves thresholded image
    BW_region(i) = temp(I); %saves regionprops for large object in image


    
    cx=BW_region(i).Centroid(1);cy=BW_region(i).Centroid(2);
    
    [x_3,y_3]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
    c_mask_2=((x_3.^2+y_3.^2)<=r^2);
    
    center_mask{i} = c_mask_2;



 imagesc(BW{i})
   hold on

    if mean(mean(center_mask{i}.*STIM_region)) > 0
        plot(STIM_region_x, STIM_region_y,'y')
        %insert in_ROI function here
    else
        plot(STIM_region_x, STIM_region_y,'k')
      
    end
    

   
  
 
   
   %plots a video of the thresholded image, the user_defined ROI, the
   %centroid of the head_mask, and changes the color of the ROI is the
   %animal is detected inside it
   
   %would be cool if in the live-tracking mode -- if we could visualize the
   %ROIs overlaid on the live video as well as whether the animal is being
   %detected in a given ROI ... sort of like these videos
   
   %plot video and tracking
  
   
   scatter(BW_region(i).Centroid(1),BW_region(i).Centroid(2),'k')
   

   pause(.05)
    
end


%won't be necessary in function
%clearvars -except BW Test head_center head_mask STIM_region STIM_region_x STIM_region_y
