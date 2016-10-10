classdef TestAnonyFcn < handle
   events
      Update
   end
   methods
      function obj = TestAnonyFcn
          
         lbj=labJackU6;

         open(lbj); pause(.2);

         lbj.SampleRateHz = 500;

         lbj.verbose = 0; % 0 or 1

         addChannel(lbj,[0 1],[10 10],['s' 's']);

         streamConfigure(lbj); pause(.2);
         startStream(lbj);

         addlistener(obj,'Update',@(src,evnt)obj.evntCb(src,evnt,lbj));
      end
      function triggerEvnt(obj)
         notify(obj,'Update')
      end
   end
   methods (Access = private)
      function evntCb(~,~,evnt,varargin)
         % disp(['Number of inputs: ',num2str(nargin)])
         % disp(evnt.EventName)
         % disp(varargin{:})
         
         for nn = 0 : .1 : 5
         analogOut(varargin{1},1,nn) 
         pause(1/10)
         end
         analogOut(varargin{1},1,0) 
      end
   end
end