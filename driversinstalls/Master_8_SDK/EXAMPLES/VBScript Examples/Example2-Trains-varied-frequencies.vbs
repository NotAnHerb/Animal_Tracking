
' Example 2: Run 6 sequences TRAINS, with decreased interval times from each train to the following one.
'
' step 1: connect the PC to Master-8
' Step 2: switch to paradigm 4, set channel 2 to the TRAIN mode, and set the time parameters of channel 2
' Step 3: Loop 6 times. each time decrease the interval of channel 2 by 10 msec. 
'         Trigger channel 2 and wait 1000 msec before triggering the next TRAIN
'------------------------------------


const  cmTrain = 2


'step 1: Connect the PC to Master-8 first. Connect return true on success connection.

set Master8=CreateObject ("AmpiLib.Master8")
if not Master8.Connect then 
  Msgbox "Can't connect to Master8!"
  close
End If
'------------------------------------


'Step 2: Switch to paradigm 4, clear this paradigm, set channel 2 to the TRAIN mode
' Set D2=200 usec., M2 = 8 pulses per train, and first I2=100 msec.

Master8.ChangeParadigm 4			'switch to paradigm #4
Master8.Clearparadigm				'clear present paradigm (#4)
Master8.ChangeChannelMode 2,cmTrain		'set channel 2 to the TRAIN mode
Master8.SetChannelDuration 2,200e-6		'D2 = 200 usec
Master8.SetChannelM 2,8				'M2 = 8 pulses per train
I2=100e-3					'start with I2 = 100 msec
'------------------------------------


' Step 3: Loop 6 times. each time decrease the interval of channel 2 by 10 msec. 
'         Trigger channel 2 and wait 1000 msec before triggering the next TRAIN

Msgbox "start"

for i=0 to 5					'loop 6 times
	x=I2-i*10e-3 
	Master8.SetChannelInterval 2,x		'I2 decreased by 10 msec  
	Master8.Trigger 2			'trigger channel 2
	wscript.Sleep (1000)  		'wait 1000 msec before the next train
	  'NOTE: the PC clock is not very accurate. 
	  'For accurate timing you must do it by a channel of Master-8 
next
Msgbox "done. click here to exit"
'------------------------------------
' Disconnect the communication with Master-8
Master8.connected=0



