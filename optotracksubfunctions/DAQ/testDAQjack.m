function [Pulses] = testDAQjack(Pulses)

%% BUILD PULSE PATTERNS

Pulses.Patterns = 2;
Pulses.ResHz = 250;
Pulses.FreqHz = 10;
Pulses.Time = 5;
Pulses.Volts = 5;
Pulses.Phase = 0;
Pulses.Type = 'square'; % 'square' or 'sine'
Pulses.T = [];
Pulses.Y = [];


Pulses.T = 0 : 1/Pulses.ResHz : Pulses.Time-1/Pulses.ResHz ;

A = Pulses.Volts;
F = Pulses.FreqHz; 
P = Pulses.Phase; 
T = Pulses.T;

Pulses.Y = sin(2*pi*F * T + P) .* A/2 + A/2;



figure
subplot(2,2,1)
plot(T,Pulses.Y)

subplot(2,2,2)
plot(xt1,yv1)

subplot(2,2,3)
plot(xt2,yv2)

subplot(2,2,4)
plot(xt12,yv12)


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


for t = 1:TimeValue2*SampleRateHz

    analogOut(lbj,channel,yv2(t));

    pause(1/SampleRateHz)

end


voltageSet = 0;
analogOut(lbj,channel,voltageSet)

% stopStream(lbj);
% clear lbj














end