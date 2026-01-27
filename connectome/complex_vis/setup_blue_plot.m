function [figure_entries,make_Left_Axis,name_entries] = setup_blue_plot(directory,vertex,selection_pull,matrix_2_print,data_y_labels,logical_idx_vertex,ontology_Order,make_Left_Axis)
%actually plotting and creating assignment for the left axis, top x axis as
%needed.
[figure_entries,make_Left_Axis,name_entries] = plot_blue_plot_get_key_vertex_details(directory,vertex,matrix_2_print,selection_pull,data_y_labels,ontology_Order,make_Left_Axis,logical_idx_vertex);
end