function lummap = phoMes(spectrumName, mapName)
    CIETable = load("CIETable.mat").CIETable;
    lampData = readmatrix(spectrumName);
    lummap = readmatrix(mapName);
    lamp = lampData(~isnan(lampData(:,1)),:);
    lumrange = unique(lummap(:));
    lummap(lummap < lumrange(2)) = NaN;
    [Lp,~,~] = mesopic(lamp, CIETable);
    
    mesomap = lummap;
    mesorange = lumrange;
    
    for indi = 1:length(lumrange)
        if lumrange(indi) >= 5
            continue
        end
    
        spd = lamp*[1, 0; 0, lumrange(indi)/Lp];
        [~,m] = mesopic(spd, CIETable);
        mesorange(indi) = m;
        mesomap(lummap == lumrange(indi)) = mesorange(indi);
    end
end
