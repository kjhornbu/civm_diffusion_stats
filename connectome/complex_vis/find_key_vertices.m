function [idx_aboveThreshold,idx_top, positional_idx_top,node_keyvertices_entries] = find_key_vertices(key_node,matrix_2_print,matrix_2_print_names,ontology_Order)

%% What if instead we bake into this where the high signal is... that is we want at least 50% of the large effect vertices seen in the node but not noise vertices... that would be like
% Thresholding on 1% of the signal 

idx=reg_match(matrix_2_print_names,'raw_diff');
matrix_2_print_single_rd=abs(matrix_2_print{idx});

idx=reg_match(matrix_2_print_names,'edge');
matrix_2_print_single=matrix_2_print{idx};
Matrix_Criteria=mean(matrix_2_print_single);

idx_aboveThreshold=(Matrix_Criteria./max(Matrix_Criteria))>0.01;
idx_NOT_uncharted=[~cellfun(@isempty,ontology_Order.GN_Symbol);~cellfun(@isempty,ontology_Order.GN_Symbol)]';

%Check effect size for nodes...
idx=reg_match(matrix_2_print_names,'cohenD');
matrix_2_print_single_c=matrix_2_print{idx};
if size(matrix_2_print_single_c,1)>1
    Cohen_Matrix_Criteria=mean(matrix_2_print_single_c);
else
    %If only one row then we don't take the mean just keep the row because
    %we care about the responses for each vertex separately
    Cohen_Matrix_Criteria=matrix_2_print_single_c;
end

idx_NOT_nan=~isnan(Cohen_Matrix_Criteria); %If there are nan's that leak through remove them here



idx_10pct_noUncharted_nonan_inOntologyOrder=idx_aboveThreshold&idx_NOT_uncharted&idx_NOT_nan;
pos_idx_10pct_noUncharted_nonan_inOntologyOrder=find(idx_10pct_noUncharted_nonan_inOntologyOrder);

%% Filtering to Top 15 Vertices within the Node
N=15;
if sum(idx_10pct_noUncharted_nonan_inOntologyOrder)>N
    %[~,b]=sort(matrix_Criteria(idx_10pct_noUncharted_inOntologyOrder),'descend');
    [~,b]=sort(Cohen_Matrix_Criteria(idx_10pct_noUncharted_nonan_inOntologyOrder),'descend','ComparisonMethod','abs','MissingPlacement','last'); %the isnan checker should take care of the nan but in anyway "aces" should be low value for sorting.
    idx_10pct_noUncharted_inOntologyOrder_TopN=zeros(size(idx_10pct_noUncharted_nonan_inOntologyOrder));
    idx_10pct_noUncharted_inOntologyOrder_TopN(pos_idx_10pct_noUncharted_nonan_inOntologyOrder(b(1:N)))=1;
    idx_top=idx_10pct_noUncharted_inOntologyOrder_TopN>0;
else
    idx_top=idx_10pct_noUncharted_nonan_inOntologyOrder;
end

positional_idx_top=find(idx_top);

%% Getting key vertex information
node_keyvertices_entries=table;

for vertex_set=1:numel(positional_idx_top)
    node_keyvertices_entries.ROI_Node(vertex_set)=key_node;

    temp_split=strsplit(ontology_Order.Structure{ontology_Order.ROI==key_node},'_');
    node_keyvertices_entries.Structure_Node{vertex_set}=strjoin(temp_split(1:numel(temp_split)-1),'_');

    temp_split=strsplit(ontology_Order.GN_Symbol{ontology_Order.ROI==key_node},'-');
    node_keyvertices_entries.GN_Symbol_Node{vertex_set}=strjoin(temp_split(1:numel(temp_split)-1),'_');
    
    %node_keyvertices_entries.Effect_Size_Metric_used{vertex_set}=type;

    if positional_idx_top(vertex_set)>180
        adjust_idx=positional_idx_top(vertex_set)-180;
        node_keyvertices_entries.Hemisphere_Vertex{vertex_set}='contralateral';
    else
        adjust_idx=positional_idx_top(vertex_set);
        node_keyvertices_entries.Hemisphere_Vertex{vertex_set}='ipsilateral';
    end
    node_keyvertices_entries.ROI_Vertex(vertex_set)=ontology_Order.ROI(adjust_idx);

    temp_split=strsplit(ontology_Order.Structure{adjust_idx},'_');
    node_keyvertices_entries.Structure_Vertex{vertex_set}=strjoin(temp_split(1:numel(temp_split)-1),'_');

    temp_split=strsplit(ontology_Order.GN_Symbol{adjust_idx},'-');
    node_keyvertices_entries.GN_Symbol_Vertex{vertex_set}=strjoin(temp_split(1:numel(temp_split)-1),'_');

    node_keyvertices_entries.average_CohenD_value(vertex_set)=Cohen_Matrix_Criteria(positional_idx_top(vertex_set));
end

end
