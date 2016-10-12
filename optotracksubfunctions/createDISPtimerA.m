function ta = createDISPtimerA()

    Time      = 30;
    Hz        = 250;
    TimeHz    = Time*Hz;
    FreqHz    = 10;
    Volts     = 5;
    T         = linspace(0, 1, Hz);
    P        = (sin(2*pi*FreqHz*T) +1) .* (Volts/2);

    voltMatrix   = repmat(P, 1, Time);
    voltMatrix(end) = 0;


    nt = 1;

    ta = timer;
    ta.UserData = {voltMatrix, nt};
    ta.StartFcn = @DAQTimerStart;
    ta.TimerFcn = @genDAQoutput;
    ta.StopFcn = @DAQTimerCleanup;
    ta.Period = 1/Hz;
    ta.StartDelay = 0;
    ta.TasksToExecute = TimeHz;
    ta.ExecutionMode = 'fixedSpacing';

end 


function DAQTimerStart(mTimer,~)
    disp('Starting DAQ timer A.');
end


function genDAQoutput(mTimer,~)

    uData = mTimer.UserData;
    vMx = uData{1};
    nt = uData{2};
    disp( vMx(1,nt) )
    nt = nt+1;
    mTimer.UserData = {vMx, nt};

end

function DAQTimerCleanup(mTimer,~)
    disp('Stopping DAQ timer A.')
    % delete(mTimer)
end