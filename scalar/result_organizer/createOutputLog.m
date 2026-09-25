function createOutputLog(files,opts,log_outkey,log_inkey)

%% test log to ensure we only transfered 1 to 1.
err_idx=struct('out_overwrite',zeros(1,log_outkey.length,'logical'), ...
    'in_multicopy',zeros(1,log_inkey.length,'logical'));
% first look at our out files
err_k='out_overwrite';
processed_files=log_outkey.keys();
for idx_file=1:numel(processed_files)
    err_idx.(err_k)(idx_file)= 1 < numel( log_outkey(processed_files{idx_file}) );
end

err_k='in_multicopy';
processed_files=log_inkey.keys();
for idx_file=1:numel(processed_files)
    err_idx.(err_k)(idx_file)= 1 < numel( log_inkey(processed_files{idx_file}) );
end
clear err_k processed_files idx_file;

try
    assert(nnz(err_idx.out_overwrite)==0,'data handling error, some ouputs would have had multiple inputs');
    assert(nnz(err_idx.in_multicopy)==0,'data handling error, some inputs were copied to multiple outputs');
    assert(log_inkey.length == log_outkey.length,'data handling error, count of inputs and outputs does not match');
    if exist(files.log_out,'file')
        delete(files.log_out);
    end
    if exist(files.log_out_mat,'file')
        delete(files.log_out_mat);
    end
    [fid,fm]=fopen(files.log_out,'w');
    log_save(fid,log_outkey,'input');
    % this'd be less clear.
    % log_save(fid,log_inkey,'output');
    fclose(fid);
    if ispc && opts.hide_transfer_log
        fileattrib(files.log_out,'+h','');
    end
catch merr
    warning(merr.message);
    % save mat version of log when in error
    fprintf('Saving error log %s\n',files.log_out_mat);
    save(files.log_out_mat,'log_outkey','log_inkey');

    err_print(log_outkey,err_idx.out_overwrite,'input')
    err_print(log_inkey, err_idx.in_multicopy, 'output')
end
end