function [figure_entries,Top_idx_10pct_noUncharted_inOntologyOrder,make_Left_Axis] = place_data_in_matrix_blue_plot(directory,vertex,selection_pull,compare_group_A,compare_group_B,data,ontology_Order,total_Ordering,make_Left_Axis)

%Doing math to lay into matrix for printing and assigning the data labels
%of the y axis.

count = 1;
for m=1:numel(selection_pull)
    for o = 1:2
        if mod(o,2)==1
            matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))& (~cellfun(@isempty,regexpi(data.compare_group,compare_group_A)))}(total_Ordering);
            data_y_labels{count}=compare_group_A;
            count = count + 1;
        else
            matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))& (~cellfun(@isempty,regexpi(data.compare_group,compare_group_B)))}(total_Ordering);
            data_y_labels{count}=compare_group_B;
            count = count + 1;
        end
    end
end

matrix_Criteria=mean(matrix_2_print);
idx_vertex_10pct_noUncharted_inOntologyOrder=(matrix_Criteria./max(matrix_Criteria))>0.1 & [~cellfun(@isempty,ontology_Order.GN_Symbol);~cellfun(@isempty,ontology_Order.GN_Symbol)]';

%actually plotting and creating assignment for the left axis, top x axis as
%needed.
[figure_entries,Top_idx_10pct_noUncharted_inOntologyOrder,make_Left_Axis] = plot_blue_plot(directory,vertex,matrix_2_print,matrix_Criteria,selection_pull,data_y_labels,ontology_Order,make_Left_Axis,idx_vertex_10pct_noUncharted_inOntologyOrder);

end