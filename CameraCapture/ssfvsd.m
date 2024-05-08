imn = raw2rgb("C:\Users\marku\Music\WORK\HDR\CameraCapture\KALIBRACE_CANNON_EOS_80D_Zaznam_6_JPG_NEF_0_16\ISO_100\IMG_46.cr2");
gray = im2uint8(im2gray(imn));
j = fft2(gray);
jabs= abs(j);
imshow(jabs);