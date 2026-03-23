function [output_connectome,output_difference,output_plot_vertex_LUT] = full_edge_effect_setup(directory,dataframe,data_scaling,comparison,meaningful_nodes)

graphs=load_graph(dataframe);
if data_scaling
    graphs=graphs.*dataframe.scale; % not pulling from the saved graphs --- we are getting it from the dataframe (ie typically the archive)
end

%ontology_Order=civm_read_table("Ontology_Order_EdgeStrengthPlots.csv");
ontology_Order=civm_read_table("Ontology_Layout_DMBA_20260317_RobFixedOrder.txt");
[ontology_Order,total_Ordering] = find_proper_ontology_order(ontology_Order,size(graphs,2)/2);

for n=1:numel(comparison)

    if ~isfield(comparison(n),'stratification')||isempty(comparison(n).stratification)
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
    compare_a=fieldnames(comparison(n).grouping.Basis);
    compare_b=fieldnames(comparison(n).grouping.UnderTest);

    [~,compare_group_A,compare_group_A_idx]=find_group_information_from_groupingcriteria(dataframe,compare_a);
    [~,compare_group_B,compare_group_B_idx]=find_group_information_from_groupingcriteria(dataframe,compare_b);

    clear compare_a_term
    for m=1:numel(compare_a)
        compare_a_term{m}=comparison(n).grouping.Basis.(compare_a{m});
    end
    compare_a_name=strjoin(fliplr(compare_a_term),' ');
    positional_idx_A=find(reg_match(compare_group_A,compare_a_name));

    clear compare_b_term
    for m=1:numel(compare_b)
        compare_b_term{m}=comparison(n).grouping.UnderTest.(compare_b{m});
    end
    compare_b_name=strjoin(fliplr(compare_b_term),' ');
    positional_idx_B=find(reg_match(compare_group_B,compare_b_name));

    %Get connectomic data and differences for each comparsion and compile
    %into a tabular format for each ROI in the connectome (not filtering
    %ROIs at this point)
    [output_connectome{n}] = create_contralateral_ipsilateral_StructInput(graphs,selection_name,selection_group_idx,postional_idx_selection,compare_a_name,compare_group_A_idx,positional_idx_A,compare_b_name,compare_group_B_idx,positional_idx_B);
    [output_difference{n}] = create_difference_metric_for_connectome_StructInput(output_connectome{n},selection_name,compare_a_name,compare_b_name);
end

output_connectome=vertcat(output_connectome{:});
output_difference=vertcat(output_difference{:});

% plot traditional square connectome on the output_connectome data


%Give data on a 0:0.995 scale rather than 0 to 100 which stretches out the
%top signal
 max_entry_data=horzcat(output_connectome.data{:});
% [a,b]=ecdf(max_entry_data);
% [~,idx]=min(abs(a-0.995));
% 
% max_entry=b(idx);

max_entry=max(max_entry_data,[],'all');

%% Generate Plots -- basically do this unit over and over again to make figures with different selection pull and different directories.
make_Left_Axis=1;
make_LUT_img=1;
output_plot_vertex_LUT=table;

%get all options out of the setup data in the order they were placed in the
%table
selection_pull=unique(output_connectome.selection_group,'stable');
compare_group_A_pull=unique(output_difference.compare_group_A,'stable');
compare_group_B_pull=unique(output_difference.compare_group_B,'stable');

% plot traditional square connectome on the output_connectome data
plot_FullConnectome_contralateral_ipsilateral(directory,output_connectome,total_Ordering);

figure_output=table;
for n=1:numel(meaningful_nodes)
    [matrix_2_print_edge,data_y_labels] = setup_matrix2print(output_connectome,selection_pull,meaningful_nodes(n),total_Ordering,'edge','',compare_group_A_pull,compare_group_B_pull);
    [matrix_2_print_cohenD,data_y_labels_cohenD] = setup_matrix2print(output_difference,selection_pull,meaningful_nodes(n),total_Ordering,'effect','cohenD_difference',compare_group_A_pull,compare_group_B_pull);
    [matrix_2_print_percent,data_y_labels_percent] = setup_matrix2print(output_difference,selection_pull,meaningful_nodes(n),total_Ordering,'effect','percent_difference',compare_group_A_pull,compare_group_B_pull);
    [matrix_2_print_rawdiff,~] = setup_matrix2print(output_difference,selection_pull,meaningful_nodes(n),total_Ordering,'effect','raw_difference',compare_group_A_pull,compare_group_B_pull);

    matrix_2_print={matrix_2_print_edge;matrix_2_print_cohenD;matrix_2_print_percent;matrix_2_print_rawdiff};
    matrix_2_print_names={'edge','cohenD','percent','raw_diff'};

    [idx_aboveThreshold,idx_10pct_noUncharted_inOntologyOrder_Top15,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,node_keyvertices_entries] = find_key_vertices(meaningful_nodes(n),matrix_2_print,matrix_2_print_names,ontology_Order);

    %setup LUT of output plot vertices per each key node
    if ~isempty(node_keyvertices_entries)
        offset=height(output_plot_vertex_LUT);
        output_plot_vertex_LUT(offset+[1:height(node_keyvertices_entries)],:)=node_keyvertices_entries;


        %The edge plot doesn't need a wrapper since we dont' make a LUT for it or only pull out key regions
        [figure_entries,make_Left_Axis] = plot_edge_plot(directory,meaningful_nodes(n),matrix_2_print_edge,selection_pull,data_y_labels,ontology_Order,idx_aboveThreshold,make_Left_Axis,idx_10pct_noUncharted_inOntologyOrder_Top15,max_entry);
        [~,make_LUT_img] = setup_difference_plot(directory,meaningful_nodes(n),data_y_labels_cohenD,matrix_2_print_cohenD,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'cohenD_difference',ontology_Order,make_LUT_img);
        
        if n==1
            figure_output=figure_entries;
        else
            figure_output(figureoffset+[1:height(figure_entries)],:)=figure_entries;
        end
        figureoffset=height(figure_output);

        if n==1
            %Allow both effect difference plots to have LUTs generated on first
            %pass
            make_LUT_img=1;
        end

        [~,make_LUT_img] = setup_difference_plot(directory,meaningful_nodes(n),data_y_labels_percent,matrix_2_print_percent,positional_idx_10pct_noUncharted_inOntologyOrder_Top15,'percent_difference',ontology_Order,make_LUT_img);
    end
end

output_connectome.idx_in_dataframe=[];
output_connectome.indiv_specimen_data=[];
output_connectome.indiv_specimen_std=[];

civm_write_table(output_connectome,fullfile(directory,strcat('OutputConnectome_',datestr(datetime("today")),'.csv')));
civm_write_table(output_difference,fullfile(directory,strcat('OutputDifferences_',datestr(datetime("today")),'.csv')));

civm_write_table(figure_output,fullfile(directory,strcat('EdgeStrength_FigureProperties',datestr(datetime("today")),'.csv')));
civm_write_table(output_plot_vertex_LUT,fullfile(directory,strcat('Top15Vertices_ForEachNode_',datestr(datetime("today")),'.csv')));
end