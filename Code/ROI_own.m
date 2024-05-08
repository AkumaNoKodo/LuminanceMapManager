classdef ROI_own < handle
    properties
        MaskFunctions = {@rectangleMask, @circleMask, @ellipseMask, @polygonMask}
        ROIFunctions = {@createRectangle, @createCircle, @createEllipse, @createPolygon}
        PlotFunctions = {@drawrectangle, @drawcircle, @drawellipse, @drawpolygon}
        Properities = struct
        Type (1,1) string
        TypeOptions = ["rectangle", "circle", "ellipse", "polygon"]
        Label (1,1) string = ""
    end

    methods
        function obj = ROI_own(type)
            arguments
                type (1,1) string
            end

            if ~ismember(type, obj.TypeOptions)
                error("Invalid type. Must be " + strjoin(obj.TypeOptions, ", "));
            end

            obj.Type = type;

        end

        function mask = getMask(obj, maskSize)
            arguments
                obj
                maskSize (1,3) uint64
            end

            if isempty(fieldnames(obj.Properities))
                mask = [];
                return;
            end

            warning('off', 'MATLAB:colon:nonIntegerIndex');

            maskFunction = obj.MaskFunctions{strcmp(obj.Type, obj.TypeOptions)};
            mask = maskFunction(obj, maskSize);

            warning('on', 'MATLAB:colon:nonIntegerIndex');
        end

        function image = getMaskedImage(obj, image)
            arguments
                obj
                image (:,:,:) {mustBeNumericOrLogical}
            end

            if isempty(fieldnames(obj.Properities))
                return;
            end

            mask = getMask(obj, size(image, 1:3));
            image(~mask) = nan;
        end

        function meanValue = getMeanValue(obj, image)
            arguments
                obj
                image (:,:,:) {mustBeNumericOrLogical}
            end

            if isempty(fieldnames(obj.Properities))
                meanValue = [];
                return;
            end

            image = getMaskedImage(obj, image);
            meanValue = squeeze(mean(image, 1:2, "omitmissing"));
        end

        function plotROI(obj, target)
            arguments
                obj
                target
            end

            if isempty(fieldnames(obj.Properities))
                return;
            end

            options = [fieldnames(obj.Properities), struct2cell(obj.Properities)]';
            options = options(:);
            color = [255 0 255]./255;
            options = [options; {"Parent"; target; "Label"; obj.Label; "LabelTextColor"; color; "MarkerSize"; 1; "Color"; color; "InteractionsAllowed"; "none"; "LineWidth"; 2; "LabelAlpha"; 0}];

            plotFunction = obj.PlotFunctions{strcmp(obj.Type, obj.TypeOptions)};
            plotFunction(options{:});

        end

        function defineByUserInImage(obj, image, target)
            arguments
                obj
                image (:,:,:) {mustBeNumericOrLogical} = []
                target = [];
            end

            closeTarget = isempty(target);

            if isempty(image) && isempty(target)
                error("Image or parent must be defined.")
            end

            if isempty(target)
                fig = figure;
                target = axes('Parent', fig, 'Position', [0 0 1 1]);
            end

            if ~isempty(image)
                imshow(image,'Parent', target);
            end

            roiFunction =  obj.ROIFunctions{strcmp(obj.Type, obj.TypeOptions)};
            roiFunction(obj, target);

            if closeTarget
                close(fig);
            end

        end
    end

    methods (Access=private)
        %% CREATING ROI BY USER
        function createRectangle(obj, target)
            roi = drawrectangle('Parent', target);
            obj.Properities.Position = roi.Position; % [xmin, ymin, width, height]
        end

        function createCircle(obj, target)
            roi = drawcircle('Parent', target);
            obj.Properities.Center = roi.Center;
            obj.Properities.Radius = roi.Radius;
        end

        function createEllipse(obj, target)
            roi = drawellipse('Parent', target);
            obj.Properities.Center = roi.Center;
            obj.Properities.SemiAxes = roi.SemiAxes;
            obj.Properities.RotationAngle = roi.RotationAngle;
        end

        function createPolygon(obj, target)
            roi = drawpolygon('Parent', target);
            obj.Properities.Position = roi.Position; %  n-by-2 points = [x y]
        end

        %% CREATING ROI MASK
        function mask = rectangleMask(obj, maskSize)
            arguments
                obj
                maskSize (1,3) uint64
            end

            rows = maskSize(1);
            cols = maskSize(2);
            thirdDimension = maskSize(3);

            xmin = obj.Properities.Position(1);
            ymin = obj.Properities.Position(2);
            width = obj.Properities.Position(3);
            height = obj.Properities.Position(4);

            mask = false(rows, cols, thirdDimension);
            mask(ymin:ymin+height, xmin:xmin+width, :) = true;
        end

        function mask = circleMask(obj, maskSize)
            arguments
                obj
                maskSize (1,3) uint64
            end

            rows = maskSize(1);
            cols = maskSize(2);
            thirdDimension = maskSize(3);

            centerX = obj.Properities.Center(1);
            centerY = obj.Properities.Center(2);
            radius = obj.Properities.Radius;

            [X, Y] = meshgrid(1:cols, 1:rows);
            mask = (X - centerX).^2 + (Y - centerY).^2 <= radius^2;

            mask = repmat(mask, 1,1,thirdDimension);
        end

        function mask = ellipseMask(obj, maskSize)
            arguments
                obj
                maskSize (1,3) uint64
            end

            rows = maskSize(1);
            cols = maskSize(2);
            thirdDimension = maskSize(3);

            centerX = obj.Properities.Center(1);
            centerY = obj.Properities.Center(2);
            semiAxisX = obj.Properities.SemiAxes(1);
            semiAxisY = obj.Properities.SemiAxes(2);
            angle = obj.Properities.RotationAngle(1);

            [X, Y] = meshgrid(1:cols, 1:rows);
            Xr = (X - centerX)*cosd(angle) + (Y - centerY)*sind(angle);
            Yr = -(X - centerX)*sind(angle) + (Y - centerY)*cosd(angle);
            mask = (Xr/semiAxisX).^2 + (Yr/semiAxisY).^2 <= 1;

            mask = repmat(mask, 1,1,thirdDimension);
        end

        function mask = polygonMask(obj, maskSize)
            arguments
                obj
                maskSize (1,3) uint64
            end

            rows = maskSize(1);
            cols = maskSize(2);
            thirdDimension = maskSize(3);

            xPoints = obj.Properities.Position(:,1);
            yPoints = obj.Properities.Position(:,2);

            mask = poly2mask(xPoints, yPoints, rows, cols);

            mask = repmat(mask, 1,1,thirdDimension);
        end

    end
end

