function [Pulses] = makePulses(PP)
%% makePulses.m
%{
% PP(1).Pnum   = 2;          % (int) number of different pulse patterns to generate
% PP(1).ResHz  = 250;        % (ms)  pulse sampling rate
% PP(1).Type   = 'square';   % (str) wave type: 'square' or 'sine'
% PP(1).FreqHz = 10;         % (int) number of pulses per second
% PP(1).Time   = 5;          % (sec) total length of time pulses are generated
% PP(1).Volts  = 5;          % (dub) output voltage maximum pulse amplitude
% PP(1).Phase  = 0;          % (rad) phase to start sine wave pulse
% PP(1).PLen   = 0;          % (ms)  single square wave pulse on-duration (< 1/FreqHz)
% PP(1).PDelay = 0;          % (ms)  delay between square wave pulse bursts (< FreqHz*PLen)
% PP(1).xT = [];             % generated: X-axis timepoints
% PP(1).yV = [];             % generated: Y-axis voltage amplitude values


clc; close all; clear;


PP(1).Pnum     = 2;
PP(1).ResHz    = 250;
PP(1).Type     = 'square';
PP(1).FreqHz   = 10;
PP(1).Time     = 5;
PP(1).Volts    = 5;
PP(1).Phase    = 0;
PP(1).PLen     = 1 / PP(1).FreqHz / 2 * 1000;
PP(1).PDelay   = 0;
PP(1).xT       = [];
PP(1).yV       = [];

PP(2).Pnum     = 2;
PP(2).ResHz    = 250;
PP(2).Type     = 'sine';
PP(2).FreqHz   = 10;
PP(2).Time     = 5;
PP(2).Volts    = 5;
PP(2).Phase    = 0;
PP(2).PLen     = 0;
PP(2).PDelay   = 0;
PP(2).xT       = [];
PP(2).yV       = [];
%}

%%

Pulses = PP;

for nn = 1:PP(1).Pnum
    
    if strcmp(PP(nn).Type,'square') == 1
        
        A  = PP(nn).Volts;
        F  = PP(nn).FreqHz; 
        P  = PP(nn).Phase; 
        Hz = PP(nn).ResHz;
        S  = PP(nn).Time;
        
        
        T = linspace(0, 1, Hz);
        
        P = (square(2*pi*F*T) + 1) .* (A/2);
        
        T = linspace(0, S, Hz*S);
        
        P = repmat(P, 1, S);
        

        Pulses(nn).xT = T;
        
        Pulses(nn).yV = P;
        
    else
    
        A  = PP(nn).Volts;
        F  = PP(nn).FreqHz; 
        P  = PP(nn).Phase; 
        Hz = PP(nn).ResHz;
        S  = PP(nn).Time;
        
        T = 0 : 1/Hz : S-1/Hz ;
        
        P = sin(2*pi*F * T + P) .* A/2 + A/2;

        Pulses(nn).xT = T;

        Pulses(nn).yV = P;
    
    
    end

end




fh44=figure('Units','normalized','OuterPosition',[.1 .1 .8 .6],'Color','w','MenuBar','none');


ax1 = subplot(2,2,1);
plot( Pulses(1).xT(1:PP(1).ResHz) , Pulses(1).yV(1:PP(1).ResHz))
ax1.YLim = [-1 6];

ax2 = subplot(2,2,2);
plot( Pulses(2).xT(1:PP(2).ResHz) , Pulses(2).yV(1:PP(2).ResHz))
ax2.YLim = [-1 6];

ax3 = subplot(2,2,3);
plot( Pulses(1).xT , Pulses(1).yV)
ax3.YLim = [-1 6];

ax4 = subplot(2,2,4);
plot( Pulses(2).xT , Pulses(2).yV )
ax4.YLim = [-1 6];

pause(2)


close(fh44)


%%
end