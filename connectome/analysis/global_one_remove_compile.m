function [outputArg1,outputArg2] = global_one_remove_compile(save_cnt,connectome_outputs,Paths_Pval)

for n=1:numel(connectome_outputs)
    total_comparisions = height(Paths_Pval.(connectome_outputs{n}));
    for m=1:total_comparisions
        pval=civm_read_table(Paths_Pval.(connectome_outputs{n}).global{m});
        specimen{m}=Paths_Pval.(connectome_outputs{n}).name{m};

        if m == 1
            %then this is the initial manova!
            [value,~,idx]=unique(pval.source_of_variation);
            for o=1:numel(value)
                value_adjust{o}=strrep(value{o},':','x');
                full_list_raw.(connectome_outputs{n}).(value_adjust{o})=0;
            end
        end
        for o=1:numel(value)
            logical_idx_raw=~cellfun(@isempty,regexpi(pval.source_of_variation,value{o})) & (pval.pval<=pval_threshold);
            full_list_raw.(connectome_outputs{n}).(value_adjust{o})=sum(logical_idx_raw,1)+full_list_raw.(connectome_outputs{n}).(value_adjust{o});
        end
    end

end

Sig_Among_1RM.count_sig_bh_brainscaled


for n=1:numel(connectome_outputs)
    Paths_Pval.(connectome_outputs{n}).regional=strrep(Paths_Pval.(connectome_outputs{n}).regional,'/Volumes/dusom_civm-kjh60/All_Staff/','Z:\All_Staff\');
    Paths_Pval.(connectome_outputs{n}).regional=strrep(Paths_Pval.(connectome_outputs{n}).regional,'/','\');

    Paths_Pval.(connectome_outputs{n}).global=strrep(Paths_Pval.(connectome_outputs{n}).global,'/Volumes/dusom_civm-kjh60/All_Staff/','Z:\All_Staff\');
    Paths_Pval.(connectome_outputs{n}).global=strrep(Paths_Pval.(connectome_outputs{n}).global,'/','\');
end
