
close all;
clear all;

Data_global_overall=civm_read_table("Z:\All_Staff\20.5xFAD.02\stats_Combined_Phase1Phase2_from205xFAD02_20250908_olddataframe_woPhaseScanner\Connectomics\omnimanova_100010001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Global_MDS_Zscore_0000.csv");
[output_global_overall] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('subgroup4'));

Data_regional_overall=civm_read_table('Z:\All_Staff\20.5xFAD.02\stats_Combined_Phase1Phase2_from205xFAD02_20250908_olddataframe_woPhaseScanner\Connectomics\omnimanova_100010001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Regional_MDS_Zscore_0000.csv');
[output_regional_overall] = centroid_2_centroid(Data_regional_overall,list2cell('group1'),list2cell('subgroup4'));

Data_global_strain_strat=civm_read_table('Z:\All_Staff\20.5xFAD.02\test_0910\Connectomics\omnimanova_1001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Global_MDS_Zscore_0000.csv');
[output_global_strain_strat] = centroid_2_centroid(Data_global_strain_strat,list2cell('group1'),list2cell('subgroup4'));

Data_regional_strain_strat=civm_read_table('Z:\All_Staff\20.5xFAD.02\test_0910\Connectomics\omnimanova_1001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Regional_MDS_Zscore_0000.csv');
[output_regional_strain_strat] = centroid_2_centroid(Data_regional_strain_strat,list2cell('group1'),list2cell('subgroup4'));

Keep_Strains=list2cell('B6-5XFAD AD-BXD77 AD-BXD65b AD-BXD60 AD-BXD40 AD-BXD102 AD-BXD65 AD-BXD32 All');

idx_overall=sum(output_regional_strain_strat.vertex==[9,28,31],2)>0;
[value,~,value_idx]=unique(output_regional_strain_strat.hold);

for n=1:numel(Keep_Strains)
    strain_idx(:,n)=reg_match(value,Keep_Strains{n});
end
logical_strain_idx=sum(strain_idx,2)>0;
positional_strain_idx=find(logical_strain_idx);
full_strain_logical_idx=sum(value_idx==positional_strain_idx',2)>0;
REGIONAL=output_regional_strain_strat(and(idx_overall,full_strain_logical_idx),:);
civm_write_table(REGIONAL,'Z:\All_Staff\20.5xFAD.02\REGIONAL_centroid_to_centroid_Distance_8GoodStrains+AllStrain.csv');

% idx_overall=sum(output_regional_overall.vertex==[9,28,31],2)>0;
% [value,~,value_idx]=unique(output_regional_overall.hold);
% 
% for n=1:numel(Keep_Strains)
%     strain_idx(:,n)=reg_match(value,Keep_Strains{n});
% end
% logical_strain_idx=sum(strain_idx,2)>0;
% positional_strain_idx=find(logical_strain_idx);
% full_strain_logical_idx=sum(value_idx==positional_strain_idx',2)>0;
% OVERALL=output_regional_overall(and(idx_overall,full_strain_logical_idx),:); %these are the same just wanted to check

[value,~,value_idx]=unique(output_global_overall.hold);

for n=1:numel(Keep_Strains)
    strain_idx(:,n)=reg_match(value,Keep_Strains{n});
end
logical_strain_idx=sum(strain_idx,2)>0;
positional_strain_idx=find(logical_strain_idx);
full_strain_logical_idx=sum(value_idx==positional_strain_idx',2)>0;
GLOBAL=output_global_overall(full_strain_logical_idx,:); %these are the same just wanted to check
civm_write_table(GLOBAL,'Z:\All_Staff\20.5xFAD.02\GLOBAL_centroid_to_centroid_Distance_8GoodStrains+AllStrain.csv');

