

Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Global_MDS_0000.csv");
[output_global_overall,s_global] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('group2'));

Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Regional_MDS_0000.csv");
[output_regional, s_regional] = centroid_2_centroid(Data_regional,list2cell('group1'),list2cell('group2'));


ASE_Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Global_ASE_0000.csv");
[ASE_output_global_overall,ASE_s_global] = centroid_2_centroid(ASE_Data_global_overall,list2cell('group1'),list2cell('group2'));

ASE_Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\ASE_0000.csv");
[ASE_output_regional, ASE_s_regional] = centroid_2_centroid(ASE_Data_regional,list2cell('group1'),list2cell('group2'));


civm_write_table(ASE_output_regional,'Z:\All_Staff\18.gaj.42\REGIONAL_ASE_centroid_to_centroid_Distance_All_Strains+All.csv');
civm_write_table(ASE_output_global_overall,'Z:\All_Staff\18.gaj.42\GLOBAL_ASE_centroid_to_centroid_Distance_All_Strains+All.csv');