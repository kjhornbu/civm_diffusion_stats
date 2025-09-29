function [group_mean,group_std,group_median,group_IQR] = group_summary_statistics_connectome(data_table,data_name,zscore_grouping)

%% Create local cell math functions
omean = @(x) mean(x,'omitnan');
omedian = @(x) median(x,'omitnan');
ostd = @(x) std(x,'omitnan');
opercentile25 = @(x) prctile(x,25);
opercentile75 = @(x) prctile(x,75);

%list of super key things to keep track of for each ROI to make sure we can
%return to the key information for the individual
Bookkeeping_list={'vertex'};

%all the data we want to group on
grouping_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(Bookkeeping_list,'|'),'|',strjoin(zscore_grouping,'|'),')$'));
grouping_names=data_table.Properties.VariableNames(~cellfun(@isempty,grouping_idx));

%overarching mean and standard deviation etc given the grouping we are interested in
group_mean=varfun(omean,data_table,'GroupingVariables',grouping_names(:),'InputVariables',data_name);
group_mean.Properties.VariableNames=strrep(group_mean.Properties.VariableNames,'Fun_','');

group_std=varfun(ostd,data_table,'GroupingVariables',grouping_names(:),'InputVariables',data_name);
group_std.Properties.VariableNames=strrep(group_std.Properties.VariableNames,'Fun_','');

group_median=varfun(omedian,data_table,'GroupingVariables',grouping_names(:),'InputVariables',data_name);
group_median.Properties.VariableNames=strrep(group_median.Properties.VariableNames,'Fun_','');

group_percentile25=varfun(opercentile25,data_table,'GroupingVariables',grouping_names(:),'InputVariables',data_name);
group_percentile25.Properties.VariableNames=strrep(group_percentile25.Properties.VariableNames,'Fun_','');

group_percentile75=varfun(opercentile75,data_table,'GroupingVariables',grouping_names(:),'InputVariables',data_name);
group_percentile75.Properties.VariableNames=strrep(group_percentile75.Properties.VariableNames,'Fun_','');

%Then doing final work for the IQR data putting everyting together
grouping_idx_25=~cellfun(@isempty,regexpi(group_percentile25.Properties.VariableNames,strcat('^(',strjoin(data_name,'|'),')$')));
grouping_idx_75=~cellfun(@isempty,regexpi(group_percentile75.Properties.VariableNames,strcat('^(',strjoin(data_name,'|'),')$')));

%IQR calculation is Percentile75-Percentile25
temp=table('Size',[size(group_median,1),size(data_name,2)],'VariableTypes',repmat({'double'},[size(data_name,2),1])','VariableNames',data_name);
temp(:,:)=array2table(table2array(group_percentile75(:,grouping_idx_75))-table2array(group_percentile25(:,grouping_idx_25)));

grouping_name_idx_25=~cellfun(@isempty,regexpi(group_percentile25.Properties.VariableNames,strcat('^(GroupCount|',strjoin(grouping_names,'|'),')$')));
group_IQR=group_percentile25(:,grouping_name_idx_25);

length_group=size(group_IQR,2);
length_temp=size(temp,2);
group_IQR(:,length_group+(1:length_temp))=temp;
group_IQR.Properties.VariableNames(length_group+(1:length_temp))=data_name;

end