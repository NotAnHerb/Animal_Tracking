function [] = exampleProgram(obj, src, event)

    % MAKE TWO ARRAYS OF VOLTAGE VALUES - SAVE AS ROWS IN 1 MATRIX
    Time      = 30;
    Hz        = 250;
    TimeHz    = Time*Hz;
    FreqHz    = 10;
    Volts     = 5;
    T         = linspace(0, 1, Hz);
    P1        = (square(2*pi*FreqHz*T) + 1) .* (Volts/2);
    P2        = (2*pi*FreqHz*T + 1) .* (Volts/2);

    voltMatrix(1,:)   = repmat(P1, 1, Time);
    voltMatrix(2,:)   = repmat(P2, 1, Time);
    voltMatrix(:,end) = 0;

    % voltMatrix has 2 rows of 7500 values each
    
    roi = 1;
    
	for t = 1:TimeHz


        % im = getCameraImage;
        im = rand;

        roiOld = roi;

        roi = determineROI(im, roiOld);


        if roi ~= roiOld

           % sendtodaq(voltMatrix(roi,:), Hz, 0)
           
           disp(voltMatrix(roi,t))

        end
        
        if t == TimeHz
            
            % sendtodaq(0, .1, 1)
            
        end
        
        pause(1/Hz)

	end

end



function [roi] = determineROI(im, roiOld)

    if im > .99 && roiOld == 1

        roi = 2;

    elseif im > .99 && roiOld == 2

        roi = 1;
        
    else
        
        roi = roiOld;

    end

end




function [] = sendtodaq(voltArray, Hz, stop)


v = 1;
while v <= numel(voltArray) && stop ~=1

    disp(voltArray(v))

    v = v+1;
    pause(1/Hz)
end


end






