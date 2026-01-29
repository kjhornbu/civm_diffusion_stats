close all;
clear all;

working_folder="B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall";
directory=fullfile(working_folder,'All+AgeGroupStratified_BluePlots_EffectPlots_TEST');

mkdir(directory);

dataframe_path="B:\24.chdi.01-PHASE2\stats\24.chdi.01_DataFrame_Windows_20260115_KH.txt";
dataframe=civm_read_table(dataframe_path);
data_scaling=1;

%pull the signficant regions to get the vertices to try for plots here.
pval_table=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\Genotype_AgeofTerminationmonths_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv"));
source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Genotype'));
pval_idx=pval_table.pval_BH<0.05;
meaningful_nodes=pval_table.ROI(and(source_idx,pval_idx));

meaningful_nodes(meaningful_nodes>1000)=meaningful_nodes(meaningful_nodes>1000)-1000;
meaningful_nodes=unique(meaningful_nodes); %only 1 hemisphere

comparison(1).grouping.Basis.('Genotype')='WILD';
comparison(1).grouping.UnderTest.('Genotype')='HET';

comparison(2).stratification.('Age_of_Termination_months')='Fifteen';
comparison(2).grouping.Basis.('Genotype')='WILD';
comparison(2).grouping.UnderTest.('Genotype')='HET';

comparison(3).stratification.('Age_of_Termination_months')='Ten';
comparison(3).grouping.Basis.('Genotype')='WILD';
comparison(3).grouping.UnderTest.('Genotype')='HET';

comparison(4).stratification.('Age_of_Termination_months')='Six';
comparison(4).grouping.Basis.('Genotype')='WILD';
comparison(4).grouping.UnderTest.('Genotype')='HET';

comparison(5).stratification.('Age_of_Termination_months')='Two';
comparison(5).grouping.Basis.('Genotype')='WILD';
comparison(5).grouping.UnderTest.('Genotype')='HET';

[output_connectome,output_difference,output_plot_vertex_LUT] = full_blue_effect_setup(directory,dataframe,data_scaling,comparison,meaningful_nodes);
