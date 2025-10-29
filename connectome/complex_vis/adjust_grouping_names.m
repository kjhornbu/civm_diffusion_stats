function [output_connectome,output_difference,compare_group_A_Prime,compare_group_B_Prime]=adjust_grouping_names(output_connectome,output_difference,compare_group_A,compare_group_A_Prime,compare_group_B,compare_group_B_Prime)

if ~strcmp(compare_group_A,compare_group_A_Prime)
    idx_group=~cellfun(@isempty,regexpi(output_connectome.compare_group,strcat('^(',compare_group_A,')$')));
    output_connectome.compare_group(idx_group)={compare_group_A_Prime};

    idx_diff_group=~cellfun(@isempty,regexpi(output_difference.compare_group_A,strcat('^(',compare_group_A,')$')));
    output_difference.compare_group_A(idx_diff_group)={compare_group_A_Prime};
end

if ~strcmp(compare_group_B,compare_group_B_Prime)
    idx_group=~cellfun(@isempty,regexpi(output_connectome.compare_group,strcat('^(',compare_group_B,')$')));
    output_connectome.compare_group(idx_group)={compare_group_B_Prime};

    idx_diff_group=~cellfun(@isempty,regexpi(output_difference.compare_group_B,strcat('^(',compare_group_B,')$')));
    output_difference.compare_group_B(idx_diff_group)={compare_group_B_Prime};
end

end