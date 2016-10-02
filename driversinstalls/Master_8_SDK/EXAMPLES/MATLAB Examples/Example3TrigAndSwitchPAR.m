
% Example 3: Click to trigger channels, and to switch paradigms
%
% step 1: connect the PC to Master-8
% Step 2: set paradigm #3: Set all channels in TRAIN mode, with I=50 msec, and 20 pulses per train
% Step 3: set paradigm #4: Set all channels in TRAIN mode, with I=200 msec, and 8 pulses per train
% Step 4: Loop: Write: 13 - to switch to paradigm 3
% 		write: 14 - to switch to paradigm 4
% 		write the channel number that you want to trigger (1 to 8)
%		write 99 to exit
%------------------------------------


%This is a sample for declaring variables.
cmTrain = 2;

%step 1: Connect the PC to Master-8 first. Connect return true on success connection.

Master8=actxserver ('AmpiLib.Master8'); %Create COM Automation server
if ~(Master8.Connect),
    h=errordlg('Can''t connect to Master8!','Error');
    beep;
    uiwait(h);
    delete(Master8); %Close COM
    return;
end;
%------------------------------------

%Step 2:  First switch to paradigm 3, clear it, and set all parameters of all 8 channels

Master8.ChangeParadigm( 3);		  %switch to paradigm #3
Master8.ClearParadigm;				%clear present paradigm (#3)

% the following loop sets all 8 channels to the TRAIN mode
% with the parameters: Di=200 usec., Ii = 50 msec and Mi = 20 pulses per train.

for i=1:1:8,	%loop 8 times, for all 8 channels
    Master8.SetChannelInterval( i, 50e-3);       %Ii = 50 millisec.
    Master8.SetChannelDuration( i, 200e-6);     %Di = 200 microsec.
    Master8.SetChannelM( i, 20);                %Mi = 20 pulses per train
    Master8.ChangeChannelMode( i, cmTrain);	%set channel i to the TRAIN mode
end;
%------------------------------------

%Step 3: Now switch to paradigm 4 and copy paradigm 3 to paradigm 4 (it does not affect paradigm 3)

Master8.ChangeParadigm(  4);			%switch to paradigm #3
Master8.CopyParadigm( 3, 4);			%copy paradigm 3 to paradigm 4

% the following loop sets the following modifications for paradim 4:
% Ii = 200 msec and Mi = 8 pulses per train.

for i=1:1:8,	%loop 8 times, for all 8 channels
    Master8.SetChannelInterval( i, 200e-3);	 %Ii = 200 millisec.
    Master8.SetChannelM( i, 8);              %Mi = 8 pulses per train
end;
%------------------------------------

%Step 4: Loop: Write what do you want to do (see the above options)

S=1; % restart S
while S~=99,

    S= inputdlg('WRITE the channel number you want to trig [1-8]. 13-switch to PAR 3. 14- switch to PAR 4. WRITE 99 to exit','inputdlg');
    if isempty(S), S=99;
    else, S= str2num(S{1}); % convert S to num
    end;

    switch S
        case 13                    %switch to paradigm #3
            Master8.ChangeParadigm( 3);
        case 14                    %switch to paradigm #4
            Master8.ChangeParadigm( 4);
        case {1,2,3,4,5,6,7,8}  %trigger channel S
            Master8.Trigger( S);
        case 99                    %exit
            h=msgbox('EXIT, Master-8 stores last parameters', 'Error');
            uiwait( h);
        otherwise	%Wrong Value
            h=msgbox('Wrong Value', 'Error');
            uiwait( h);
    end ;

end;
%------------------------------------

%Remember  to free memory by close/delete the COM
Master8.connected=0;
delete(Master8);
% -------------------





