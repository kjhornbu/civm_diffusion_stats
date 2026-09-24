
function process_singleton_transfers(job_holder,log_inkey,log_outkey)
% This is for transfers where we may have many equivalent inputs with a
% single output. We queue up those transfers instead of running them in
% place because the copy/re-copy rules are different than for slice images
% or others.
% 
% job_holder is a map, keys are md5 of the input file. values are struct
% with input=path, output=path, and md5=md5(spurious?).
for md5=job_holder.keys
    md5=uncell(md5);
    % this should already be taken care of, shouldn't it?
    %out_dir=fileparts(job_holder(k).output);
    %if ~exist(out_dir,'dir')
    %    mkdir(out_dir);
    %end

    md5_out=md5;
    if exist(job_holder(md5).output,'file')
        md5_out=GetMD5(job_holder(md5).output,'file');
    end
    % getting collisions
    if ~strcmp(md5,md5_out)
        % load both tables, do a table compare
        tab_in=civm_read_table(job_holder(md5).input,[],[],1);
        tab_cur=civm_read_table(job_holder(md5).output,[],[],1);
        count_diff=table_compare(tab_cur,tab_in);
        if not( count_diff )
            % same, so we dont care.
            continue;
        else
            % loaded tables are different... ruh-roh
            keyboard;
        end
    end
    if ~strcmp(md5,md5_out)
        [d,n,e]=fileparts(job_holder(k).output);
        bak=fullfile(d,sprintf('%s_%s%s',n,md5_out,e));
        if exist(bak,'file')
            delete(bak);
        end
        movefile(job_holder(k).output,bak);
        if job_holder.isKey(md5)
            job_holder.remove(md5)
        end
        warning('file collision and does not match, previous file will be renamed. %s',bak);
        md5_out=md5;
    end
    assert(strcmp(md5,md5_out),'queued singleton file transfer has differing input datafiles.');
        
    update_file(job_holder(md5).input,job_holder(md5).output,log_inkey,log_outkey)
end
end
