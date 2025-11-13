
close all;
clear all;

ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
%Keep this in the folder as a LUT??? this shouldn't change per run??

dataframe_path="Z:\All_Staff\18.gaj.42\18.gaj.42_dataframe_noB6v2.csv";
dataframe=civm_read_table(dataframe_path);

graphs=load_graph(dataframe);

data_scaling=1;
if data_scaling
    graphs=graphs.*dataframe.scale;
end

[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);

compare='Age_Class';
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

%selection_pull=list2cell('All BXD29 BXD65b BXD101 BXD60 BXD34 BXD24');
selection_pull=list2cell('All BXD24 BXD34 BXD60 BXD101 BXD65b BXD29');
compare_group_A='Young';
compare_group_B='Old';

[output_difference] = create_difference_metric_for_connectome(output_connectome,selection_pull,compare_group_A,compare_group_B); 
% A is the control group
% B is the treatement group

%Convert to "Better Names"
compare_group_A_Prime='Young';
compare_group_B_Prime='Middle-Aged';

[output_connectome,output_difference,compare_group_A,compare_group_B]=adjust_grouping_names(output_connectome,output_difference,compare_group_A,compare_group_A_Prime,compare_group_B,compare_group_B_Prime);


%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.
directory="Z:\All_Staff\18.gaj.42\StrainStrat+All_Img_Generation_20251030_wScaling";
make_Left_Axis=1;
make_LUT_img_cohen=1;
make_LUT_img_percent=1;

%all_sig_pvalues=[9, 14, 26, 156, 161];
all_sig_pvalues=[9, 14, 17, 26, 28, 71, 104, 137, 156, 161];

for n=1:numel(all_sig_pvalues)
    [figure_entries,Top_idx_10pct_noUncharted_inOntologyOrder,make_Left_Axis] = place_data_in_matrix_blue_plot(directory,all_sig_pvalues(n),selection_pull,compare_group_A,compare_group_B,output_connectome,ontology_Order,total_Ordering,make_Left_Axis);
    %We need the top idx pushed into the next set...
    [figure_entries,make_LUT_img_cohen] = place_data_in_matrix_difference_plot(directory,all_sig_pvalues(n),selection_pull,Top_idx_10pct_noUncharted_inOntologyOrder,'cohenD_difference',output_difference,ontology_Order,total_Ordering,make_LUT_img_cohen);
    [figure_entries,make_LUT_img_percent] = place_data_in_matrix_difference_plot(directory,all_sig_pvalues(n),selection_pull,Top_idx_10pct_noUncharted_inOntologyOrder,'percent_difference',output_difference,ontology_Order,total_Ordering,make_LUT_img_percent); %cohenD_difference
end
