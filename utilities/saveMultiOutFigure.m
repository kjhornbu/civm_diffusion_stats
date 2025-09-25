function [] = saveMultiOutFigure(Current_Fig,save_location,file_name,file_extension)
%saves figure to one (or multiple) of different file types.
for n=1:numel(file_extension)
    if ~exist(fullfile(save_location,file_extension{n}),'dir')
        mkdir(fullfile(save_location,file_extension{n}));
    end

    if  regexpi(file_extension{n},'png')
        print(Current_Fig,fullfile(save_location,file_extension{n},file_name),'-dpng','-r600');
    end

    if regexpi(file_extension{n},'svg')
        print(Current_Fig,fullfile(save_location,file_extension{n},file_name),'-dsvg','-vector');
    end

    if regexpi(file_extension{n},'tif')
        print(Current_Fig,fullfile(save_location,file_extension{n},file_name),'-dtiff','-r600');
    end
end
end