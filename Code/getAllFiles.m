function fileList = getAllFiles(folder, extensions, includeSubfolders)
    arguments
        folder (1,1) string
        extensions (1,:) string
        includeSubfolders (1,1) logical = false
    end
    extensions = lower(extensions);
    if includeSubfolders
        searchPattern = '**/*';
    else
        searchPattern = '*';
    end
    
    info = dir(fullfile(folder, searchPattern));
    info = struct2table(info);
    
    if isempty(info)
        fileList = [];
        return;
    end
    
    [~, ~, ext] = fileparts(info.name);
    ext = lower(ext);
    info = info(ismember(ext, extensions), :); 

    fileList =  string(fullfile(info.folder, info.name)); 
end
