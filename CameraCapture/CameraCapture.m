classdef CameraCapture < handle
    properties (SetAccess=private, GetAccess=public)
        portAdress string = [];
        Folder string = [];
        AskSavePath string = [];
        UseOriginalFilename string = [];
        isonumber string = [];
        fnumber string = [];
        shutterspeed string = [];
        counter = 0;
    end
    
    methods (Access=public)
        function obj = CameraCapture()
            setPort(obj, "5514");
            setFolder(obj, string(pwd) + filesep + "ImageCapture");
            setAskSavePath(obj, "0");
            setUseOriginalFilename(obj, "0");
        end

        function capture(obj, imageFormat)
            if  isempty(obj.isonumber) || isempty(obj.shutterspeed) || isempty(obj.fnumber)
                warning("Some parameters are undefined.");
                return;
            end

            try
                fileName = "IMG_" + obj.counter;
                file = obj.Folder + filesep + fileName + imageFormat(1);
                file2 = obj.Folder + filesep + fileName + imageFormat(2);
                obj.counter = obj.counter +1;
                webread(obj.portAdress + "/?SLC=CaptureNoAf&param1=" + fileName);
                while true
%                     if counterTime == 100000
%                         disp("Capture Error");
%                         pause(0.1);
%                         return;
%                     end
                    if exist(file2, "file") && exist(file, "file")
                        break;
                    end
                    pause(0.1);
%                     counterTime = counterTime + 1;
                end
                disp(file);
            catch
                warning("Capture Error");
            end
        end

        function multipleShutterIsoCapture(obj, iso, shutter, fileFormat)
            folder = obj.Folder;
            for c = 1:length(iso) 
                disp(iso(c));
                setIsonumber(obj, iso(c));
                setFolder(obj, folder + filesep + "ISO_" + iso(c))
                for k = 1:length(shutter)
                   setShutterspeed(obj, shutter(k));
                   disp(shutter(k));
                   capture(obj, fileFormat);
                end
                
            end
            disp("All images are capture.");
            [y ,fs] = audioread("beep-01a.mp3");
            sound(y, fs);
        end
  
%% Setters
        function setPort(obj, option)
            option = "http://localhost:" + option;
            changeOption(obj, "", "portAdress", option);
        end

        function setFolder(obj, option)
            option = replace(option, " ", "");
            changeOption(obj, "session", "Folder", option);
        end

        function setAskSavePath(obj, option)
            changeOption(obj, "session", "AskSavePath", option); 
        end

        function setUseOriginalFilename(obj, option)
            changeOption(obj, "session", "UseOriginalFilename", option);
        end

        function setIsonumber(obj, option)
            changeOption(obj, "camera", "isonumber", option);
        end

        function setFnumber(obj, option)
            changeOption(obj, "camera", "fnumber", option);
            disp(obj.fnumber);
        end

        function setShutterspeed(obj, option)
            changeOption(obj, "camera", "shutterspeed", option);
        end

    end


    methods (Access=private)
%% Process function--------------------------------------------------------------------------------------------------------------------------------------------  
        function changeOption(obj, type, variable, option)
            obj.(variable) = option;

            if type == "session"
                disp(webread(obj.portAdress + "/?slc=set&param1=session." + variable + "&&param2=" + option));
            end

            if type == "camera"
                disp(webread(obj.portAdress + "/?SLC=Set&param1=camera." + variable + "&param2=" + option));
            end
           
        end

    end


end

