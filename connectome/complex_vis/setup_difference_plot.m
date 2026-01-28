function [figure_entries,make_lut_img] = setup_difference_plot(directory,vertex,selection_pull,matrix_2_print,positional_idx,difference_criteria,ontology_Order,make_lut_img)
%% Find only Key Regions within data
%the positional_idx_region is in the order of strength of difference? 
% Filter out Zero idxs
matrix_2_print_onlyKeyRegions=matrix_2_print(:,positional_idx);

[LUT,make_lut_img] = make_effectplot_LUT(directory,difference_criteria,matrix_2_print_onlyKeyRegions,make_lut_img);
[figure_entries] = plot_difference_plot(directory,difference_criteria,vertex,selection_pull,matrix_2_print_onlyKeyRegions,LUT,ontology_Order,positional_idx);

end