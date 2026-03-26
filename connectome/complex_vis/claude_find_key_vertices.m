function [idx_aboveThreshold,idx_top, positional_idx_top,node_keyvertices_entries,connections_for_key_inLUT] = claude_find_key_vertices(connection_LUT,key_node,matrix_2_print,matrix_2_print_names,ontology_Order)

[~,connections_for_key_inLUT,output_ontology_set] = claude_found_regions(connection_LUT,ontology_Order,key_node);

%Always have the left and right versions of each region included in the
%dataset.
%Which one is the positioning in the ontology that we are keeping or
ordered_total=[output_ontology_set.ontology_order;output_ontology_set.ontology_order+180];

%for each of the matrix2 print graphics zero out  or nan out the not useful
%regions The nan-out in CohenD will allow you to completely exclude these
%regions. -- Should we be only doing the zeroed out data from now on? 
for n=1:height(matrix_2_print)
    temp_matrix_2_print=matrix_2_print{n};
    if reg_match(matrix_2_print_names{n},'cohenD')
        data_saver=nan(size(temp_matrix_2_print));
    else
        data_saver=zeros(size(temp_matrix_2_print));
    end
    % but is the matrix_2_print in ROI order or ontology order!!!!!!!!
    % Matrix_2_print is in ontology order so we grab the way we grab from
    % the L/R vertex setup.
    data_saver(:,ordered_total)=temp_matrix_2_print(:,ordered_total);
    matrix_2_print{n}=data_saver;
end
%run through the normal vertex finder to grab a Top 15 list
[idx_aboveThreshold,idx_top, positional_idx_top,node_keyvertices_entries] = find_key_vertices(key_node,matrix_2_print,matrix_2_print_names,ontology_Order);

% Return connections where we couldn't find a region. -- This should be
% saved and stored so we can refer back and adjust the included regions as
% needed. 
connections_for_key_inLUT(connections_for_key_inLUT.Found_In_DMBA==1,:)=[];
end