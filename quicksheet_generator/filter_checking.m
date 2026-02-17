function [value,value_idx] = filter_checking(statistic_result,column_name)
logical_idx=~cellfun(@isempty,regexpi(statistic_result.Properties.VariableNames,column_name));
positional_idx=find(logical_idx);

if isempty(positional_idx)
    value={''};
    value_idx=ones(height(statistic_result),1);
else
    [value,~,value_idx]=unique(statistic_result.(positional_idx),'stable');
end

end