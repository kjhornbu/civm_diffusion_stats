function [idx_top, positional_idx_top,name_entries] = find_key_vertices(matrix_2_print,matrix_2_print_names,ontology_Order)

%% the original match for high signal
idx=reg_match(matrix_2_print_names,'blue');

matrix_2_print_single=matrix_2_print{idx};
matrix_Criteria=mean(matrix_2_print_single);
idx_10pct_noUncharted_inOntologyOrder=(matrix_Criteria./max(matrix_Criteria))>0.1 & [~cellfun(@isempty,ontology_Order.GN_Symbol);~cellfun(@isempty,ontology_Order.GN_Symbol)]';
pos_idx_10pct_noUncharted_inOntologyOrder=find(idx_10pct_noUncharted_inOntologyOrder);

%% Filtering to Top 15 Vertices within the Node
N=15;
if sum(idx_10pct_noUncharted_inOntologyOrder)>N
    [~,b]=sort(matrix_Criteria(idx_10pct_noUncharted_inOntologyOrder),'descend');
    idx_10pct_noUncharted_inOntologyOrder_TopN=zeros(size(idx_10pct_noUncharted_inOntologyOrder));
    idx_10pct_noUncharted_inOntologyOrder_TopN(pos_idx_10pct_noUncharted_inOntologyOrder(b(1:N)))=1;
    idx_top=idx_10pct_noUncharted_inOntologyOrder_TopN>0;
else
    idx_top=idx_10pct_noUncharted_inOntologyOrder;
end
positional_idx_top=find(idx_top);

%% Getting key vertex information
name_entries=table;
for vertex_set=1:numel(positional_idx_top)
    if positional_idx_top(vertex_set)>180
        name_entries.ROI(vertex_set)=ontology_Order.ROI(positional_idx_top(vertex_set)-180);
        name_entries.Structure{vertex_set}=ontology_Order.Structure{positional_idx_top(vertex_set)-180};
        name_entries.GN_Symbol{vertex_set}=ontology_Order.GN_Symbol{positional_idx_top(vertex_set)-180};
        name_entries.Hemisphere{vertex_set}='contralateral';
    else
        name_entries.ROI(vertex_set)=ontology_Order.ROI(positional_idx_top(vertex_set));
        name_entries.Structure{vertex_set}=ontology_Order.Structure{positional_idx_top(vertex_set)};
        name_entries.GN_Symbol{vertex_set}=ontology_Order.GN_Symbol{positional_idx_top(vertex_set)};
        name_entries.Hemisphere{vertex_set}='ipsilateral';
    end
end