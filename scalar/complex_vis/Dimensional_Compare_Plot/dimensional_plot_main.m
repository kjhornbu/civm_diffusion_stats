function [] = dimensional_plot_main(stats_Filter,Filter,save_path,pval_type)
%% Actual Processing 
for n = 1:numel(stats_Filter)
    [filtered_Stats,~] = stat_filtering(stats_Filter{n},Filter{n});

    %pull out basically everything you specifically need and all pvalue
    %types ---  we will filter in a second once we make the -log10's we
    % might need
    idx = ~cellfun(@isempty,regexpi(filtered_Stats{1}.Properties.VariableNames,'^(GN_Symbol|Structure|source_of_variation|contrast|pval|pval_BH|PercentChange|stratification)$|^(BASIS_|TEST_)'));
    
    total_Filtered_Stats{n} = table;
    total_Filtered_Stats{n} = filtered_Stats{1}(:,idx);
    total_Filtered_Stats{n}.NEGLog10_pval = -log10(total_Filtered_Stats{n}.pval);
    total_Filtered_Stats{n}.NEGLog10_pval_BH = -log10(total_Filtered_Stats{n}.pval_BH);

    %remove the type of pvals you don't need here
    idx = ~cellfun(@isempty,regexpi(total_Filtered_Stats{n}.Properties.VariableNames,strcat('^(GN_Symbol|Structure|source_of_variation|contrast|',pval_type,'|PercentChange|stratification)$|^(BASIS_|TEST_)')));
    reduced_Filtered_Stats{n} = table;
    reduced_Filtered_Stats{n} = total_Filtered_Stats{n}(:,idx);
end

[plotting_Data] = clean_for_plotting(reduced_Filtered_Stats,pval_type);
dimensional_plot(plotting_Data,save_path,pval_type);
end