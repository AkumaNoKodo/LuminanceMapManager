classdef ImageProcessor
    methods (Static)
        function allInfo = rawImageInfo(paths)
            arguments
                paths (1,:) string
            end

            allInfo = cell(numel(paths),1);
            for c = 1:numel(paths)
                outInfo.Path = fullfile(paths(c));
                info = rawinfo(outInfo.Path);
                outInfo.ExposureTime = single(info.ExifTags.ExposureTime);
                outInfo.CameraModel = upper(info.MiscInfo.CameraMake + " " + info.MiscInfo.CameraModel);
                outInfo.FNumber = single(info.ExifTags.FNumber);

                if isfield(info.ExifTags, "ISOSpeedRatings")
                    outInfo.ISO = single(info.ExifTags.ISOSpeedRatings);
                else
                    outInfo.ISO = single(100);
                end

                outInfo.BlackLevel = single(info.ColorInfo.BlackLevel);
                outInfo.CFALayout = info.CFALayout;

                cameras = ["CANON EOS 80D", "NIKON D90"];
                bitsDepth = [14, 12];
                bits2maxRange = @(x) single(2^x-1);

                outInfo.BitsDepth = [];

                if ismember(outInfo.CameraModel, cameras)
                    outInfo.BitsDepth = bits2maxRange(bitsDepth(strcmp(outInfo.CameraModel, cameras)));
                end

                allInfo{c} = struct2table(outInfo);
            end

            allInfo = vertcat(allInfo{:});
        end

        function RGB = raw2rgb(info)
            % Read CFA Image and color index
            cfa = single(rawread(fullfile(info.Path)));
            colorIndex = {strfind(info.CFALayout, "R"), strfind(info.CFALayout, "G"), strfind(info.CFALayout, "B")};

            % Demosaic
            cfaIm = cat(3, cfa(1:2:end, 1:2:end), ...
                cfa(1:2:end, 2:2:end), ...
                cfa(2:2:end, 1:2:end), ...
                cfa(2:2:end, 2:2:end));

            % Black level correction
            cfaIm = cfaIm - reshape(info.BlackLevel, 1,1,[]);

            % reScale 0-1
            cfaIm = cfaIm ./ reshape((info.BitsDepth - info.BlackLevel), 1,1,[]);

            % Convert to 3 dimensions
            RGB = cat(3, cfaIm(:,:,colorIndex{1}), ...
                mean(cfaIm(:,:,colorIndex{2}),3), ...
                cfaIm(:,:,colorIndex{3}));

            % Clamp Boundaries Pixel Values
            RGB(RGB<0.15) = 0;
            RGB(RGB>0.85) = 1;
        end

        function HDR = HDR(informations, model)
            arguments
                informations
                model = []
            end
            refISO = 100;
            refFNumber = 1;
            refTime = 1;

            HDRRGB = [];
            weightHDRRGB = [];

            actualFNumber = informations.FNumber(1);
            actualISO = informations.ISO(1);

            for c = 1:size(informations,1)
                info = informations(c,:);
                workRGB = ImageProcessor.raw2rgb(info);

                if c == 1
                    HDRRGB = zeros(size(workRGB), "single");
                    weightHDRRGB = zeros(size(workRGB), "single");
                end

                if c ~= 1 && all(size(workRGB) ~= size(HDRRGB))
                    error("Invalid image size.")
                end

                weight = 1 - 2 .* abs(workRGB - 0.5);

                correctionValue = (refTime ./ info.ExposureTime) ;
                workRGB = workRGB .* correctionValue .* weight;

                weightHDRRGB = weightHDRRGB + weight;
                HDRRGB = HDRRGB + workRGB;
            end

            HDR = HDRRGB ./ weightHDRRGB ./ (refFNumber ./ actualFNumber)^2 ./ (actualISO ./ refISO);

            if ~isempty(model)
                try
                    HDR = HDR .* model.CalibrationCoeficients.("FNumber_" + strrep(string(actualFNumber), ".", "_"));
                catch
                    error("Coefients for this FNumber(" + actualFNumber + ") not exist. Must be one from [" + join(string(calibrationModel.CalibrationList.FNumbers), ", " ) + "]." );
                end
            end
        end

        function HDR = HDRFromFolder(folder, extensions, includeSubfolders, model)
            arguments
                folder (1,1) string
                extensions (1,:) string
                includeSubfolders (1,1) logical = false
                model = []
            end

            files = getAllFiles(folder, extensions, includeSubfolders);

            if extensions == ".jpg"
                refISO = 100;
                refFNumber = 1;
                refTime = 1;
                rgb = single(imread(files));
                
                im_info = imfinfo(files);
                iso = im_info.DigitalCamera.ISOSpeedRatings;
                fnumber = im_info.DigitalCamera.FNumber;
                exposure_time = im_info.DigitalCamera.ExposureTime;
                if iso == 0
                    iso = 100;
                end
                
                rgb = rgb ./ 255;
                imshow(rgb)
                weight = 1 - 2 .* abs(rgb - 0.5);

                correctionValue = (refTime ./ exposure_time) ;
                rgb = rgb .* correctionValue .* weight;
                HDR = rgb ./ weight ./ (refFNumber ./ fnumber)^2 ./ (iso ./ refISO);
                return 
            end

            info = ImageProcessor.rawImageInfo(files);

            HDR = ImageProcessor.HDR(info, model);
        end

        function Y = rgb2y(RGB, type, scaleMode, enableLog10)
            arguments
                RGB (:,:,:) single
                type (1,1) string = "originalMap"
                scaleMode = []
                enableLog10 (1,1) logical = false
            end

            if size(RGB,3) > 1 && size(RGB,1) >= 1
                Y = reshape(reshape(RGB, [], 3) * [0.2126; 0.7152; 0.0722], size(RGB, 1:2));
            elseif size(RGB,3) == 1 && size(RGB,2) == 3 && size(RGB,1) >= 1
                Y = RGB * [0.2126; 0.7152; 0.0722];
            else
                error("Invalid size for this operation.")
            end

            switch type
                case "originalMap"

                case "hightLuminance"
                    Y(Y < 10^0.2) = nan;
                case "mediumLuminance"
                    Y(Y < 10^-0.3 | Y > 10^0.2) = nan;
                case "lowLuminance"
                    Y(Y < 10^-1 | Y >= 10^-0.3) = nan;
                case "photopic"
                    Y(Y < 10^0.7) = nan;
                case "mesopic"
                    Y(Y >= 10^0.7) = nan;
                otherwise
                    error("Invalid type.")
            end


            if enableLog10
                Y = log10(Y);
            end

            if isempty(scaleMode)
                return;
            end

            fig = figure;
            cmap = colormap(fig,scaleMode);
            close(fig);
            Y = uint8(rescale(Y) .* 255 +1);
            Y = ind2rgb(Y, cmap);
        end


    end
end

