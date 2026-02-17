function [] = quick_sheet_generator(statistic_result,quick_save_path,varargin)

%In the  case of a path being put in.
if ~istable(statistic_result)
    statistic_result_temp=statistic_result;
    statistic_result=civm_read_table(statistic_result_temp);
end

column_name='contrast';
[value_contrast,value_idx_contrast]=filter_checking(statistic_result,column_name);
column_name='source_of_variation';
[value_sov,value_idx_sov]=filter_checking(statistic_result,column_name);

key_columns={'ROI','Structure','hemisphere_assignment','GN_Symbol','contrast','study_model','statistical_test','source_of_variation','pval','eta2','cohenF','stratification','pval_BH'};
length_key_columns=numel(key_columns);

if ~isempty(varargin)
    for n=1:numel(varargin)
        key_columns{length_key_columns+n}=varargin{n};
    end
end

logical_idx=~cellfun(@isempty,regexpi(statistic_result.Properties.VariableNames,strcat('^(',strjoin(key_columns,'|'),')$')));

% Contrast is the variable that is likely to actually not exist so we check
% and if not then we just use the sov
if numel(value_contrast)>1 && any(~cellfun(@isempty,value_contrast))
    for n=1:numel(value_contrast)
        for m=1:numel(value_sov)
            data_idx=(value_idx_contrast==n) & (value_idx_sov==m) & (statistic_result.pval_BH<0.05);
            data_temp=statistic_result(data_idx,logical_idx);

            %save to desired location
            temp_file_name=strcat('Reduced_Results_for_',value_sov{m},'_and_',value_contrast{n},'.csv');
            civm_write_table(data_temp,fullfile(quick_save_path,temp_file_name));
        end
    end
else
    for m=1:numel(value_sov)
        data_idx=(value_idx_sov==m) & (statistic_result.pval_BH<0.05);
        data_temp=statistic_result(data_idx,logical_idx);

        %save to desired location
        temp_file_name=strcat('Reduced_Results_for_',value_sov{m},'.csv');
        civm_write_table(data_temp,fullfile(quick_save_path,temp_file_name));
    end
end

end