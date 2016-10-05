function tb = createDAQtimerB()

    Time      = 30;
    Hz        = 250;
    TimeHz    = Time*Hz;
    FreqHz    = 10;
    Volts     = 5;
    T         = linspace(0, 1, Hz);
    P        = (square(2*pi*FreqHz*T) + 1) .* (Volts/2);

    voltMatrix   = repmat(P, 1, Time);
    voltMatrix(end) = 0;

    nt = 2;

    tb = timer;
    tb.UserData = {voltMatrix, nt};
    tb.StartFcn = @DAQTimerStart;
    tb.TimerFcn = @genDAQoutput;
    tb.StopFcn = @DAQTimerCleanup;
    tb.Period = 1/Hz;
    tb.StartDelay = 0;
    tb.TasksToExecute = TimeHz;
    tb.ExecutionMode = 'fixedSpacing';

end 


function DAQTimerStart(mTimer,~)
    disp('Starting DAQ timer B.');
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
    disp('Stopping DAQ timer B.')
    delete(mTimer)
end