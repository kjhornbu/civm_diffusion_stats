close all;
clear all;

%% Preliminaries
dataframe_path="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
compare='Genotype';
selection=list2cell('Strain');

directory="Z:\All_Staff\20.5xFAD.02\Test_circos_gen";
selection_pull=list2cell('All');
compare_group_A='nTG';
compare_group_B='FAD';
threshold=0.1;

vertex=9;

%% Running Portion - With Brain Scaling
ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
dataframe=civm_read_table(dataframe_path);
graphs=load_graph(dataframe);

data_scaling=1; % turn graphs into brain scaled graphs
if data_scaling
    graphs=graphs.*dataframe.scale;
end

[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);

[compare_group,~,compare_group_idx]=unique(dataframe.(compare));

for n=1:numel(selection)
    [selection_group,~,selection_group_idx]=unique(dataframe.(selection{n}));
    [output_connectome{n}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);
end

% To do all things together together at end
selection_group=list2cell('All');
selection_group_idx=ones(height(dataframe),1);
[output_connectome{numel(selection)+1}] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx);

output_connectome=vertcat(output_connectome{:});

create_circos_file(directory,ontology_Order,total_Ordering,vertex,output_connectome,selection_pull,compare_group_A,compare_group_B,threshold); 
