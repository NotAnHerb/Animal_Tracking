
' Example 3: Click to trigger channels, and to switch paradigms
'
' step 1: connect the PC to Master-8
' Step 2: set paradigm #3: Set all channels in TRAIN mode, with I=50 msec, and 20 pulses per train
' Step 3: set paradigm #4: Set all channels in TRAIN mode, with I=200 msec, and 8 pulses per train
' Step 4: Loop: Write: 13 - to switch to paradigm 3
' 		write: 14 - to switch to paradigm 4
' 		write the channel number that you want to trigger (1 to 8)
'		write 99 to exit
'------------------------------------


const  cmTrain = 2

'step 1: Connect the PC to Master-8 first. Connect return true on success connection.

set Master8=CreateObject ("AmpiLib.Master8")
if not Master8.Connect then 
  Msgbox "Can't connect to Master8!"
  close
End If
'------------------------------------

'Step 2:  First switch to paradigm 3, clear it, and set all parameters of all 8 channels

Master8.ChangeParadigm 3			'switch to paradigm #3
Master8.Clearparadigm				'clear present paradigm (#3)

' the following loop sets all 8 channels to the TRAIN mode
' with the parameters: Di=200 usec., Ii = 50 msec and Mi = 20 pulses per train.

for i=1 to 8					'loop 8 times, for all 8 channels
	Master8.SetChannelInterval i,50e-3	'Ii = 50 millisec.  
	Master8.SetChannelDuration i,200e-6	'Di = 200 microsec.
	Master8.SetChannelM i,20		'Mi = 20 pulses per train
	Master8.ChangeChannelMode i,cmTrain	'set channel i to the TRAIN mode
next
'------------------------------------


'Step 3: Now switch to paradigm 4 and copy paradigm 3 to paradigm 4 (it does not affect paradigm 3)

Master8.ChangeParadigm 4			'switch to paradigm #3
Master8.CopyParadigm 3,4			'copy paradigm 3 to paradigm 4

' the following loop sets the following modifications for paradim 4:
' Ii = 200 msec and Mi = 8 pulses per train.

for i=1 to 8					'loop 8 times, for all 8 channels
	Master8.SetChannelInterval i,200e-3	'Ii = 200 millisec.  
	Master8.SetChannelM i,8			'Mi = 8 pulses per train
next
'------------------------------------



'Step 4: Loop: Write what do you want to do (see the above options)


While S<>99
S= InputBox ("WRITE the channel number you want to trig [1-8]. '13'-switch to PAR 3,     '14' - switch to PAR 4.          WRITE '99' to exit")


	Select case S				
		Case 13
			Master8.ChangeParadigm 3	'switch to paradigm #3
		Case 14
			Master8.ChangeParadigm 4	'switch to paradigm #4
		Case 1,2,3,4,5,6,7,8
			Master8.Trigger s		'trigger channel s
		Case 99				
			MsgBox "EXIT, Master-8 stores last parameters"	'exit program
		Case else				
			MsgBox "Wrong Value"		'Wrong Value
	end select
wend
'------------------------------------
' Disconnect the communication with Master-8
Master8.connected=0





