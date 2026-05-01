clear all;
close all;

contrasts={'ad_mean','rd_mean','md_mean','fa_mean','volume_fraction','volume_mm3'};

Stats_x = civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260420\Scalar_and_Volume\anovan_1001\AgeClass_Strain_Sex\Non_Erode\Bilateral_Young\Group_Statistical_Results_withoutPairwiseComparisions_Strain_Sex.csv");
Stats_y = civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260420\Scalar_and_Volume\anovan_1001\AgeClass_Strain_Sex\Non_Erode\Bilateral_Old\Group_Statistical_Results_withoutPairwiseComparisions_Strain_Sex.csv");

Group_Data_x = civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260420\Scalar_and_Volume\anovan_1001\AgeClass_Strain_Sex\Non_Erode\Bilateral_Young\Group_Data_Table_Strain_Sex.csv");
Group_Data_y = civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260420\Scalar_and_Volume\anovan_1001\AgeClass_Strain_Sex\Non_Erode\Bilateral_Old\Group_Data_Table_Strain_Sex.csv");

pval_type ={'NEGLog10_pval','NEGLog10_pval_BH','pval','pval_BH'};

for o=1:numel(pval_type)
    for i=1:numel(contrasts)
        %save path and file name for the output plot
        save_path = strcat('Z:\All_Staff\18.gaj.42\Dimensional_Correlation_Plotting\',pval_type{o},'_',contrasts{i},'.svg');

        %% Dimension 1 Information
        % This sets the percent change values across Dim 1; the First entry here is
        % the control condition  -- This is used for the size and color of the ROI
        % dot
        Filter{1} = table;
        Filter{1}.Data{1} = Group_Data_x;
        Filter{1}.Field{1} = {'Strain','Sex'};
        Filter{1}.Entry{1} = {'^(-)$','M'};

        Filter{1}.Data{2} = Group_Data_x;
        Filter{1}.Field{2} = {'Strain','Sex'};
        Filter{1}.Entry{2} = {'^(-)$','F'};

        %this is the actual data that is plotted for the given dimension (pvalue
        %comparisions for a given source and contrast)
        stats_Filter{1} = table;
        stats_Filter{1}.Data{1} = Stats_x;
        stats_Filter{1}.source{1} = {'^(Sex)$'};
        stats_Filter{1}.contrast{1} = {contrasts{i}};

        %% Dimension 2 Information
        % This sets the percent change values across Dim 2; the First entry here is
        % the control condition  -- This is used for the size and color of the ROI
        % dot
        Filter{2} = table;
        Filter{2}.Data{1} = Group_Data_y;
        Filter{2}.Field{1} = {'Strain','Sex'};
        Filter{2}.Entry{1} = {'^(-)$','M'};

        Filter{2}.Data{2} = Group_Data_y;
        Filter{2}.Field{2} = {'Strain','Sex'};
        Filter{2}.Entry{2} = {'^(-)$','F'};

        %this is the actual data that is plotted for the given dimension (pvalue
        %comparisions for a given source and contrast) -- This ones source and
        %contrast must be the same as Dimension 1's information
        
        stats_Filter{2} = table;
        stats_Filter{2}.Data{1} = Stats_y;
        stats_Filter{2}.source{1} = {'^(Sex)$'};
        stats_Filter{2}.contrast{1} = {contrasts{i}};

        dimensional_plot_main(stats_Filter,Filter,save_path,pval_type{o});
        close all
    end
end