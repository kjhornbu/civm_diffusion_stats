function [idx_aboveThreshold,idx_top, positional_idx_top,node_keyvertices_entries,connections_for_key_inLUT] = claude_find_key_vertices(connection_LUT,key_node,matrix_2_print,matrix_2_print_names,ontology_Order)

[~,connections_for_key_inLUT,output_ontology_set] = claude_found_regions(connection_LUT,ontology_Order,key_node);

%Always have the left and right versions of each region included in the
%dataset.
ordered_ROI=sort(output_ontology_set.ROI);
ordered_ROI_total=[ordered_ROI; ordered_ROI+180];

%for each of the matrix2 print graphics zero out  or nan out the not useful
%regions The nan-out in CohenD will allow you to completely exclude these
%regions. 
for n=1:height(matrix_2_print)
    temp_matrix_2_print=matrix_2_print{n};
    if reg_match(matrix_2_print_names{n},'cohenD')
        data_saver=nan(size(temp_matrix_2_print));
    else
        data_saver=zeros(size(temp_matrix_2_print));
    end
    data_saver(:,ordered_ROI_total)=temp_matrix_2_print(:,ordered_ROI_total);
    matrix_2_print{n}=data_saver;
end
%run through the normal vertex finder to grab a Top 15 list
[idx_aboveThreshold,idx_top, positional_idx_top,node_keyvertices_entries] = find_key_vertices(key_node,matrix_2_print,matrix_2_print_names,ontology_Order);

% Return connections where we couldn't find a region. -- This should be
% saved and stored so we can refer back and adjust the included regions as
% needed. 
connections_for_key_inLUT(connections_for_key_inLUT.Found_In_DMBA==1,:)=[];
end