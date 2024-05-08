classdef CalibrationModel < handle
    properties
        HDRImagesData = []
        InputData = []
        CalibrationCoeficients
        CalibrationTables
        CalibrationList;
    end

    methods
        function obj = CalibrationModel()

        end

        function addFolder(obj, folder, extension, trueLuminance, ROIs)
            arguments
                obj
                folder (1,1) string
                extension (1,:) string
                trueLuminance (1,3) double
                ROIs (1,3) cell
            end

            if numel(ROIs) ~= numel(trueLuminance)
                error("The number of ROIs and real luminances must be the same.")
            end

            files = getAllFiles(folder, extension, true);

            trueLuminance = repmat({trueLuminance}, size(files));
            ROIs = repmat({ROIs}, size(files));

            dataTable = table(files, trueLuminance, ROIs);
            if isempty(obj.InputData)
                obj.InputData = dataTable;
            else
                obj.InputData = vertcat(obj.InputData, dataTable);
            end
        end

        function getCalibrationData(obj)
            info = cell(size(obj.InputData,1),1);
            inputData = obj.InputData.files;

            try
            for c = 1:size(obj.InputData,1)
                info{c} = ImageProcessor.rawImageInfo(inputData(c));
            end
            catch
                display(inputData(c));
                return;
            end

            info = vertcat(info{:});
            obj.InputData(:,"files") = [];
            obj.InputData = horzcat(info, obj.InputData);

            getUnique = @(x) unique(x, "rows", "stable");

            [cameraModels, ~, cameraModelsIDX] = getUnique(obj.InputData.CameraModel);
            [FNumbers, ~, FNumbersIDX] = getUnique(obj.InputData.FNumber);
            [ISOs, ~, ISOsIDX] = getUnique(obj.InputData.ISO);
            [luminances, ~, luminancesIDX] = getUnique(vertcat(obj.InputData.trueLuminance{:}));

            obj.CalibrationList = struct;
            obj.CalibrationList.CameraModels = cameraModels;
            obj.CalibrationList.FNumbers = FNumbers;
            obj.CalibrationList.Luminances = luminances;
            obj.CalibrationList.ISOs = ISOs;

            names = ["RGB_HDR", "TrueLuminance", "CameraModel", "FNumber", "ISO"];
            for c = 1:numel(cameraModels)
                for c1 = 1:size(luminances,1)
                    for c2 = 1:numel(FNumbers)
                        for c3 = 1:numel(ISOs)
                            info = obj.InputData(cameraModelsIDX == c & luminancesIDX == c1 & FNumbersIDX == c2 & ISOsIDX == c3,:);
                            if isempty(obj.HDRImagesData)
                                obj.HDRImagesData = table(getRGBMean(info), luminances(c1,:), cameraModels(c), FNumbers(c2), ISOs(c3), 'VariableNames', names);
                                continue;
                            end

                            obj.HDRImagesData = [obj.HDRImagesData; table(getRGBMean(info), luminances(c1,:), cameraModels(c), FNumbers(c2), ISOs(c3), 'VariableNames', names)];
                        end
                    end
                end
            end         
            
            RGB = obj.HDRImagesData.RGB_HDR;
            Y = cellfun(@(x) ImageProcessor.rgb2y(x'), RGB);
            obj.HDRImagesData = addvars(obj.HDRImagesData, Y, NewVariableNames="Lumimance", After="RGB_HDR");

            function RGB = getRGBMean(info)
                HDR =  ImageProcessor.HDR(info);
                RGB = cell(1, numel(info.ROIs{1}));
                for k = 1:numel(info.ROIs{1})
                    RGB{k} = info.ROIs{1,1}{1,k}.getMeanValue(HDR);
                end
            end
        end

        function calcCalibrationCoeficients(obj)
            allHDR = obj.HDRImagesData;  
            FNumbers = obj.CalibrationList.FNumbers;

            coeficients = struct;

            for c = 1:numel(FNumbers)
                name = "FNumber_" + strrep(string(FNumbers(c)), ".", "_");
                
                data = allHDR(allHDR.FNumber == FNumbers(c),:);
                Yref = data.Lumimance(:);
                Y = data.TrueLuminance(:);
                bad = isnan(Y) | isnan(Yref);
                Yref(bad,:) = [];
                Y(bad,:) = [];

                coef = Yref \ Y;

                coeficients.(name) = coef;
            end
            
            obj.CalibrationCoeficients = coeficients;
            obj.HDRImagesData = allHDR;
        end
    end
end

