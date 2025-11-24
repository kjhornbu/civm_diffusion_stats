function [save_path] = global_one_remove_compile(save_cnt,connectome_outputs,Paths_Pval,pval_threshold)
save_cnt=fullfile(save_cnt,'OneRemove');

if ~exist(save_cnt,'dir')
    mkdir(save_cnt)
end

count=1;
for n=1:numel(connectome_outputs)
    total_comparisions = height(Paths_Pval.(connectome_outputs{n}));
    for m=1:total_comparisions
        pval=civm_read_table(Paths_Pval.(connectome_outputs{n}).global{m});
        specimen{m}=Paths_Pval.(connectome_outputs{n}).name{m};

        if m==1
           all_sources=unique(pval.source_of_variation);
        end

        temp_pval=pval(pval.pval<=pval_threshold,:);
        temp_pval.specimen=repmat({specimen{m}},height(temp_pval),1);
        temp_pval.connectome_factor=repmat({connectome_outputs{n}},height(temp_pval),1);
        output_save_table{count}=temp_pval;

        count=count+1;
    end
end

RM_1_results=vertcat(output_save_table{:});

save_path=fullfile(save_cnt,'Global_1_Remove_Test.txt');
civm_write_table(RM_1_results,save_path);
clear save_path;

[connectome,~,connectome_idx]=unique(RM_1_results.connectome_factor);
[sov,~,sov_idx]=unique(RM_1_results.source_of_variation);

Sig_Among_1RM=table;
Sig_Among_1RM.source_of_variation=all_sources;
%preallocate the number of hits to zeros
for m=1:numel(connectome_outputs) 
    Sig_Among_1RM.(connectome_outputs{m})=zeros(size(all_sources));
end

for n=1:numel(sov)
    idx_sov=reg_match(all_sources,strcat('^(',sov{n},')$'));
    postional_idx_sov=find(idx_sov);
    for m=1:numel(connectome_outputs)
        idx_connectome=reg_match(connectome,connectome_outputs{m});
        postional_idx_connectome=find(idx_connectome);
        Sig_Among_1RM.(connectome_outputs{m})(postional_idx_sov)=sum((connectome_idx==postional_idx_connectome & sov_idx==postional_idx_sov));
    end
end


save_path=fullfile(save_cnt,'Global_Significant_Among_1_Remove.txt');
civm_write_table(Sig_Among_1RM,save_path);

end