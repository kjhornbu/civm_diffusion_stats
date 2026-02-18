function [] = quick_sheet_generator(statistic_result,quick_save_path,varargin)

%in the  case of a path being put in.
if ~istable(statistic_result)
    statistic_result_temp=statistic_result;
    statistic_result=civm_read_table(statistic_result_temp);
end

%% Checking for the contrast, source of variation, and stratificaiton columns
column_name='contrast';
[value_contrast,value_idx_contrast]=filter_checking(statistic_result,column_name);
column_name='source_of_variation';
[value_sov,value_idx_sov]=filter_checking(statistic_result,column_name);
column_name='stratification';
[value_stratification,~]=filter_checking(statistic_result,column_name);
% In the case that the stratiifcation is not empty (ie it has something) --
% break it on delineations = and ,
if ~reg_match(value_stratification,'') 
    string_stratification=strsplit(value_stratification{:},{'=',','});
    if reg_match(string_stratification{end-1},'hemisphere')
        %in the case of we just grabbed hemisphere clear out the
        %stratification checking
        clear string_stratification
    else
        string_stratification_temp= string_stratification;
        clear string_stratification        
        string_stratification{1}=strjoin(string_stratification_temp(2+2:2:numel(string_stratification_temp)),'_');
    end
end

%% Setup key columns to keep
key_columns={'ROI','Structure','hemisphere_assignment','GN_Symbol','contrast','study_model','statistical_test','source_of_variation','pval','eta2','cohenF','stratification','pval_BH'};
length_key_columns=numel(key_columns);
% Add in varargin to the end as needed. These are the explicit colun names.
if ~isempty(varargin)
    for n=1:numel(varargin)
        key_columns{length_key_columns+n}=varargin{n};
    end
end

logical_idx=~cellfun(@isempty,regexpi(statistic_result.Properties.VariableNames,strcat('^(',strjoin(key_columns,'|'),')$')));

% What do we do in the case of stratified data sets? How are we going to
% put the data within those with the names appropriately? 

% Contrast is the variable that is likely to actually not exist so we check
% and if not then we just use the sov
if numel(value_contrast)>1 && any(~cellfun(@isempty,value_contrast))
    for n=1:numel(value_contrast)
        for m=1:numel(value_sov)
            data_idx=(value_idx_contrast==n) & (value_idx_sov==m) & (statistic_result.pval_BH<0.05);
            data_temp=statistic_result(data_idx,logical_idx);

            %save to desired location
            if exist('string_stratification','var')
                temp_file_name=strcat('Stratified_by_',string_stratification{1},'_Reduced_Results_for_',value_sov{m},'SourceOnly_and_',value_contrast{n},'_SigAfterBHCorrection.csv');
            else
                temp_file_name=strcat('Reduced_Results_for_',value_sov{m},'SourceOnly_and_',value_contrast{n},'_SigAfterBHCorrection.csv');
            end
            civm_write_table(data_temp,fullfile(quick_save_path,temp_file_name));
        end
    end
else
    for m=1:numel(value_sov)
        data_idx=(value_idx_sov==m) & (statistic_result.pval_BH<0.05);
        data_temp=statistic_result(data_idx,logical_idx);

        %save to desired location
        if exist('string_stratification','var')
            temp_file_name=strcat('Stratified_by_',string_stratification{1},'_Reduced_Results_for_',value_sov{m},'SourceOnly_SigAfterBHCorrection.csv');
        else
            temp_file_name=strcat('Reduced_Results_for_',value_sov{m},'SourceOnly_SigAfterBHCorrection.csv');
        end
        civm_write_table(data_temp,fullfile(quick_save_path,temp_file_name));
    end
end

end