clear
clc
zaznam = 1;
folder = "KALIBRACE_NIKON_7200D_Zaznam_";
camera = CameraCapture();
camera.setFnumber("5.6");
iso = "100";
shutter = ["2s", "1s", "1/2", "1/4", "1/8", "1/15", "1/30", "1/60", "1/125", "1/250", "1/500", "1/1000", "1/2000", "1/4000", "1/8000"];
camera.setFolder(string(pwd) + filesep + folder + zaznam + "_JPG_NEF_0_5.6");
camera.multipleShutterIsoCapture(iso, shutter, [".nef", ".jpg"]);

camera.setFnumber("8.0");
camera.setFolder(string(pwd) + filesep + folder + zaznam + "_JPG_NEF_8");
camera.multipleShutterIsoCapture(iso, shutter, [".nef", ".jpg"]);

camera.setFnumber("11.0");
camera.setFolder(string(pwd) + filesep + folder + zaznam + "_JPG_NEF_0_11");
camera.multipleShutterIsoCapture(iso, shutter, [".nef", ".jpg"]);

camera.setFnumber("16.0");
camera.setFolder(string(pwd) + filesep + folder + zaznam + "_JPG_NEF_0_16");
camera.multipleShutterIsoCapture(iso, shutter, [".nef", ".jpg"]);
