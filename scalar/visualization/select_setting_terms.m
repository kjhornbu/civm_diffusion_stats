function [setting_VariableNames] = select_setting_terms(setting)

setting_VariableNames=setting.Properties.VariableNames;

if sum(~cellfun(@isempty,regexpi(setting_VariableNames,'^(case)$')))
    setting_VariableNames=setting_VariableNames(3:end);
else
    setting_VariableNames=setting_VariableNames(2:end);
end

end