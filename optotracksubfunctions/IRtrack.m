function [] = IRtrack(outputstructure)
%TRACK'S ANIMAL'S HEAD


% this code is the 'meat' of the tracking software. 
% 
% it works by first
% thresholding the image to only look at the top 2% of pixels (more specific
% to IR imaging -- but could probably work with a white rat on a black
% background). 
% 
% after thresholding, it defines "objects" as contiguous pixels
% and only looks at the largest "object." 
% 
% it finds a point at the front and
% back of the animal using regionprops. 
% 
% only having these points is
% insufficient to track the animal as 1) we don't know which is the front or
% rear and 2) when the animal is curled, these points do not lie on the
% animal. 
% 
% to circumvent these issues, the program draws a circular mask with
% a defined radius at each point. the mean pixel value within each mask is
% calculated and the larger of the two is the head. (if this is not accurate
% enough, a weight can be assigned to the position previous defined as the
% head to minimize errors). 
% 
% it then uses this head_mask to define the
% animal's location and can trigger a function/event when the animal is
% within the user_defined ROI.

%the end result is a fast program that accurately tracks the head of an
%animal in real-time.

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

%%



%this won't be necessary with live video
n_frames = length(outputstructure.xy); 

%radius of circle program draws -- this could be inputed in the gui
%or it can be calculated once -- when we draw ROI
r = 60; 

%size of image -- this could be inputed in the gui
[iy, ix] = size(outputstructure.image{1}); 

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


    %uses regionprops to plot majoraxis, at the centroid, at the set
    %orientation -- note this can also draw an oval around the animal -- the
    %main output is x(1) y(1) and x(2) y(2) which are the points at either end
    %of the animal (roughly)


    %note it would be very easy to track the animal based on its centerpoint
    %instead of its head -- this function could be helpful for certain
    %experiments

        phi = linspace(0,2*pi,3);
        cosphi = cos(phi);
        sinphi = sin(phi);


        xbar = BW_region(i).Centroid(1);
        ybar = BW_region(i).Centroid(2);

        a = BW_region(i).MajorAxisLength/2;
        b = BW_region(i).MinorAxisLength/2;

        theta = pi*BW_region(i).Orientation/180;
        R = [ cos(theta)   sin(theta)
             -sin(theta)   cos(theta)];

        xy = [a*cosphi; b*sinphi];
        xy = R*xy;

        x = xy(1,:) + xbar;
        y = xy(2,:) + ybar;

        x = x(1:2);
        y = y(1:2);


    %makes circular mask with radius r around x(1) y(1) -- outputs values
    %'testing' which is the mean pixel value in that region

        cx=x(1);cy=y(1);
        [x_3,y_3]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
        c_mask_1=((x_3.^2+y_3.^2)<=r^2);


        testing = mean(mean(c_mask_1 .* BW{i}));


    %makes circular mask with radius r around x(2) y(2) -- outputs values
    %'testing2' which is the mean pixel value in that region


        cx=x(2);cy=y(2);
        [x_3,y_3]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
        c_mask_2=((x_3.^2+y_3.^2)<=r^2);


        testing2 = mean(mean(c_mask_2 .* BW{i}));


    %whichever mask has a larger mean value is the head -- so make that value
    %'head_mask'

        if testing > testing2
            head_mask{i} = (c_mask_1.* BW{i});
        else

            head_mask{i} = (c_mask_2.* BW{i});
        end


        head_center{i} = regionprops(head_mask{i},'centroid');


        if mean(mean(STIM_region .* head_mask{i})) > 0 

            %some rule -- ie -- a pulse that goes through the DAC

        else


        end





       %plots a video of the thresholded image, the user_defined ROI, the
       %centroid of the head_mask, and changes the color of the ROI is the
       %animal is detected inside it

       %would be cool if in the live-tracking mode -- if we could visualize the
       %ROIs overlaid on the live video as well as whether the animal is being
       %detected in a given ROI ... sort of like these videos

       %plot video and tracking
    % %    imagesc(BW{i})
    % %    hold on
    % %    plot(STIM_region_x, STIM_region_y,'k')
    % %    scatter(head_center{i}.Centroid(1),head_center{i}.Centroid(2),'k')
    % %    
    % %    if mean(mean(STIM_region.*head_mask{i})) > 0
    % %        plot(STIM_region_x, STIM_region_y,'y')
    % %    else
    % %    end
    % %    
    % %    pause(.05)

    end





end
%won't be necessary in function
%clearvars -except BW Test head_center head_mask STIM_region STIM_region_x STIM_region_y
