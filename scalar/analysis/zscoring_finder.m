function [varargout] = zscoring_finder(data_table,test_groups,do_median,groups_to_remove)
%% validate that nargout is the right value when conditions are set.
if exist('groups_to_remove','var') && do_median && numel(groups_to_remove)>0
    assert(nargout == 2, 'Wrong number of outputs for this given function');
else
    assert(nargout == 1, 'Wrong number of outputs for this given function');
end

%% standarize the data using z-score to remove undesired effects if have covariates you want to remove
if exist('groups_to_remove','var')
    [data_standardized]=zscore_method(data_table,groups_to_remove);
    varargout{1}=data_standardized;
end

%%  Getting Median Zscore for each specimen grouping type so that can get estimate of best specimen to pick
if do_median==1
    %% Preliminary Setups
    specimen_zscore=table;
    if ~exist('data_standardized','var')
        [data_standardized_keygroups]=zscore_method(data_table,test_groups);
    else
        [data_standardized_keygroups]=zscore_method(data_standardized,test_groups);
    end

    [data_name, data_idx] = data_idx_name(data_standardized_keygroups);
    [specimen_name_list,~,specimen_name_idx]=unique(data_standardized_keygroups.specimen,'stable');

    for n=1:numel(specimen_name_list)
        specimen_zscore.specimen{n}=specimen_name_list{n};
        %write the specific grouped condition
        temp=unique(data_standardized_keygroups(specimen_name_idx==n,test_groups));
        assert(height(temp)==1,'Too many conditions found double check test groups input')

        specimen_zscore.zscore_calculated_via_groupingby{n}=strjoin(table2array(temp));

        clear temp;

        temp(1,:)=median(table2array(data_standardized_keygroups(specimen_name_idx==n,data_idx)),1,"omitnan");
        temp_table=array2table(temp,'VariableNames',strcat(data_name,'_MedianZscore'));

        if n==1
            length_group=size(specimen_zscore,2);
            length_temp=size(temp,2);
            specimen_zscore(n,length_group+(1:length_temp))=temp_table;
            specimen_zscore.Properties.VariableNames(length_group+(1:length_temp))=temp_table.Properties.VariableNames;
        else
            length_temp=size(temp_table,2);
            specimen_zscore(n,temp_table.Properties.VariableNames)=temp_table;
        end

        specimen_zscore.Mean_MedianZscore(n)=mean(table2array(specimen_zscore(n,length_group+(1:length_temp))));
        specimen_zscore.mean_ABS_MedianZscore(n)=mean(abs(table2array(specimen_zscore(n,length_group+(1:length_temp)))));

        specimen_zscore.Mean_MedianZscore_FA_Vol(n)=mean(table2array(specimen_zscore(n,~cellfun(@isempty,regexp(specimen_zscore.Properties.VariableNames,'^(fa|volume_mm3)')))));
        specimen_zscore.Mean_ABS_MedianZscore_FA_Vol(n)=mean(abs(table2array(specimen_zscore(n,~cellfun(@isempty,regexp(specimen_zscore.Properties.VariableNames,'^(fa|volume_mm3)'))))));
    end

    if ~exist('data_standardized','var')
        varargout{1}=specimen_zscore;
    else
        varargout{2}=specimen_zscore;
    end
end
end

function [name, idx] = data_idx_name(data)
idx=column_find(data.Properties.VariableNames,'(_mean|volume_mm3|voxels|volume_fraction)$'); %actual idx not in logical array format
name=data.Properties.VariableNames(:,idx);
end

function [group_mean, group_std] = pull_groupmean_groupstd(data,grouping)
[data_name, ~] = data_idx_name(data);
[group_mean,group_std] = group_summary_statistics(data,data_name,grouping);
end

function [groupcol_inData_positional_idx,unique_groups,unique_groups_positions] = select_groupings_from_data (data,grouping)
groupcol_inData_idx=regexpi(data.Properties.VariableNames,strcat('^(',strjoin(grouping,'|'),')$'));
groupcol_inData_positional_idx=find(~cellfun(@isempty,groupcol_inData_idx)==1);
[unique_groups,~,unique_groups_positions]=unique(data(:,groupcol_inData_positional_idx));
end

