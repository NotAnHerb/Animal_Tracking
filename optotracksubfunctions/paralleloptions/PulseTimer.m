function t = PulseTimer()


secondsBreak = 1;
secondsBreakInterval = 5;
secondsPerHour = 60^2;
secondsWorkTime = 8*secondsPerHour;

t = timer;
t.UserData = secondsBreak;
t.StartFcn = @PTimerStart;
t.TimerFcn = @takeBreak;
t.StopFcn = @PTimerCleanup;
t.Period = secondsBreakInterval+secondsBreak;
t.StartDelay = t.Period-secondsBreak;
t.TasksToExecute = ceil(secondsWorkTime/t.Period);
t.ExecutionMode = 'fixedSpacing';
end 




function PTimerStart(mTimer,~)

% By default, the timer object passes itself and event data to the callback function. 
% Here the function disregards the event data.



secondsPerMinute = 60;
secondsPerHour = 60*secondsPerMinute;
str1 = 'Starting Ergonomic Break Timer.  ';
str2 = sprintf('For the next %d hours you will be notified',...
    round(mTimer.TasksToExecute*(mTimer.Period + ...
    mTimer.UserData)/secondsPerHour));
str3 = sprintf(' to take a %d second break every %d minutes.',...
    mTimer.UserData, (mTimer.Period - ...
    mTimer.UserData)/secondsPerMinute);
disp([str1 str2 str3])
end


function takeBreak(mTimer,~)
disp('Take a 30 second break.')
end



function PTimerCleanup(mTimer,~)
disp('Stopping Ergonomic Break Timer.')
delete(mTimer)
end