function [slidedata] = make_regional_pval_summary(ppt,global_pval_table,regional_pval_table,threshold_type,pval_threshold)
import mlreportgen.ppt.*;

All_Sources_In_System=unique(global_pval_table.source_of_variation,'stable');

model=strjoin(global_pval_table.source_of_variation,'+');
title=strjoin({'Regional: ',model},'');
large_effect_cohenF2 = 0.35;

summary_table=table;
Sig_Label=sprintf('Count Significant Regions (%s < %0.2f)',threshold_type,pval_threshold);
Sig_Label_LargeEffect=sprintf('Count Significant Regions (%s < %0.2f) with Large Effects',threshold_type,pval_threshold);

for n=1:numel(All_Sources_In_System)
    summary_table.('Source of Variation'){n}=All_Sources_In_System{n};
    logical_source_entries=~cellfun(@isempty,regexpi(regional_pval_table.source_of_variation,strcat('^(', All_Sources_In_System{n}, ')$')));
    logical_effect_entries=regional_pval_table.cohenFSquared>large_effect_cohenF2;
    summary_table.(Sig_Label)(n)=sum(regional_pval_table.(threshold_type)(logical_source_entries)<pval_threshold);
    summary_table.(Sig_Label_LargeEffect)(n) = sum(regional_pval_table.(threshold_type)(and(logical_source_entries,logical_effect_entries))<pval_threshold);
end

slidedata = add(ppt,"Title and Content");
replace(slidedata,"Title",title);
replaces(slidedata,"Content",summary_table);

end