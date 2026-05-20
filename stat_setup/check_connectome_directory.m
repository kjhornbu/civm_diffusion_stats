function [archive_idx,temp_connectome_data] = check_connectome_directory(m,n,cloud_notebook,unique_column,opts)
%Checks all possible project research archives given by user for where data
%is saved.
if iscell(opts.stats_archive)
    if ~isempty(opts.suffix)
        temp_connectome_data=connectome_dir(opts.stats_archive{m},[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    else
        temp_connectome_data=connectome_dir(opts.stats_archive{m},[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional);
    end
    
    archive_idx=m;

    if ~exist(temp_connectome_data.results,'dir')
        if numel(opts.stats_archive)==m
            return;
        else
            % lol, recursion instead of loop
            [archive_idx,temp_connectome_data] = check_connectome_directory(m+1,n,cloud_notebook,unique_column,opts);
        end
    end
else
    if ~isempty(opts.suffix)
        temp_connectome_data=connectome_dir(opts.stats_archive,[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    else
        temp_connectome_data=connectome_dir(opts.stats_archive,[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional);
    end

    archive_idx = 1;
end

end