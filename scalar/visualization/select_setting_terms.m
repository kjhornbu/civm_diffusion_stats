function [setting_VariableNames,start_idx] = select_setting_terms(setting)

setting_VariableNames=setting.Properties.VariableNames;

if nnz(~cellfun(@isempty,regexpi(setting_VariableNames,'^(case)$')))
    setting_VariableNames=setting_VariableNames(3:end);
    start_idx=3;
else
    setting_VariableNames=setting_VariableNames(2:end);
    start_idx=2;
end

end