function [Data] = combine_mean_std_from_groups(Data)

[roi,~,roi_value_idx]=unique(Data.ROI,'stable');
if  numel(roi)==numel(roi_value_idx)
    warning('Only one row per ROI, no work to do.');
    return;
end
%{
    idx_groupcount=regexp(Data.Properties.VariableNames,strcat( 'GroupCount$'));
    idx_mean=regexp(Data.Properties.VariableNames,strcat( 'mean$'));
    idx_std=regexp(Data.Properties.VariableNames,strcat( 'std$'));
    idx_median=regexp(Data.Properties.VariableNames,strcat( 'median$'));
    idx_IQR=regexp(Data.Properties.VariableNames,strcat( 'IQR$'));

    logical_idx_groupcount=~cellfun(@isempty,idx_groupcount);
    logical_idx_mean=~cellfun(@isempty,idx_mean);
    logical_idx_std=~cellfun(@isempty,idx_std);
    logical_idx_median=~cellfun(@isempty,idx_median);
    logical_idx_IQR=~cellfun(@isempty,idx_IQR);
%}
col_names=Data.Properties.VariableNames;
idx_groupcount=column_find(col_names,'GroupCount$');
idx_mean=column_find(col_names,'mean$');
idx_std=column_find(col_names,'std$');
%{
idx_median=column_find(col_names,'median$');
idx_IQR=column_find(col_names,'IQR$');
%}
groupcount_name=col_names{idx_groupcount};
%{
mean_names=col_names(idx_mean);
std_names=col_names(idx_std);
median_names=col_names(idx_median);
IQR_names=col_names(idx_IQR);
%}

%do check for ROI out here first! (if on average >1 roi per data entry then need to combine which has a lot of holes in the data dropping in the mean)
for n=1:numel(roi)
    ROI_rows=Data(roi_value_idx==n,:);
    % NOT certain this should only be one row :D
    assert(height(ROI_rows)==1,'data selector failed, should only have one row');
    % preallocations to shut matlab up.
    top_std=zeros(height(ROI_rows),numel(idx_std));
    bottom_std=zeros(height(ROI_rows),numel(idx_groupcount));
    top_mean=zeros(height(ROI_rows),numel(idx_mean));
    bottom_mean=zeros(height(ROI_rows),numel(idx_groupcount));

    for m=1:height(ROI_rows)
        %Get Pooled STD
        top_std(m,:)=(table2array(ROI_rows(m,idx_groupcount))-1)*table2array(ROI_rows(m,idx_std)).^2;
        bottom_std(m,:)=(table2array(ROI_rows(m,idx_groupcount))-1);
        %Get Weighted Mean of Means
        top_mean(m,:)=table2array(ROI_rows(m,idx_groupcount))*table2array(ROI_rows(m,idx_mean));
        bottom_mean(m,:)=table2array(ROI_rows(m,idx_groupcount));
    end

    Data.(groupcount_name)(roi_value_idx==n)=sum(table2array(ROI_rows(:,idx_groupcount)));

    %% Final clean up math and assigning back to the table
    try
        Data.(std_name)(roi_value_idx==n)=sqrt(sum(top_std)/sum(bottom_std));
        Data.(mean_name)(roi_value_idx==n)=sum(top_mean)/sum(bottom_mean);
    catch exception
        warning(exception.identifier,'Error getting mean/std to re-insert : %s',exception.message)
        keyboard;
    end

    %% Can't combine Median or IQR without the Full Range so put NaN for Them
    Data.(median_name)(roi_value_idx==n)=NaN;
    Data.(IQR_name)(roi_value_idx==n)=NaN;

end

end