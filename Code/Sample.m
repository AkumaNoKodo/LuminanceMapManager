classdef Sample < handle
    properties
        Name (1,1) string
        HDR (:,:,3) single
        ROIs = {}
        ROIsName string;
        ReCalibrationValue (1,1) single = 1;
    end

    methods
        function obj = Sample(name)
            arguments
                name (1,1) string
            end

            obj.Name = name;
            saveObj(obj);
        end

        function cropImage(obj, rec)
            obj.HDR = imcrop(obj.HDR, rec);
        end

        function createHDRFromSpectrumAndMap(obj, spectrum, map)
            luminance = phoMes(spectrum, map);
            obj.HDR = cat(3, luminance./0.2126, luminance./0.7152, luminance./0.0722);
        end

        function createHDRFromFolder(obj, folder, extensions, model, includeSubfolders)
            arguments
                obj
                folder (1,1) string
                extensions (1,:) string
                model
                includeSubfolders (1,1) logical = false
            end
            obj.HDR = ImageProcessor.HDRFromFolder(folder, extensions, includeSubfolders, model);
            saveObj(obj);
        end

        function out = getHDR(obj)
            out = obj.HDR .* obj.ReCalibrationValue;
        end

        function addROI(obj, roi, name)
            obj.ROIs{end+1} = roi;
            obj.ROIsName(end+1) = name;
            saveObj(obj);
        end

        function deleteROI(obj, number)
            if number > numel(obj.ROIs) || number <= 0 
                return;
            end

            obj.ROIs(number) = [];
            obj.ROIsName(number) = [];
            saveObj(obj);
        end

        function tab = getROIsTable(obj)
            varNames = ["ID", "ROI Name", "L [cd/m^2]", "RGB [Normalize]"];
            if isempty(obj.ROIs)
                Y = {};
                RGB = {};
                name = [];
                number = [];
                tab = table(number, name, Y, RGB, 'VariableNames',varNames);
                return;
            end

            RGB = cell(numel(obj.ROIs),1);
            Y = cell(numel(obj.ROIs),1);

            for c = 1:numel(obj.ROIs)
                RGB{c} = reshape(obj.ROIs{c}.getMeanValue(getHDR(obj)), 1, []);
                Y{c} = reshape(obj.ROIs{c}.getMeanValue(ImageProcessor.rgb2y(getHDR(obj))), 1, []);
            end

            Y = cell2mat(Y);
            RGB = cell2mat(RGB);
            NameROI = reshape(obj.ROIsName, [], 1);
            Number = reshape((1:numel(NameROI)), [], 1);
            tab = table(Number, NameROI, Y, RGB, 'VariableNames', varNames);            
        end

        function plotROIs(obj, target)
            for c = 1:numel(obj.ROIs)
                obj.ROIs{c}.Label = string(c);
                obj.ROIs{c}.plotROI(target);
            end
        end

        function saveObj(obj)
            if ~exist("Maps", "dir")
                mkdir("Maps");
            end
            save(fullfile("Maps", obj.Name + ".mat"), "obj");
        end

        function addRecalibrationValue(obj, value)
            obj.ReCalibrationValue = value;
            saveObj(obj);
        end

    end
end

