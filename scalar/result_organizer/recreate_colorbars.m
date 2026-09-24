function recreate_colorbars(job_holder,log_inkey,log_outkey)
% should add an output-path setup here, to help validate input md5.
out_map=containers.Map();
input_cksums=job_holder.keys();
for idx_f=1:numel(input_cksums)
    md5=input_cksums{idx_f};
    if ~ out_map.isKey( job_holder(md5).output )
        S=job_holder(md5);
        S.md5=md5;
        out_map( job_holder(md5).output )=S;
    elseif ~strcmp( md5, out_map(job_holder(md5).output).md5 ) 
        % outmap set, but md5 for inputs is different.
        next_input=job_holder(md5).input;
        cur_input=out_map(job_holder(md5).output).input;
        tab_in=civm_read_table(next_input,[],[],1);
        tab_cur=civm_read_table(cur_input,[],[],1);
        count_diff=table_compare(tab_cur,tab_in);
        if not( count_diff )
            % same, so we dont care, unqueue this md5.
            % uh, that could be an interator bug if we just remove key. 
            % lets set cached key to empty string instead.
            input_cksums{idx_f}='';
            continue;
        else
            % loaded tables are different... ruh-roh
            keyboard;
        end
    end
end
clear idx_f S;

for idx_f=1:numel(input_cksums)
    md5=input_cksums{idx_f};
    if isempty(md5)
        % we blank out the cached key for any which are redundant.
        continue;
    end
    % this should already be taken care of, shouldn't it?
    %out_dir=fileparts(job_holder(md5).output);
    %if ~exist(out_dir,'dir')
    %    mkdir(out_dir);
    %end
    if file_time_check(job_holder(md5).output, 'new', job_holder(md5).input)
        % data ready, do nothing, even though this
        % empty looks funny this is on purpose for
        % branch prediction. (historical testing showed
        % this was a useful optimization, not validated on current matlab version.)
        fprintf('');
    else
        % i think file_time_check is ... dumb,
        % The SECOND file must exist! This makes some logic non-obvious.
        % I should adjust it to better handle files
        % which should be present and files which should
        % not.
        tab_lut=civm_read_table(job_holder(md5).input,[],[],1);
        % cannot log these the same way, these conflict with the previously
        % copied LUT files. 
        % log_entry(job_holder(md5).input,job_holder(md5).output,log_inkey,log_outkey);
        lookup_plot(table2struct(tab_lut),'proportional',false,'out_height',4,job_holder(md5).output);
    end
end
end