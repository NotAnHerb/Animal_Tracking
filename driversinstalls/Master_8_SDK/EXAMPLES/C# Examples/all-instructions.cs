using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using AmpiLib;

namespace WindowsApplication1
{
    public partial class Form1 : Form
    {
        Master8Class m8;

        public Form1()
        {
            InitializeComponent();
        }

        private void backgroundWorker1_DoWork(object sender, DoWorkEventArgs e)
        {

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // step 1: Connect the PC to Master-8 first. Connect return true on success connection.
            m8 = new Master8Class();
            if ( ! m8.Connect() ) 
            {
                MessageBox.Show("Can't connect to Master8!","Master 8 SDK");
                this.Close();
            }
            
        }


        private void button1_Click(object sender, EventArgs e)
        {
            double xtime;
            // Step 2: switch to paradigm #4 and Set all channels modes
            if (paradigm4.Checked)
            {
                toolStripStatusLabel2.Text = "Paradigm 4 selected";
                m8.ChangeParadigm(4);   // switch to paradigm #4
                m8.ClearParadigm();     // clear present paradigm (#4)
               /* ------------------- */
               /* The following lines are examples to set the operation mode of the different channels
               /* ------------------- */
                m8.ChangeChannelMode(1, AmpiLib.ChannelModes.cmGate);       // set chnnel 1 to the GATE mode
                m8.ChangeChannelMode(2, AmpiLib.ChannelModes.cmFreeRun);    // set chnnel 2 to the FREE-RUN mode
                m8.ChangeChannelMode(3, AmpiLib.ChannelModes.cmTrain);      // set chnnel 3 to the TRAIN mode
                m8.ChangeChannelMode(4, AmpiLib.ChannelModes.cmTrig);       // set chnnel 4 to the TRIG mode
                m8.ChangeChannelMode(5, AmpiLib.ChannelModes.cmDC);         // set chnnel 5 to the DC mode
                m8.ChangeChannelMode(6, AmpiLib.ChannelModes.cmFreeRun);    // set chnnel 6 to the FREE-RUN mode
                m8.ChangeChannelMode(6, AmpiLib.ChannelModes.cmOff);        // set chnnel 6 to the OFF mode
                m8.ChangeChannelMode(8, AmpiLib.ChannelModes.cmTrig);       // set chnnel 8 to the TRIG mode
            }
                //Step 3: switch to paradigm #5 and Set the time parameters of the channels
            else if (paradigm5.Checked)
            {
                toolStripStatusLabel2.Text = "Paradigm 5 selected";
                m8.ChangeParadigm(5);   // switch to paradigm #5
                m8.ClearParadigm();     // clear present paradigm (#5)
                /* ------------------- */
                /* The following lines are examples to set the parameters of the different channels */
                /* ------------------- */
                m8.SetChannelM(8, 23);              // M8=23
                m8.SetChannelDuration(1, 40e-6);    // D1=40 usec - can be written in any format
                m8.SetChannelInterval(1, 0.001234); // I1=1.234 msec
                m8.SetChannelDelay(1, 0.01234);     // L1=12.34 msec
                m8.SetChannelDuration(2, 0.01);     // D2=10 msec
                m8.SetChannelInterval(2, 0.1);      // I2=100 msec
                xtime = 2.1;			/* example for using variable time */
                m8.SetChannelDelay(2, xtime+0.4);   // L2=2.1+0.4=2.5 sec
                m8.SetChannelDuration(3, 10);       // D3=10 sec
                m8.SetChannelInterval(3, 100);      // I3=100 sec
                m8.SetChannelDelay(3, 1000);        // L3=1000 sec
                m8.SetChannelInterval(4, 3999);     // I4=3999 sec (1 hour+399 sec)

            }
            // Step 4: Example for all the other instructions
            else if (paradigm6.Checked)
            {
                toolStripStatusLabel2.Text  = "Paradigm 6 selected";
                m8.ChangeParadigm(6);   // switch to paradigm #6
                m8.ClearParadigm();     // clear present paradigm (#6)
                
                m8.Trigger(8);              // trigger channel 8
                m8.CopyParadigm(4, 6);      // copy paradigm 4 to paradigm 6
                m8.ConnectChannel(8, 1);    // connect channel 8 to channel 1
                m8.ConnectChannel(8, 2);    // connect channel 8 to channel 2
                m8.ConnectChannel(8, 3);    // connect channel 8 to channel 3
                m8.DisconnectChannel(8, 1); // disconnect connection from channel 8 to channel 1
            }
        }

    }
}