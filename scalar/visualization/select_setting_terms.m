function [setting_VariableNames,start_idx] = select_setting_terms(setting)

setting_VariableNames=setting.Properties.VariableNames;

flag_terms=find(~cellfun(@isempty,regexpi(setting_VariableNames,'^(makeimage|applytoppt)$')));
start_term=find(~cellfun(@isempty,regexpi(setting_VariableNames,'^(source_of_variation)$')));

if nnz(~cellfun(@isempty,regexpi(setting_VariableNames,'^(case)$')))
    start_idx=(start_term+1);
    end_idx=(flag_terms(1)-1);
    setting_VariableNames=setting_VariableNames(start_idx:end_idx);
else
    keyboard;
end

end