function [data_standardized]=zscore_method(data_table,groups_to_select)
data_standardized=data_table;
% force table into a knowable order.
data_standardized=sortrows(data_standardized,'ROI');

%Get mean and Standard deviation
[remove_group_mean, remove_group_std] = pull_groupmean_groupstd(data_standardized,groups_to_select);

data_standardized=column_reorder(data_standardized,groups_to_select);
remove_group_mean=column_reorder(remove_group_mean,groups_to_select);
remove_group_std=column_reorder(remove_group_std,groups_to_select);

[~, data_idx] = data_idx_name(data_standardized);

[~,full_data_remove_type,full_data_remove_type_idx] = select_groupings_from_data(data_standardized,groups_to_select);
[~,remove_group_mean_type,remove_group_mean_type_idx] = select_groupings_from_data(remove_group_mean,groups_to_select);
[~,remove_group_std_type,remove_group_std_type_idx] = select_groupings_from_data(remove_group_std,groups_to_select);

%% Making some assumptions about the ordering.
for m=1:size(full_data_remove_type,1)
    %All specimen of one data type
    %The problem is this is not the same idx for the same thing here!!!
    string_regex=strcat('^(',table2array(full_data_remove_type(m,groups_to_select)),')$');

    for term=1:numel(string_regex)
        mean_logical_idx(:,term)=~cellfun(@isempty,regexpi(remove_group_mean_type{:,term},string_regex{term}));
        std_logical_idx(:,term)=~cellfun(@isempty,regexpi(remove_group_std_type{:,term},string_regex{term}));
    end

    mean_pos=find(sum(mean_logical_idx,2)==numel(string_regex));
    std_pos=find(sum(std_logical_idx,2)==numel(string_regex));

    full_remove=sortrows(data_standardized(full_data_remove_type_idx==m,:),'ROI');
    removemean=sortrows(remove_group_mean(remove_group_mean_type_idx==mean_pos,:),'ROI');
    removestd=sortrows(remove_group_std(remove_group_std_type_idx==std_pos,:),'ROI');

    [~, data_removemean_idx] = data_idx_name(removemean);
    [specimen_name_list,~,specimen_name_idx]=unique(full_remove.specimen,'stable');

    for o=1:size(specimen_name_list,1)
        %Checking the ROI values to the same set of ROI -- This sorts
        %on ROI
        mean_data=innerjoin(full_remove(specimen_name_idx==o,:),removemean,'Keys','ROI','LeftVariables','ROI');
        std_data=innerjoin(full_remove(specimen_name_idx==o,:),removestd,'Keys','ROI','LeftVariables','ROI');
        specimen_data=innerjoin(mean_data,full_remove(specimen_name_idx==o,:),'Keys','ROI','LeftVariables','ROI');

        assert(height(mean_data)==height(specimen_data),'Datas are not the same length: check ROI -- to mean table')
        assert((numel(data_standardized.ROI)/numel(unique(data_standardized.specimen)))==height(specimen_data),'Datas are not the same length: check ROI -- to main table')

        numerator= table2array(specimen_data(:,data_idx))-table2array(mean_data(:,data_removemean_idx));
        denominator = table2array(std_data(:,data_removemean_idx));

        data=numerator./denominator;

        % Check for the no standard deviation, no changing mean case
        % which is really a 0 zscore

        zero_variability_mask=(numerator == 0 & denominator == 0);
        data(zero_variability_mask)=0;

        data=array2table(data);
        data.Properties.VariableNames=specimen_data.Properties.VariableNames(data_idx);

        % find this specimen in data_standarized
        select_correct_specimen_idx=row_find(data_standardized,'^specimen$',specimen_name_list{o});
        data_standardized(select_correct_specimen_idx,data_idx)=data;
    end
end
end