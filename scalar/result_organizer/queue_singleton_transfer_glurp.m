function queue_singleton_transfer_glurp(job_holder, in_filepath, out_filepath, log_inkey, log_outkey)

md5=persistentmd5(in_filepath,'file');
md5_out=md5;
if exist(out_filepath,'file')
    md5_out=GetMD5(out_filepath,'file');
end
% getting collisions
if ~strcmp(md5,md5_out)
    % load both tables, do a table compare
    keyboard;
end
if ~strcmp(md5,md5_out)
    [d,n,e]=fileparts(out_filepath);
    bak=fullfile(d,sprintf('%s_%s%s',n,md5_out,e));
    if exist(bak,'file')
        delete(bak);
    end
    movefile(out_filepath,bak);
    if job_holder.isKey(md5)
        job_holder.remove(md5)
    end
    warning('file collision and does not match, previous file will be renamed. %s',bak);
    md5_out=md5;
end
assert(strcmp(md5,md5_out));
if ~job_holder.isKey(md5)
    job_holder(md5)=struct('input',in_filepath,'output',out_filepath);
    log_entry(in_filepath,out_filepath,log_inkey,log_outkey);
else
    assert(strcmp(job_holder(md5).output,out_filepath));
end

end
