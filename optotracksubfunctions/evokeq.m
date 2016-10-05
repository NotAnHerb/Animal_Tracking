function [daqstatus] = evokeq(x)


for t=1:1000
    
    disp(x(t))
    
    pause(.5)

end

daqstatus = 'finished';






%% function [] = evokeq(mTimer,~)
% 
%     FreqHz   = 10;
%     Time     = 30;
%     Volts    = 5;
%     Hz       = 250;
% 
%     T        = linspace(0, 1, Hz);
%     P        = (square(2*pi*FreqHz*T) + 1) .* (Volts/2);
% 
%     yV       = repmat(P, 1, Time);
%     yV(end)  = 0;
%     TimeHz   = Time*Hz;
% 
%     lbj      = labJackU6
% 
%     open(lbj);
% 
%     channel             = 1;
%     lbj.SampleRateHz    = Hz * 4;
%     lbj.verbose         = 0;
% 
%     addChannel(lbj,[0 1],[10 10],['s' 's']);
% 
% 
% 
%     streamConfigure(lbj);
%     startStream(lbj);
%     analogOut(lbj,channel,0)
%     analogOut(lbj,channel,5)
%     analogOut(lbj,channel,1)
% 
%     daqstatus = 'started';
%     
%     for t=1:TimeHz; analogOut(lbj,channel,yV(t)); pause(1/Hz); end
% 
%     daqstatus = 'finished';
    
    
%%
    
end


% pmode start 1
% 
% PP(1).Pnum     = 2;
% PP(1).ResHz    = 250;
% PP(1).Type     = 'square';
% PP(1).FreqHz   = 10;
% PP(1).Time     = 30;
% PP(1).Volts    = 5;
% PP(1).Phase    = 0;
% PP(1).PLen     = 1 / PP(1).FreqHz / 2 * 1000;
% PP(1).PDelay   = 0;
% PP(1).xT       = [];
% PP(1).yV       = [];
% 
% Pulses = PP;
% A  = PP(1).Volts;
% F  = PP(1).FreqHz; 
% P  = PP(1).Phase; 
% Hz = PP(1).ResHz;
% S  = PP(1).Time;
% T = linspace(0, 1, Hz);
% P = (square(2*pi*F*T) + 1) .* (A/2);
% T = linspace(0, S, Hz*S);
% P = repmat(P, 1, S);
% Pulses.xT = T;
% Pulses.yV = P;
% 
% Pulses.yV(end) = 0;
% 
% lbj=labJackU6
% open(lbj);
% lbj.SampleRateHz = Pulses(1).ResHz * 4;
% lbj.verbose = 0;
% addChannel(lbj,[0 1],[10 10],['s' 's']);
% channel = 1
% streamConfigure(lbj);
% startStream(lbj);
% analogOut(lbj,channel,0)
% analogOut(lbj,channel,5)
% analogOut(lbj,channel,1)
% for t=1:Pulses(1).Time*Pulses(1).ResHz; analogOut(lbj,channel,Pulses(1).yV(t)); pause(1/Pulses(1).ResHz); end;
