function data_select = select_data_in_EmbeddingFile(data,specimen_number,data_height)
logical_X_idx=~cellfun(@isempty,regexpi(data.Properties.VariableNames,'^X'));
positional_X_idx=find(logical_X_idx==1);

data_select=table2array(data(:,positional_X_idx));

data_select=reshape(data_select,specimen_number,data_height,[]);
data_select=permute(data_select,[3,2,1]);

nan_mask=isnan(data_select);
data_select(nan_mask)=0;
end