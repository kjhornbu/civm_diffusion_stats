function queue_singleton_transfer(job_holder, in_filepath, out_filepath)
md5=persistentmd5(in_filepath,'file');
if ~job_holder.isKey(md5)
    job_holder(md5)=struct('input',in_filepath,'output',out_filepath);
else
    % get oldest of current file, and last one set?
    % does it even matter?
end
end