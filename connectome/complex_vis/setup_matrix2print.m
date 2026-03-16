function [matrix_2_print,data_y_labels] = setup_matrix2print(data,selection_pull,vertex,total_Ordering,plot_type,difference_criteria,compare_group_A,compare_group_B)
%creates the matrix2print for both plot types
switch plot_type
    case "edge"
        count = 1;
        for m=1:numel(selection_pull)
            for o = 1:2
                if mod(o,2)==1
                    if numel(compare_group_A)==numel(selection_pull)
                        matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))& (~cellfun(@isempty,regexpi(data.compare_group,strcat('^(',compare_group_A{m},')$'))))};
                        data_y_labels{count}=compare_group_A{m};
                    elseif numel(compare_group_A)==1
                        matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))& (~cellfun(@isempty,regexpi(data.compare_group,strcat('^(',compare_group_A,')$'))))};
                        data_y_labels{count}=compare_group_A{:};
                    end
                    
                    count = count + 1;
                else
                    if numel(compare_group_B)==numel(selection_pull)
                        matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group,strcat('^(',compare_group_B{m},')$'))))};
                        data_y_labels{count}=compare_group_B{m};
                    elseif numel(compare_group_B)==1
                        matrix_2_print(count,:)=data.data{(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group,strcat('^(',compare_group_B,')$'))))};
                        data_y_labels{count}=compare_group_B{:};
                    end
                    count = count + 1;
                end
            end
        end
    case "effect"
        for m=1:numel(selection_pull)
            if numel(compare_group_A)==numel(selection_pull) && numel(compare_group_B)==numel(selection_pull)
                matrix_2_print(m,:)=data.(difference_criteria){(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group_A,strcat('^(',compare_group_A{m},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group_B,strcat('^(',compare_group_B{m},')$'))))};
                data_y_labels{m}=strcat(selection_pull{m},':',compare_group_A{m},32,'v',32,compare_group_B{m});
            elseif numel(compare_group_A)==1 &&  numel(compare_group_B)==1
                matrix_2_print(m,:)=data.(difference_criteria){(data.vertex==vertex(1,1))&(~cellfun(@isempty,regexpi(data.selection_group,strcat('^(',selection_pull{m},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group_A,strcat('^(',compare_group_A{:},')$'))))&(~cellfun(@isempty,regexpi(data.compare_group_B,strcat('^(',compare_group_B{:},')$'))))};
                data_y_labels{m}=selection_pull{m};
            end
        end
end
% Re order matrix into ontology ordering
matrix_2_print=matrix_2_print(:,total_Ordering);

end