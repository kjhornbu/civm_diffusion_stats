function [idx_vertex_10pct_noUncharted_inOntologyOrder_top] = find_key_vertices(matrix_2_print,matrix_2_print_names)

%% the original match high signal
idx=reg_match(matrix_2_print_names,'blue');

matrix_Criteria=matrix_2_print{idx};
idx_10pct_noUncharted_inOntologyOrder=(matrix_Criteria./max(matrix_Criteria))>0.1 & [~cellfun(@isempty,ontology_Order.GN_Symbol);~cellfun(@isempty,ontology_Order.GN_Symbol)]';

% Filtering to Top 15
N=15;
if sum(idx_10pct_noUncharted_inOntologyOrder)>N
    [~,b]=sort(blue_mean_data(idx_10pct_noUncharted_inOntologyOrder),'descend');
    idx_10pct_noUncharted_inOntologyOrder_TopN=zeros(size(idx_10pct_noUncharted_inOntologyOrder));
    idx_10pct_noUncharted_inOntologyOrder_TopN(pos_idx_10pct_noUncharted_inOntologyOrder(b(1:N)))=1;
    idx_vertex_10pct_noUncharted_inOntologyOrder_top=idx_10pct_noUncharted_inOntologyOrder_TopN>0;
else
    idx_vertex_10pct_noUncharted_inOntologyOrder_top=idx_10pct_noUncharted_inOntologyOrder;
end

end