
' Example 1: All the instructions you can use
' 
' step 1: connect the PC to Master-8
' Step 2: switch to paradigm #4 and Set all channels modes
' Step 3: switch to paradigm #5 and Set the time parameters of the channels
' Step 4: Example for all the other instructions
'------------------------------------

Option Explicit
'The following line, begins with '  ---  this is a comment.
'We need the first line, to force variables Declarations (Dim, const...)


'This is a sample for declaring variables.
Dim master8
Dim xtime


const  cmOff = 0
const  cmFree = 1
const  cmTrain = 2
const  cmTrig = 3
const  cmDC = 4
const  cmGate = 5
' -------------------

'step 1: Connect the PC to Master-8 first. Connect return true on success connection.

set Master8=CreateObject ("AmpiLib.Master8")
if not Master8.Connect then 
  Msgbox "Can't connect to Master8!"
  close
End If
'------------------------------------


' Step 2: switch to paradigm #4 and Set all channels modes

Msgbox "switch to paradigm 4. Click here to continue"	'message box
Master8.ChangeParadigm 4		'switch to paradigm #4
Master8.Clearparadigm			'clear present paradigm (#4)
' -------------------


' The following lines are examples to set the operation mode of the different channels
Master8.ChangeChannelMode 1,cmGate		'set chnnel 1 to the GATE mode
Master8.ChangeChannelMode 2,cmFree		'set chnnel 2 to the FREE-RUN mode
Master8.ChangeChannelMode 3,cmTrain		'set chnnel 3 to the TRAIN mode
Master8.ChangeChannelMode 4,cmTrig		'set chnnel 4 to the TRIG mode
Master8.ChangeChannelMode 5,cmDC		'set chnnel 5 to the DC mode
Master8.ChangeChannelMode 6,cmFree		'set chnnel 6 to the FREE-RUN mode
Master8.ChangeChannelMode 6,cmOff		'set chnnel 6 to the OFF mode
Master8.ChangeChannelMode 8,cmTrig		'set chnnel 8 to the TRIG mode
' -------------------


' Step 3: switch to paradigm #5 and Set the time parameters of the channels

Msgbox "switch to paradigm 5. Click here to continue."	'message box
Master8.ChangeParadigm 5		'switch to paradigm #5
Master8.Clearparadigm 			'clear present paradigm (#5)
' -------------------

' The following lines are examples to set the parameters of the different channels
Master8.SetChannelM 8,23 			'M8=23
Master8.SetChannelDuration 1,40e-6		'D1=40 usec - can be written in any format
Master8.SetChannelInterval 1,0.001234		'I1=1.234 msec
Master8.SetChannelDelay 1,0.01234		'L1=12.34 msec
Master8.SetChannelDuration 2,0.01		'D2=10 msec
Master8.SetChannelInterval 2,0.1		'I2=100 msec
xtime=2.1				'** example for using variable time
Master8.SetChannelDelay 2,xtime+0.4	'L2=2.1+0.4=2.5 sec
Master8.SetChannelDuration 3,10			'D3=10 sec
Master8.SetChannelInterval 3,100 		'I3=100 sec
Master8.SetChannelDelay 3,1000 			'L3=1000 sec
Master8.SetChannelInterval 4,3999 		'I4=3999 sec (1 hour+399 sec)
'Master8.SetChannelVoltage 4,-2.1		'Master-8-vp only: V4=-2.1 Volt
' -------------------


' Step 4: Example for all the other instructions

Msgbox "switch to paradigm 6. Click here to continue."
Master8.ChangeParadigm 6
Master8.Clearparadigm 
' -------------------


' The following lines are other very useful examples
MsgBox "Click to trigger channel 8"		
Master8.Trigger 8				'trigger channel 8
Master8.CopyParadigm 4,6			'copy paradigm 4 to paradigm 6
Master8.ConnectChannel 8,1			'connect channel 8 to channel 1
Master8.ConnectChannel 8,2			'connect channel 8 to channel 2
Master8.ConnectChannel 8,3			'connect channel 8 to channel 3
Master8.DisConnectChannel 8,1	'disconnect connection from channel 8 to channel 1
' -------------------
' Disconnect the communication with Master-8
Master8.connected=0


