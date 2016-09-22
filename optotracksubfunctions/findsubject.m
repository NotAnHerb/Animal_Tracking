function [] = findsubject(image)





    %thresholds image
    image(image<(prctile(reshape(image,[],1),threshold))) = 0; 
    image(image>=(prctile(reshape(image,[],1),threshold))) = 1;

    
    
    %find regions with contiguous pixels and makes 'objects'
    CC = bwconncomp(image);
    temp = regionprops(CC, 'Area','centroid','majoraxislength',...
                       'minoraxislength','Orientation');
                   
                   
    %and picks only the largest one
    L = labelmatrix(CC);
    
    [M, I] = max([temp.Area]);

    BW = ismember(L,I);      %saves thresholded image
    BW_region = temp(I);     %saves regionprops for large object in image


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


    xbar = BW_region.Centroid(1);
    ybar = BW_region.Centroid(2);

    a = BW_region.MajorAxisLength/2;
    b = BW_region.MinorAxisLength/2;

    theta = pi*BW_region.Orientation/180;
    
    R = [ cos(theta)   sin(theta)  -sin(theta)   cos(theta)];

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


    testing = mean(mean(c_mask_1 .* BW));


    %makes circular mask with radius r around x(2) y(2) -- outputs values
    %'testing2' which is the mean pixel value in that region


    cx=x(2);
    cy=y(2);
    
    [x_3,y_3]=meshgrid(-(cx-1):(ix-cx),-(cy-1):(iy-cy));
    
    
    c_mask_2=((x_3.^2+y_3.^2)<=r^2);


    testing2 = mean(mean(c_mask_2 .* BW));


    %whichever mask has a larger mean value is the head -- so make that value
    %'head_mask'

%     if testing > testing2
%         
%         head_mask = (c_mask_1.* BW);
%         
%     else
% 
%         head_mask = (c_mask_2.* BW);
%         
%     end
% 
%     
%     
%     
%     if mean(mean(STIM_region .* head_mask)) > 0 
% 
%         %some rule -- ie -- a pulse that goes through the DAC
% 
%     else
% 
% 
%     end



end