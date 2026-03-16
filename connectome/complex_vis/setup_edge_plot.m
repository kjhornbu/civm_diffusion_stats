function [figure_entries,make_Left_Axis] = setup_blue_plot(directory,vertex,selection_pull,matrix_2_print,data_y_labels,logical_idx_vertex,ontology_Order,make_Left_Axis)
%actually plotting the "Blue Plot" which is the for a given node the mean response (for specific groupg selections) across all regions within that node and creating assignment for the left axis, top x axis asneeded.
[figure_entries,make_Left_Axis] = plot_blue_plot(directory,vertex,matrix_2_print,selection_pull,data_y_labels,ontology_Order,make_Left_Axis,logical_idx_vertex);
end