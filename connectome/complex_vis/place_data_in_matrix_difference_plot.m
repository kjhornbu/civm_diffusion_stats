function [figure_entries,make_lut_img] = place_data_in_matrix_difference_plot(directory,vertex,selection_pull,idx_vertex_10pct_noUncharted_inOntologyOrder,difference_criteria,data,ontology_Order,total_Ordering,make_lut_img)

for m=1:numel(selection_pull)
    matrix_2_print(m,:)=data.(difference_criteria){(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))};
end
% Re order matrix into ontology ordering
matrix_2_print=matrix_2_print(:,total_Ordering);

%% Re order matrix and Find only Key Regions
%the positional_idx_region is in the order of strength of difference? 
% Filter out Zero idxs
idx_vertex_10pct_noUncharted_inOntologyOrder(idx_vertex_10pct_noUncharted_inOntologyOrder==0)=[];
matrix_2_print_onlyKeyRegions=matrix_2_print(:,idx_vertex_10pct_noUncharted_inOntologyOrder);

%now put in the order of stuff you actually want
[~,positional_idx_regions_sorted]=sort(idx_vertex_10pct_noUncharted_inOntologyOrder);
matrix_2_print_onlyKeyRegions=matrix_2_print_onlyKeyRegions(:,positional_idx_regions_sorted); %reordering teh matrix to the correct position

positional_idx_regions=idx_vertex_10pct_noUncharted_inOntologyOrder(positional_idx_regions_sorted); %now putting into the proper ordering
[LUT,make_lut_img] = make_percentChange_LUT(directory,difference_criteria,matrix_2_print_onlyKeyRegions,make_lut_img);

[figure_entries] = plot_difference_plot(directory,difference_criteria,vertex,selection_pull,matrix_2_print_onlyKeyRegions,LUT,ontology_Order,positional_idx_regions);

end