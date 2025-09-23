
close all;
clear all;

ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
%Keep this in the folder as a LUT??? this shouldn't change per run??

dataframe_path="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
dataframe=civm_read_table(dataframe_path);
dataframe(123,:)=[]; %is broken right now it is a BXD65 specimen nTG Female

graphs=load_graph(dataframe);

data_scaling=1;
if data_scaling
    graphs=graphs.*dataframe.scale;
end

[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);

compare='Genotype';
[compare_group,~,compare_group_idx]=unique(dataframe.(compare));

selection=list2cell('Strain');
for n=1:numel(selection)
    [selection_group,~,selection_group_idx]=unique(dataframe.(selection{n}));
    [output_connectome{n}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
end

% To do all things together together
selection_group=list2cell('All');
selection_group_idx=ones(height(dataframe),1);
[output_connectome{numel(selection)+1}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

output_connectome=vertcat(output_connectome{:});

selection_pull=list2cell('All');
%selection_pull=list2cell('B6-5XFAD AD-BXD77 AD-BXD65b AD-BXD60 AD-BXD40 AD-BXD102 AD-BXD65 AD-BXD32');
compare_group_A='nTG';
compare_group_B='FAD';

[output_difference] = create_difference_metric_for_connectome(output_connectome,selection_pull,compare_group_A,compare_group_B);

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.
directory="Z:\All_Staff\20.5xFAD.02\AllStrain_Img_Generation_20250919";
make_Left_Axis=1;
make_LUT_img=1;

%pull the signficant regions to get the vertices to try here.
%pval_table=civm_read_table("Z:\All_Staff\20.5xFAD.02\test_0910\Connectomics\omnimanova_1001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Concat_Strain_Pval_sorted_from_ASEx2_Zscore_0000.csv");
pval_table=civm_read_table("Z:\All_Staff\20.5xFAD.02\stats_Combined_Phase1Phase2_from205xFAD02_20250908_olddataframe_woPhaseScanner\Connectomics\omnimanova_100010001\Genotype_Phase_scanner_Sex_Strain\BrainScaled_Omni_Manova\Pval_sorted_from_ASEx2_Zscore_0000.csv");
source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Genotype'));
pval_idx=pval_table.pval_BH<0.05;
all_sig_pvalues=pval_table.ROI(and(source_idx,pval_idx));

all_sig_pvalues(all_sig_pvalues>1000)=all_sig_pvalues(all_sig_pvalues>1000)-1000;
all_sig_pvalues=unique(all_sig_pvalues);

for n=1:numel(all_sig_pvalues)
    [figure_entries,Top_idx_10pct_noUncharted_inOntologyOrder,make_Left_Axis] = place_data_in_matrix_blue_plot(directory,all_sig_pvalues(n),selection_pull,compare_group_A,compare_group_B,output_connectome,ontology_Order,total_Ordering,make_Left_Axis);
    %We need the top idx pushed into the next set...
    [figure_entries,make_LUT_img] = place_data_in_matrix_difference_plot(directory,all_sig_pvalues(n),selection_pull,Top_idx_10pct_noUncharted_inOntologyOrder,'cohenD_difference',output_difference,ontology_Order,total_Ordering,make_LUT_img);
end

%The annotation, CohenD/percentChange, and MeanEdgeStrength Should go into
%thier own folders

