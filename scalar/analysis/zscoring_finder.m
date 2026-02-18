function [varargout] = zscoring_finder(data_table,zscore_grouping,varargin)
%% Preliminary Setups
specimen_zscore=table;
count=1;
      
groups_to_remove=varargin;

data_idx=column_find(data_table.Properties.VariableNames,'(_mean|volume_mm3|voxels|volume_fraction)$'); %actual idx not in logical array format
data_name=data_table.Properties.VariableNames(:,data_idx);

%% standarize the data using z-score to remove undesired effects if have covariates you want to remove
if numel(varargin)>0
    data_standardized=data_table;
    % force table into a knowable order.
    [ROI_value,~,ROI_idx]=unique(data_standardized.ROI);
    data_standardized=sortrows(data_standardized,'ROI');

    %Get mean and Standard deviation
    [remove_group_mean,remove_group_std] = group_summary_statistics(data_table, data_name, groups_to_remove);

    standarization_grouping_idx=regexpi(remove_group_mean.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
    standarization_grouping_positional_idx=find(~cellfun(@isempty,standarization_grouping_idx)==1);
    [remove_data_type,~,remove_data_type_idx]=unique(remove_group_mean(:,standarization_grouping_positional_idx),'stable');

    zscore_remove_fulldata_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(groups_to_remove,'|'),')$'));
    zscore_remove_fulldata_positional_idx=find(~cellfun(@isempty,zscore_remove_fulldata_idx)==1);
    [full_data_remove_type,~,full_data_remove_type_idx]=unique(data_table(:,zscore_remove_fulldata_positional_idx),'stable');

    %% Making some assumptions about the ordering.
    for m=1:size(full_data_remove_type,1)
        %All specimen of one data type
        full_remove_test=sortrows(data_table(full_data_remove_type_idx==m,:),'ROI');
        removemean_test=sortrows(remove_group_mean(remove_data_type_idx==m,:),'ROI');
        removestd_test=sortrows(remove_group_std(remove_data_type_idx==m,:),'ROI');

        data_removemean_cells=regexpi(removemean_test.Properties.VariableNames,'(_mean|volume_mm3|voxels|volume_fraction)$'); % we actually don't want voxelss because it follows same math of all other
        data_removemean_idx=find(~cellfun(@isempty,data_removemean_cells)==1); %actual idx not in logical array format
        data_removemean_name=removemean_test.Properties.VariableNames(~cellfun(@isempty,data_removemean_cells));

        [specimen_name_list,~,specimen_name_idx]=unique(full_remove_test.specimen,'stable');

        for o=1:size(specimen_name_list,1)
            %Checking the ROI values to the same set of ROI -- This sorts
            %on ROI
            mean_data=innerjoin(full_remove_test(specimen_name_idx==o,:),removemean_test,'Keys','ROI','LeftVariables','ROI');
            std_data=innerjoin(full_remove_test(specimen_name_idx==o,:),removestd_test,'Keys','ROI','LeftVariables','ROI');
            specimen_data=innerjoin(mean_data,full_remove_test(specimen_name_idx==o,:),'Keys','ROI','LeftVariables','ROI');

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
    varargout{1}=data_standardized;
else

end

%%  Getting Median Zscore for each specimen grouping type so that can get estimate of best specimen to pick
if ~exist('data_standardized','var')
    zscore_grouping_fulldata_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(zscore_grouping,'|'),')$'));
    zscore_grouping_fulldata_positional_idx=find(~cellfun(@isempty,zscore_grouping_fulldata_idx)==1);
    [full_data_type,~,full_data_type_idx]=unique(data_table(:,zscore_grouping_fulldata_positional_idx),'stable');

    %% for each zscore type find the difference from each specimen to the "mean" response in standard deviation
    %use this to rank order the output variables by the grouping types to
    %select the specimen you want (say light sheet or some other "representative specimen" type application) for a given condition.

    [group_mean,group_std] = group_summary_statistics(data_table,data_name,zscore_grouping);
else
    zscore_grouping_fulldata_idx=regexpi(data_standardized.Properties.VariableNames,strcat('^(',strjoin(zscore_grouping,'|'),')$'));
    zscore_grouping_fulldata_positional_idx=find(~cellfun(@isempty,zscore_grouping_fulldata_idx)==1);
    [full_data_type,~,full_data_type_idx]=unique(data_standardized(:,zscore_grouping_fulldata_positional_idx),'stable');

    %% for each zscore type find the difference from each specimen to the "mean" response in standard deviation
    %use this to rank order the output variables by the grouping types to
    %select the specimen you want (say light sheet or some other "representative specimen" type application) for a given condition.

    [group_mean,group_std] = group_summary_statistics(data_standardized,data_name,zscore_grouping);
end

%% Reorder columns because something schenanigans related resorted us unexpectedly
group_mean=column_reorder(group_mean,zscore_grouping);
group_std=column_reorder(group_std,zscore_grouping);
full_data_type=column_reorder(full_data_type,zscore_grouping);

