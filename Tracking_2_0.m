n_frames = length(Test.xy);
tic

%image thresholding
for i = 1:n_frames
    image = Test.image{i};
    image(image<(prctile(reshape(image,[],1),98))) = 0; %thresholds the image (quick process) to only look at top 2% of pixels -- will only work with infrared camera
%     image(image>=(prctile(reshape(image,[],1),98))) = 1;
    border {i} = image; %saves thresholded image

end
toc

%%
close all
%image processing
for i = 1:n_frames
    
    BWdfill = imfill(border{i}, 'holes'); %fills in thresholded images
    BWdfill = bwareaopen(BWdfill,600,8); %excludes any region less than 600 pixels
    
    border2{i} = BWdfill; %saves as border2
 
end


%%
%make an arbitrary ROI
close all

figure

imagesc(border2{1})

[BW, xi, yi] = roipoly;
hold on

plot(xi,yi,'m')

[BW2, xi_2, yi_2] = roipoly;
plot(xi_2,yi_2,'y')

pause
close all
%%
%This code needs to track the animal's head and do some function when it
%detects the head inside of a user defined ROI(s)
%visualization of tracking data
close all
figure
for i = 1:n_frames
    
    %plots original image
%     subplot(4,1,1) 

%     imagesc(Test.image{i})
%     colormap('gray')
    
    %plots image as it is processed so far
    imagesc(border2{i});
    hold on
    
    
    s = regionprops(border2{i},'centroid','majoraxislength','minoraxislength',...
        'boundingbox','Orientation',...
        'Perimeter','FilledArea','convexhull','conveximage'); %saves a bunch of parameters in structure s
    
    
    
     %plots ellipsis around animal (code based on Steve Eddin's code:
    %http://blogs.mathworks.com/steve/2010/07/30/visualizing-regionprops-ellipse-measurements/)
    
    phi = linspace(0,2*pi,50);
    cosphi = cos(phi);
    sinphi = sin(phi);

    
    xbar = s(1).Centroid(1);
    ybar = s(1).Centroid(2);

    a = s(1).MajorAxisLength/2;
    b = s(1).MinorAxisLength/2;

    theta = pi*s(1).Orientation/180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];

    xy = [a*cosphi; b*sinphi];
    xy = R*xy;

    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;

    plot(x,y,'r','LineWidth',2);
    
    
    
    
    
    
    
    
    
    %plots ROI on image -- is maroon if animal is outside ROI, yellow if
    %animal is inside
 
    %makes mask from ROI polygon
    
    test_mat = poly2mask(xi,yi,480,640); %for ROI1
    test_mat_2 = poly2mask(xi_2,yi_2,480,640); %for ROI2
    test_elps = poly2mask(x,y,480,640); %for ellipsis
    
    
    
    
    
    
%     in_small = inpolygon(s(1).ConvexHull(:,1),s(1).ConvexHull(:,2),xi,yi); %inside small roi?
%     in_big = inpolygon(s(1).ConvexHull(:,1),s(1).ConvexHull(:,2),xi_2,yi_2); %inside large roi?

        
        %if there are non-zero elements of the overlapping matrix of the
        %thresholded image and the ROI then plot ROI in a given color
        
        %can also track base on the ellipsis drawn around the animal...

    if nnz(test_mat_2 & test_elps) > 0; %is animal in big ROI?
        plot(xi_2,yi_2,'y')
    else
        plot(xi_2,yi_2,'m')
    end
    
    if nnz(test_mat & test_elps) > 0;
        fill(xi,yi,'g')
    else
        plot(xi,yi,'m')
    end
    
    
    
    
    
    
    
    %plots centroid on animal
    scatter(s(1).Centroid(1),s(1).Centroid(2),'k');
    
   
    
 % plots rectange around animal
    
    %rectangle('position',s(1).BoundingBox)
    
   
    
 %plots major and minor axis -- major axis may help define "body
 %elongation" while minor axis may help us identify the tail of the animal
 %-- especially if we can take cross sections through the ellipsis
    
%     subplot(4,1,3)
%     scatter(i,s(1).MajorAxisLength,'b')
%     scatter(i,s(1).MinorAxisLength,'m')
%     hold on
    
    
    
    %plots perimeter
 
    %
    
    %in progress -plotting orientation of animal
    
%     subplot(4,1,4)
%     theta = s(1).Orientation;
%     rho = s(1).MajorAxisLength;
%     scatter(i,theta)
%     hold on
    
    pause(.01)
   
end


%%

%SMPs -- detection through movement -- may be useful later on for defining
%'freezing' behavior or characterizing an animal's movements in the FST
n_frames = length(Test.xy);
percentile = 98;

for i = 2:n_frames
 
    image2 = Test.image{i};
    image2(image2<(prctile(reshape(image2,[],1),percentile))) = 0;
    
    image1 = Test.image{i-1};
    image1(image2<(prctile(reshape(image1,[],1),percentile))) = 0;
     
     image = image2-image1;
     image(image > 1) = 100;
    
    image = flipdim(image,1);
   
    imagesc(image)
    set(gca,'YDir','normal') %should probably do this with all images as MATLAB inexplicably flips everything around
    pause(.01)
end



%%
%wrote code to find the border of an image before i realized matlab had an
%easier code all set up...clunky, but it works
for k = 1:1
    image = Test.image{k}; %get image from video
    image(image<(prctile(reshape(image,[],1),98))) = 0; %threshold at 98th percentile
    image(image>=(prctile(reshape(image,[],1),98))) = 100;
    
    [x y] = size(image);
    image3 = image;
    
    for i = 2:x-1
        for j = 2:y-1
            center_pt = image(i,j);
            surround_pts = mean(image(i-1:i+1,j-1:j+1));
            if center_pt == surround_pts;
                image3(i,j) = 0;
            else image3(i,j) = 100;
            end
        end
    end
    border{k} = image3;
end


        