function [output_difference] = create_difference_metric_for_connectome(output,selection_pull,groupA,groupB)
% A is the control group
% B is the treatment group
output_difference=table;
count = 1;

vertex=unique(output.vertex);

for n=1:size(vertex,1)
    for m=1:numel(selection_pull)
        output_difference.selection_group{count}=selection_pull{m};
        
        %% Constant GroupA (as in for all selection the same groups) or Different Groups for GroupA (as in different groups for each selection)
        if numel(groupA)==numel(selection_pull)
            output_difference.compare_group_A{count}=groupA{m};
        elseif numel(groupA)==1
            output_difference.compare_group_A{count}=groupA{:};
        end

        %% Constant GroupB (as in for all selection the same groups) or Different Groups for GroupB (as in different groups for each selection)
        if numel(groupB)==numel(selection_pull)
            output_difference.compare_group_B{count}=groupB{m};
        elseif numel(groupB)==1
            output_difference.compare_group_B{count}=groupB{:};
        end

        output_difference.vertex(count)=vertex(n,1);
        output_difference.ROI(count)=vertex(n,1);

        %% Constant GroupA (as in for all selection the same groups) or Different Groups for GroupA (as in different groups for each selection)
        if numel(groupA)==numel(selection_pull)
            idx_A=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupA{m},')$'))) & output.vertex==vertex(n);
        elseif numel(groupA)==1
            idx_A=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupA{:},')$'))) & output.vertex==vertex(n);
        end

        %% Constant GroupB (as in for all selection the same groups) or Different Groups for GroupB (as in different groups for each selection)
        if numel(groupB)==numel(selection_pull)
            idx_B=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupB{m},')$'))) & output.vertex==vertex(n);
        elseif numel(groupB)==1
            idx_B=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupB{:},')$'))) & output.vertex==vertex(n);
        end

        output_difference.percent_difference{count}=(output.data{idx_B}-output.data{idx_A})./output.data{idx_A};
        output_difference.raw_difference{count}=(output.data{idx_B}-output.data{idx_A});
        numerator=((output.N(idx_B)-1).*output.std_data{idx_B}.^2)+((output.N(idx_A)-1).*output.std_data{idx_A}.^2);
        denominator=output.N(idx_B)+output.N(idx_A)-2;
        PooledSTD=sqrt(numerator/denominator);
        output_difference.cohenD_difference{count}=(output.data{idx_B}-output.data{idx_A})./PooledSTD;

        count=count+1;
    end
end
end