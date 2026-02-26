
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

compare_group_A='WILD'; %CONTROL GROUP
compare_group_B='HET'; %TREATED GROUP

[output_difference] = create_difference_metric_for_connectome(output_connectome,selection_pull,compare_group_A,compare_group_B);

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.

directory=fullfile(working_folder,"All+AgeGroupStratified_BluePlots_EffectPlots");
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
%all_sig_pvalues=[47];

for n=1:numel(all_sig_pvalues)

    [matrix_2_print_blue,data_y_labels] = set_up_matrix2print(output_connectome,selection_pull,all_sig_pvalues(n),total_Ordering,'blue','',compare_group_A,compare_group_B);
    [matrix_2_print_cohenD,~] = set_up_matrix2print(output_difference,selection_pull,all_sig_pvalues(n),total_Ordering,'effect','cohenD_difference','','');
    [matrix_2_print_percent,~] = set_up_matrix2print(output_difference,selection_pull,all_sig_pvalues(n),total_Ordering,'effect','percent_difference','','');

    matrix_2_print={matrix_2_print_blue;matrix_2_print_cohenD;matrix_2_print_percent};
    matrix_2_print_names={'blue','cohenD','percent'};

    [idx_10pct_noUncharted_inOntologyOrder_Top15] = find_key_vertices(matrix_2_print,matrix_2_print_names,ontology_Order);

    blue_mean_data=mean(matrix_2_print_blue);
    logical_idx_all=reg_match(selection_pull,'All');
    positional_idx_all=find(logical_idx_all);

    cohenD_All_data=matrix_2_print_cohenD(positional_idx_all,:);
    percent_All_data=matrix_2_print_percent(positional_idx_all,:);
% 
%     idx_10pct_noUncharted_inOntologyOrder=(blue_mean_data./max(blue_mean_data))>0.1 & [~cellfun(@isempty,ontology_Order.GN_Symbol);~cellfun(@isempty,ontology_Order.GN_Symbol)]';
%     pos_idx_10pct_noUncharted_inOntologyOrder=find(idx_10pct_noUncharted_inOntologyOrder);
% 
%     %Find top 15 ROI
%     if sum(idx_10pct_noUncharted_inOntologyOrder)>15
%         [a,b]=sort(blue_mean_data(idx_10pct_noUncharted_inOntologyOrder),'descend');
%         idx_10pct_noUncharted_inOntologyOrder_Top15=zeros(size(idx_10pct_noUncharted_inOntologyOrder));
%         idx_10pct_noUncharted_inOntologyOrder_Top15(pos_idx_10pct_noUncharted_inOntologyOrder(b(1:15)))=1;
% 
%         idx_10pct_noUncharted_inOntologyOrder_Top15=idx_10pct_noUncharted_inOntologyOrder_Top15>0;
%     else
%        idx_10pct_noUncharted_inOntologyOrder_Top15=idx_10pct_noUncharted_inOntologyOrder;
%     end

%     f=figure;
%     set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 2]*3.3*(72/96));
%     
%     semilogy(cohenD_All_data,blue_mean_data,'.');
%     xlabel('All - CohenD Effect')
%     ylabel('Log 10 of Mean Connectome Value')
%     hold on
%     semilogy(cohenD_All_data(idx_10pct_noUncharted_inOntologyOrder),blue_mean_data(idx_10pct_noUncharted_inOntologyOrder),'m.')    
%     semilogy(cohenD_All_data(idx_10pct_noUncharted_inOntologyOrder_Top15),blue_mean_data(idx_10pct_noUncharted_inOntologyOrder_Top15),'r.')
%     
%     idx_large_effect=abs(cohenD_All_data)>0.8;
%     semilogy(cohenD_All_data(idx_large_effect),blue_mean_data(idx_large_effect),'o','Color',green);
%     %print(f, fullfile("B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall",'Effect_v_MeanConnectome',strcat('CohenD_v_MeanConnectome_vertex_',num2str(all_sig_pvalues(n)),'.png')),'-dpng','-r600');
% 
%      f=figure;
%     set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 2]*3.3*(72/96));
%     
%     semilogy(100*percent_All_data,blue_mean_data,'.');
%     xlabel('All - Percent Change')
%     ylabel('Log 10 of Mean Connectome Value')
%     hold on
%     semilogy(100*percent_All_data(idx_10pct_noUncharted_inOntologyOrder),blue_mean_data(idx_10pct_noUncharted_inOntologyOrder),'m.')    
%     semilogy(100*percent_All_data(idx_10pct_noUncharted_inOntologyOrder_Top15),blue_mean_data(idx_10pct_noUncharted_inOntologyOrder_Top15),'r.')
%     
    idx_large_effect=abs(percent_All_data)>1;

    if exist('out_data_keeper', 'var')
        offset=width(out_data_keeper);
        temp=blue_mean_data(idx_large_effect);
        out_data_keeper(offset+(1:numel(temp)))=temp;

        offset=width(out_outside_keeper);
        temp=blue_mean_data(~idx_large_effect);
        out_outside_keeper(offset+(1:numel(temp)))=temp;
    else
        out_data_keeper=blue_mean_data(idx_large_effect);
        out_outside_keeper=blue_mean_data(~idx_large_effect);
    end

    %semilogy(100*percent_All_data(idx_large_effect),blue_mean_data(idx_large_effect),'o','Color',green);
    %print(f, fullfile("B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall",'Effect_v_MeanConnectome',strcat('Percent_v_MeanConnectome_vertex_',num2str(all_sig_pvalues(n)),'.png')),'-dpng','-r600');

    %close all;
end