zscore_grouping_idx=regexpi(group_mean.Properties.VariableNames,strcat('^(',strjoin(zscore_grouping,'|'),')$'));
zscore_grouping_positional_idx=find(~cellfun(@isempty,zscore_grouping_idx)==1);
[group_type,~,group_type_idx]=unique(group_mean(:,zscore_grouping_positional_idx),'stable');


%% Now Find the Zscore for picking specimen from groups and if desired
%re-standarize the data based on the removal groups
for m=1:size(full_data_type,1)
    clear Match_condition
    % Make sure data is the same order
    if ~exist('data_standardized','var')
        full_test=sortrows(data_table(full_data_type_idx==m,:),['Structure']);
    else
        full_test=sortrows(data_standardized(full_data_type_idx==m,:),['Structure']);
    end

    %get the match with the full options
    for o=1:numel(zscore_grouping)
        Match_condition(:,o)=~cellfun(@isempty,regexpi( group_type.(zscore_grouping{o}), strcat('^',full_data_type.(zscore_grouping{o})(m),'$') ) );
    end
    logical_idx_group_type=sum(Match_condition,2)==numel(zscore_grouping);
    positional_idx_group_type=find(logical_idx_group_type==1);
    if 1 <  numel(positional_idx_group_type)
        warning('Expected ONLY one index here!, blame james :p');
        keyboard
    end
    %Pull out the matched conditionout of the full array
    groupmean_test=sortrows(group_mean(group_type_idx==positional_idx_group_type,:),['Structure']);
    groupstd_test=sortrows(group_std(group_type_idx==positional_idx_group_type,:),['Structure']);

    data_groupmean_cells=regexpi(groupmean_test.Properties.VariableNames,'(_mean|volume_mm3|voxels|volume_fraction)$'); % we actually don't want voxelss because it follows same math of all other
    data_groupmean_idx=find(~cellfun(@isempty,data_groupmean_cells)==1); %actual idx not in logical array format
    data_groupmean_name=groupmean_test.Properties.VariableNames(~cellfun(@isempty,data_groupmean_cells));

    data_groupmean_name=strrep(data_groupmean_name,'Fun_',''); %cleaned column name

    [specimen_name_list,~,specimen_name_idx]=unique(full_test.specimen,'stable');

    for o=1:size(specimen_name_list,1)
        %Lets Keep the whole Zscore ranking of the data (the median is not smart about its reduction so maybe lets not include in the same output table)

        %Checking the ROI values to the same set of ROI
        mean_data=innerjoin(full_test(specimen_name_idx==o,:),groupmean_test,'Keys','ROI','LeftVariables','ROI');
        std_data=innerjoin(full_test(specimen_name_idx==o,:),groupstd_test,'Keys','ROI','LeftVariables','ROI');
        specimen_data=innerjoin(groupmean_test,full_test(specimen_name_idx==o,:),'Keys','ROI','LeftVariables','ROI');

        %Do actual ZScoring
        numerator= table2array(specimen_data(:,data_idx))-table2array(mean_data(:,data_groupmean_idx));
        denominator = table2array(std_data(:,data_groupmean_idx));

        data=numerator./denominator;

        % Check for the no standard deviation, no changing mean case
        % which is really a 0 zscore

        zero_variability_mask=(numerator == 0 & denominator == 0);
        data(zero_variability_mask)=0;

        specimen_zscore.specimen{count}=specimen_name_list(o);
        %write the specific grouped condition
        specimen_zscore.zscore_calculated_via_groupingby{count}=strjoin(group_type{positional_idx_group_type,:});

        temp=table('Size',[1,size(data_name,2)],'VariableTypes',repmat({'double'},[size(data_name,2),1])','VariableNames',strcat(data_groupmean_name,'_MedianZscore'));
        temp=array2table(median(data,1,"omitnan"));

        if count==1
            length_group=size(specimen_zscore,2);
            length_temp=size(temp,2);
            specimen_zscore(count,length_group+(1:length_temp))=temp;
            specimen_zscore.Properties.VariableNames(length_group+(1:length_temp))=strcat(data_groupmean_name,'_MedianZscore');
        else
            length_temp=size(temp,2);
            specimen_zscore(count,length_group+(1:length_temp))=temp;
        end

        specimen_zscore.Mean_MedianZscore(count)=mean(table2array(specimen_zscore(count,length_group+(1:length_temp))));
        specimen_zscore.ABSMean_MedianZscore(count)=abs(specimen_zscore.Mean_MedianZscore(count));

        specimen_zscore.Mean_MedianZscore_FA_Vol(count)=mean(table2array(specimen_zscore(count,~cellfun(@isempty,regexp(specimen_zscore.Properties.VariableNames,'^(fa|volume_mm3)')))));
        specimen_zscore.ABSMean_MedianZscore_FA_Vol(count)=abs(specimen_zscore.Mean_MedianZscore_FA_Vol(count));

        count=count+1;
    end
end

if ~exist('data_standardized','var')
    varargout{1}=specimen_zscore;
else
    varargout{2}=specimen_zscore;
end

end