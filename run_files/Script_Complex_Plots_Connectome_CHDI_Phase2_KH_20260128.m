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
all_sig_ROI=pval_table.ROI(and(source_idx,pval_idx));

all_sig_ROI(all_sig_ROI>1000)=all_sig_ROI(all_sig_ROI>1000)-1000;
all_sig_ROI=unique(all_sig_ROI); %only 1 hemisphere

comparison(1).grouping.A.('Genotype')='WILD';
comparison(1).grouping.B.('Genotype')='HET';

comparison(2).stratification.('Age_of_Termination_months')='Fifteen';
comparison(2).grouping.A.('Genotype')='WILD';
comparison(2).grouping.B.('Genotype')='HET';

comparison(3).stratification.('Age_of_Termination_months')='Ten';
comparison(3).grouping.A.('Genotype')='WILD';
comparison(3).grouping.B.('Genotype')='HET';

comparison(4).stratification.('Age_of_Termination_months')='Six';
comparison(4).grouping.A.('Genotype')='WILD';
comparison(4).grouping.B.('Genotype')='HET';

comparison(5).stratification.('Age_of_Termination_months')='Two';
comparison(5).grouping.A.('Genotype')='WILD';
comparison(5).grouping.B.('Genotype')='HET';


graphs=load_graph(dataframe);
if data_scaling
    graphs=graphs.*dataframe.scale;
end

ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);

for n=1:numel(comparison)
    if isempty(comparison(n).stratification)
        % case for dealing with "all" which is we don't stratify
        selection_name ='All';
        selection_group_idx=ones(height(dataframe),1);
        postional_idx_selection=1:height(dataframe);
    else
        selection=fieldnames(comparison(n).stratification);
        [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection);
        clear selection_term
        for m=1:numel(selection)
            selection_term{m}=comparison(n).stratification.(selection{m});
        end
        selection_name=strjoin(fliplr(selection_term),' ');
        postional_idx_selection=find(reg_match(selection_group,selection_name));
    end

    % Get comparision fields
    compare_a=fieldnames(comparison(n).grouping.A);
    compare_b=fieldnames(comparison(n).grouping.B);

    [~,compare_group_A,compare_group_A_idx]=find_group_information_from_groupingcriteria(dataframe,compare_a);
    [~,compare_group_B,compare_group_B_idx]=find_group_information_from_groupingcriteria(dataframe,compare_b);

    clear compare_a_term
    for m=1:numel(compare_a)
        compare_a_term{m}=comparison(n).grouping.A.(compare_a{m});
    end
    compare_a_name=strjoin(fliplr(compare_a_term),' ');
    positional_idx_A=find(reg_match(compare_group_A,compare_a_name));

    clear compare_b_term
    for m=1:numel(compare_b)
        compare_b_term{m}=comparison(n).grouping.B.(compare_b{m});
    end
    compare_b_name=strjoin(fliplr(compare_b_term),' ');
    positional_idx_B=find(reg_match(compare_group_B,compare_b_name));

    %Get connectomic data and differences for each comparsion and compile
    %into a tabular format for each ROI in the connectome (not filtering
    %ROIs at this point)
    [output_connectome{n}] = create_contralateral_ipsilateral_JamesVersion(graphs,selection_name,selection_group_idx,postional_idx_selection,compare_a_name,compare_group_A_idx,positional_idx_A,compare_b_name,compare_group_B_idx,positional_idx_B);
    [output_difference{n}] = create_difference_metric_for_connectome_JamesVersion(output_connectome{n},selection_name,compare_a_name,compare_b_name);
end

output_connectome=vertcat(output_connectome{:});
output_difference=vertcat(output_difference{:});

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.
make_Left_Axis=1;
make_LUT_img=1;
output_plot_LUT=table;

selection_pull=unique(output_connectome.selection_group,'stable');
compare_group_A=unique(output_difference.compare_group_A,'stable');
compare_group_B=unique(output_difference.compare_group_B,'stable');

for n=1:numel(all_sig_ROI)
    [matrix_2_print_blue,data_y_labels] = setup_matrix2print(output_connectome,selection_pull,all_sig_ROI(n),total_Ordering,'blue','',compare_group_A,compare_group_B);
    [matrix_2_print_cohenD,data_y_labels_cohenD] = setup_matrix2print(output_difference,selection_pull,all_sig_ROI(n),total_Ordering,'effect','cohenD_difference',compare_group_A,compare_group_B);
    [matrix_2_print_percent,data_y_labels_percent] = setup_matrix2print(output_difference,selection_pull,all_sig_ROI(n),total_Ordering,'effect','percent_difference',compare_group_A,compare_group_B);

    matrix_2_print={matrix_2_print_blue;matrix_2_print_cohenD;matrix_2_print_percent};
    matrix_2_print_names={'blue','cohenD','percent'};

    [idx_10pct_noUncharted_inOntologyOrder_Top15,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,node_keyvertices_entries] = find_key_vertices(all_sig_ROI(n),matrix_2_print,matrix_2_print_names,ontology_Order);

    %setup LUT of output plot vertices per each key node
    offset=height(output_plot_LUT);
    output_plot_LUT(offset+[1:height(node_keyvertices_entries)],:)=node_keyvertices_entries;

    [~,make_Left_Axis] = setup_blue_plot(directory,all_sig_ROI(n),selection_pull,matrix_2_print_blue,data_y_labels,idx_10pct_noUncharted_inOntologyOrder_Top15,ontology_Order,make_Left_Axis);
    [~,make_LUT_img] = setup_difference_plot(directory,all_sig_ROI(n),data_y_labels_cohenD,matrix_2_print_cohenD,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'cohenD_difference',ontology_Order,make_LUT_img);

    if n==1
        make_LUT_img=1;
    end

    [~,make_LUT_img] = setup_difference_plot(directory,all_sig_ROI(n),data_y_labels_percent,matrix_2_print_percent,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'percent_difference',ontology_Order,make_LUT_img);
end

civm_write_table(output_plot_LUT,fullfile(directory,strcat('Top_15_Vertices_ForEachNode_',datestr(datetime("today")),'.csv')));
