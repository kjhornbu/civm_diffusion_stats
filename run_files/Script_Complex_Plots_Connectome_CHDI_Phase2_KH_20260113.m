
close all;
clear all;

ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
%Keep this in the folder as a LUT??? this shouldn't change per run??

dataframe_path="B:\24.chdi.01-PHASE2\stats\24.chdi.01_DataFrame_Windows_20260112_KH.txt";
dataframe=civm_read_table(dataframe_path);

graphs=load_graph(dataframe);

data_scaling=1;
if data_scaling
    graphs=graphs.*dataframe.scale;
end

[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);


compare='Genotype';
[compare_group,~,compare_group_idx]=unique(dataframe.(compare));

selection=list2cell('Age_of_Termination_months');

for n=1:numel(selection)
    [selection_group,~,selection_group_idx]=unique(dataframe.(selection{n}));
    [output_connectome{n}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
end

% To do all things together together
selection_group=list2cell('All');
selection_group_idx=ones(height(dataframe),1);
[output_connectome{numel(selection)+1}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

output_connectome=vertcat(output_connectome{:});

%selection_pull=list2cell('All Two Six Ten Twelve Fifteen');
selection_pull=list2cell('All Fifteen Twelve Ten Six Two');
compare_group_A='HET';
compare_group_B='WILD';

[output_difference] = create_difference_metric_for_connectome(output_connectome,selection_pull,compare_group_A,compare_group_B);

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.
directory="B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_Run_20260112_Overall\All+AgeGroup_BluePlots";
make_Left_Axis=1;


%pull the signficant regions to get the vertices to try here.
pval_table=civm_read_table("B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_Run_20260112_Overall\Connectomics\omnimanova_100010001\AgeofTerminationmonths_Genotype_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv");
source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Genotype'));
pval_idx=pval_table.pval_BH<0.05;
all_sig_pvalues=pval_table.ROI(and(source_idx,pval_idx));

all_sig_pvalues(all_sig_pvalues>1000)=all_sig_pvalues(all_sig_pvalues>1000)-1000;
all_sig_pvalues=unique(all_sig_pvalues);

%all_sig_pvalues=9;
output_plot_LUT=table;
for n=1:numel(all_sig_pvalues)

    [figure_entries,Top_idx_10pct_noUncharted_inOntologyOrder,make_Left_Axis,name_entries] = place_data_in_matrix_blue_plot(directory,all_sig_pvalues(n),selection_pull,compare_group_A,compare_group_B,output_connectome,ontology_Order,total_Ordering,make_Left_Axis);
    out_height=height(output_plot_LUT);

    output_plot_LUT.ROI_Node(out_height+[1:height(name_entries)])=repmat(all_sig_pvalues(n),height(name_entries),1);
    output_plot_LUT.Structure_Node(out_height+[1:height(name_entries)])={ontology_Order.Structure{ontology_Order.ROI==all_sig_pvalues(n)}};
    output_plot_LUT.GN_Symbol_Node(out_height+[1:height(name_entries)])={ontology_Order.GN_Symbol{ontology_Order.ROI==all_sig_pvalues(n)}};
    
    for m=1:height(name_entries)
        output_plot_LUT.ROI_Vertex(out_height+m)=name_entries.ROI(m);
        output_plot_LUT.Structure_Vertex(out_height+m)=name_entries.Structure(m);
        output_plot_LUT.GN_Symbol_Vertex(out_height+m)=name_entries.GN_Symbol(m);
        output_plot_LUT.Hemisphere_Vertex(out_height+m)=name_entries.Hemisphere(m);
    end

    %We need the top idx pushed into the next set...
    [figure_entries,make_LUT_img] = place_data_in_matrix_difference_plot(directory,all_sig_pvalues(n),selection_pull,Top_idx_10pct_noUncharted_inOntologyOrder,'cohenD_difference',output_difference,ontology_Order,total_Ordering,make_LUT_img); %'percent_difference' %'cohenD_difference'
    if n==1
        make_LUT_img=1;
    end
    [figure_entries,make_LUT_img] = place_data_in_matrix_difference_plot(directory,all_sig_pvalues(n),selection_pull,Top_idx_10pct_noUncharted_inOntologyOrder,'percent_difference',output_difference,ontology_Order,total_Ordering,make_LUT_img); %'percent_difference' %'cohenD_difference'
end

civm_write_table(output_plot_LUT,'B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_Run_20260112_Overall\Top_15_Vertices_ForEach_Significant_Node_OverallModel.csv');
