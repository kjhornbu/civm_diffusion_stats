
close all;
clear all;

green=[0.4660 0.6740 0.1880];
purple=[0.4940 0.1840 0.5560];

working_folder="B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall";

ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
%Keep this in the folder as a LUT??? this shouldn't change per run??

dataframe_path="B:\24.chdi.01-PHASE2\stats\24.chdi.01_DataFrame_Windows_20260115_KH.txt";
dataframe=civm_read_table(dataframe_path);

graphs=load_graph(dataframe);

data_scaling=1;
if data_scaling
    graphs=graphs.*dataframe.scale;
end

[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);
%civm_write_table(ontology_Order,'Ordering_For_Plotting_Connectomes_inRCCF_20260126.csv');

compare=list2cell('Genotype');
selection=list2cell('Age_of_Termination_months');
% 
% 
% comparison(1).stratification.('Age_of_Termination_months')='Two';
% comparison(1).stratification.('Sex')='M';
% comparison(1).grouping.A.('Genotype')='WILD';
% 
% comparison(1).grouping.B.('Genotype')='HET';
% 
% comparison(2).stratification.('Age_of_Termination_months')='Two';
% comparison(2).stratification.('Sex')='F';
% comparison(2).grouping.A.('Genotype')='WILD';
% comparison(2).grouping.B.('Genotype')='HET';
% 
% comparison(3).stratification.('Age_of_Termination_months')='Two';
% comparison(3).grouping.A.('Genotype')='WILD';
% comparison(3).grouping.B.('Genotype')='HET';

if numel(selection)>1 && numel(compare)>1
    count=1;
    [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection);
    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare);
    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

    for n=1:numel(selection)
        for m=1:numel(compare)
            [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(m));
            [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection(n));
            count=count+1;
            [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
        end
    end
elseif  numel(selection) == 1 && numel(compare) > 1
    m=1;
    count=1;

    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare);
    [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection(m));
    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

    for n=1:numel(compare)
        count=count+1;
        [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(n));
        [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
    end
elseif numel(selection) > 1 && numel(compare) == 1
    m=1;
    count=1;
    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(m));
    [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection);
    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

    for n=1:numel(selection)
        count=count+1;
        [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection(n));
        [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
    end
elseif numel(selection) == 1 && numel(compare) == 1
    m=1;
    count=1;
    [~,selection_group,selection_group_idx]=find_group_information_from_groupingcriteria(dataframe,selection(m));
    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(m));

    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
end

%% Then do with "All" As selection group... maybe have a switch on if numel(selection) is empty? 
selection_group=list2cell('All');
selection_group_idx=ones(height(dataframe),1);

