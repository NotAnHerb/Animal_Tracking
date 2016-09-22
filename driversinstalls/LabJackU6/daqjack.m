function [] = daqjack(varargin)

% clc; close all; clear;


SampleRateHz = 250;
TimeValue = 10;
freq = 20;
voltageSet = 5;

xt = 0:(1/SampleRateHz):TimeValue;
yt = sin(2*pi*freq*xt);

yv = yt .* voltageSet/2 + voltageSet/2;

figure
subplot(2,1,1)
plot(xt,yv)

xt1 = xt(1:round(numel(xt)/TimeValue));
yv1 = yv(1:round(numel(yv)/TimeValue));

subplot(2,1,2)
plot(xt1,yv1)

pause(4)


LJDAQ_SampleRateHz = SampleRateHz*4;

% Example: labJackU6: version 1.0

lbj=labJackU6

pause(.2)

% devInfo = getInfo(lbj)

open(lbj);

pause(.2)

lbj.SampleRateHz = LJDAQ_SampleRateHz;

lbj.verbose = 0; % Set this to 1 if you want to see error warnings

addChannel(lbj,[0 1],[10 10],['s' 's']);

channel = 1;            % 0 or 1

streamConfigure(lbj);

pause(.2)

startStream(lbj);



for t = 1:TimeValue*SampleRateHz

    analogOut(lbj,channel,yv(t));

    pause(1/SampleRateHz)

end


voltageSet = 0;
analogOut(lbj,channel,voltageSet)

stopStream(lbj);

clear lbj

end

