function [output_difference] = create_difference_metric_for_connectome_JamesVersion(output,selection_pull,groupA,groupB)
% A is the control group
% B is the treatment group
output_difference=table;
vertex=unique(output.vertex);

for n=1:size(vertex,1)
    output_difference.selection_group{n}=selection_pull;

    %% Constant GroupA (as in for all selection the same groups) or Different Groups for GroupA (as in different groups for each selection)
    output_difference.compare_group_A{n}=groupA;

    %% Constant GroupB (as in for all selection the same groups) or Different Groups for GroupB (as in different groups for each selection)
    output_difference.compare_group_B{n}=groupB;

    output_difference.vertex(n)=vertex(n,1);
    output_difference.ROI(n)=vertex(n,1);

    %% Constant GroupA (as in for all selection the same groups) or Different Groups for GroupA (as in different groups for each selection)
    idx_A=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull,')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupA,')$'))) & output.vertex==vertex(n);
    %% Constant GroupB (as in for all selection the same groups) or Different Groups for GroupB (as in different groups for each selection)
    idx_B=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull,')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,strcat('^(',groupB,')$'))) & output.vertex==vertex(n);

    output_difference.percent_difference{n}=(output.data{idx_B}-output.data{idx_A})./output.data{idx_A};
    output_difference.raw_difference{n}=(output.data{idx_B}-output.data{idx_A});
    numerator=((output.N(idx_B)-1).*output.std_data{idx_B}.^2)+((output.N(idx_A)-1).*output.std_data{idx_A}.^2);
    denominator=output.N(idx_B)+output.N(idx_A)-2;
    PooledSTD=sqrt(numerator/denominator);
    output_difference.cohenD_difference{n}=(output.data{idx_B}-output.data{idx_A})./PooledSTD;
end
end