if numel(compare) > 1
    count=count+1;
    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare);
    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

    for n=1:numel(compare)
        count=count+1;
        [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(n));
        [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
    end
    
elseif numel(compare)==1
    m=1;
    count=count+1;
    [~,compare_group,compare_group_idx]=find_group_information_from_groupingcriteria(dataframe,compare(m));
    [output_connectome{count}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
end

output_connectome=vertcat(output_connectome{:});

%selection_pull=list2cell('All Two Six Ten Twelve Fifteen');
%selection_pull=list2cell('All Fifteen Twelve Ten Six Two');
selection_pull=list2cell('All Fifteen Ten Six Two');
%selection_pull=list2cell('All All All');

%can either be 1 entry like this for all the selection pulls
compare_group_A='WILD';%{'WILD' 'WILD M' 'WILD F'}; %CONTROL GROUP % WILD
compare_group_B='HET';%{'HET' 'HET M' 'HET F'}; %TREATED GROUP %HET

[output_difference] = create_difference_metric_for_connectome(output_connectome,selection_pull,compare_group_A,compare_group_B);

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.

directory=fullfile(working_folder,'All+AgeGroupStratified_BluePlots_EffectPlots_no12mo_AllSigOverall');
make_Left_Axis=1;
make_LUT_img=1;

%pull the signficant regions to get the vertices to try here.
pval_table=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\Genotype_AgeofTerminationmonths_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv"));
source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Genotype'));
pval_idx=pval_table.pval_BH<0.05;
all_sig_pvalues=pval_table.ROI(and(source_idx,pval_idx));

all_sig_pvalues(all_sig_pvalues>1000)=all_sig_pvalues(all_sig_pvalues>1000)-1000;
all_sig_pvalues=unique(all_sig_pvalues);

output_plot_LUT=table;
all_sig_pvalues=[47];

for n=1:numel(all_sig_pvalues)

    [matrix_2_print_blue,data_y_labels] = setup_matrix2print(output_connectome,selection_pull,all_sig_pvalues(n),total_Ordering,'blue','',compare_group_A,compare_group_B);
    [matrix_2_print_cohenD,data_y_labels_cohenD] = setup_matrix2print(output_difference,selection_pull,all_sig_pvalues(n),total_Ordering,'effect','cohenD_difference',compare_group_A,compare_group_B);
    [matrix_2_print_percent,data_y_labels_percent] = setup_matrix2print(output_difference,selection_pull,all_sig_pvalues(n),total_Ordering,'effect','percent_difference',compare_group_A,compare_group_B);

    matrix_2_print={matrix_2_print_blue;matrix_2_print_cohenD;matrix_2_print_percent};
    matrix_2_print_names={'blue','cohenD','percent'};

    [idx_10pct_noUncharted_inOntologyOrder_Top15,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,node_keyvertices_entries] = find_key_vertices(all_sig_pvalues(n),matrix_2_print,matrix_2_print_names,ontology_Order);
    
    %setup LUT of output plot vertices per each key node
    offset=height(output_plot_LUT);
    output_plot_LUT(offset+[1:height(node_keyvertices_entries)],:)=node_keyvertices_entries;

    [~,make_Left_Axis] = setup_blue_plot(directory,all_sig_pvalues(n),selection_pull,matrix_2_print_blue,data_y_labels,idx_10pct_noUncharted_inOntologyOrder_Top15,ontology_Order,make_Left_Axis);
    [~,make_LUT_img] = setup_difference_plot(directory,all_sig_pvalues(n),data_y_labels_cohenD,matrix_2_print_cohenD,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'cohenD_difference',ontology_Order,make_LUT_img);
    
    if n==1
        make_LUT_img=1;
    end

    [~,make_LUT_img] = setup_difference_plot(directory,all_sig_pvalues(n),data_y_labels_percent,matrix_2_print_percent,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'percent_difference',ontology_Order,make_LUT_img);

    blue_mean_data=mean(matrix_2_print_blue);

    logical_idx_all=reg_match(selection_pull,'All');
    positional_idx_all=find(logical_idx_all);
    percent_All_data=matrix_2_print_percent(positional_idx_all,:);

    idx_gt_100=abs(percent_All_data)>1;

    if exist('out_gt_100', 'var') && exist('out_NOT_gt_100', 'var')
        offset=width(out_gt_100);
        temp=blue_mean_data(idx_gt_100);
        out_gt_100(offset+(1:numel(temp)))=temp;

        offset=width(out_NOT_gt_100);
        temp=blue_mean_data(~idx_gt_100);
        out_NOT_gt_100(offset+(1:numel(temp)))=temp;
    else
        out_gt_100=blue_mean_data(idx_gt_100);
        out_NOT_gt_100=blue_mean_data(~idx_gt_100);
    end
end

civm_write_table(output_plot_LUT,fullfile(working_folder,'All+AgeGroupStratified_BluePlots_EffectPlots_no12mo_AllSigOverall',"Top_15_Vertices_ForEach_Significant_Node_inOverallModel_20260127.csv"));

[a,b]=ecdf(out_gt_100);
[a2,b2]=ecdf(out_NOT_gt_100);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));

semilogx(b,100*(1-a));
hold on
semilogx(b2,100*a2);

legend({'|%Change| > 100%','|%Change| < 100%'},Location="northoutside");

ylabel('Cumulative Probability');
xlabel('Edge Strength');
set(gca,'FontSize',6,'FontName','Arial'); %6 == 4.5 on mac

print(f, fullfile(working_folder,'All+AgeGroupStratified_BluePlots_EffectPlots_no12mo_AllSigOverall','Blown-up_PercentagesGraph_atDifferentEdgeStrengths.png'),'-dpng','-r600');