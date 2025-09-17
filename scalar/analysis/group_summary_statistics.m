function [group_mean,group_std,group_median,group_IQR] = group_summary_statistics(data_table,data_name,test_grouping)

%list of super key things to keep track of for each ROI to make sure we can
%return to the key information for the individual
%Bookkeeping_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','structure_id'};
Bookkeeping_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','structure_id'};

% To cleverly generate the averages for all the reasonable possiblities, 
% we'll need to run for (2^(nGroupColumns))-1. That will be used as a binary count
% from 1..((2^(nGroupColumns))-)
output_means_to_generate=(2^(numel(test_grouping)));%-1; %converted from (2^(numel(test_grouping)))-1; on 20250916

output_mean=cell(1,output_means_to_generate);
output_std=cell(1,output_means_to_generate);
output_median=cell(1,output_means_to_generate);
output_IQR=cell(1,output_means_to_generate);

% For each test grouping iterate and add to the list
%THIS IS COUNTING WRONG NOW! WHEN I TRY TO REMOVE THE SEX TERM this also
%doesn't have an overall which would be useful to have. 
for n=1:output_means_to_generate

    character_array=dec2bin(n-1,numel(test_grouping));
    %converted from character_array=dec2bin(n,numel(test_grouping)); on 20250916
    logical_array=logical(character_array-'0');

    grouping_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin([Bookkeeping_list test_grouping{1,logical_array} ],'|'),')$'));
    grouping_names=data_table.Properties.VariableNames(~cellfun(@isempty,grouping_idx));

    [output_mean{n},output_std{n},output_median{n},output_IQR{n}] = group_summary_math(data_table,data_name,grouping_names);

    if n~=output_means_to_generate
        positional_idx=find(~logical_array==1);
        for m=1:numel(positional_idx)
            if ischar(test_grouping{1,positional_idx(m)})
                k=test_grouping{1,positional_idx(m)};
            else
                k=strjoin(test_grouping{1,positional_idx(m)},'_');
            end
            output_mean{n}.(k)=repmat({'-'},height(output_mean{n}),1);
            output_std{n}.(k)=repmat({'-'},height(output_std{n}),1);
            output_median{n}.(k)=repmat({'-'},height(output_median{n}),1);
            output_IQR{n}.(k)=repmat({'-'},height(output_IQR{n}),1);
        end
    end
end

%Then when we remove sex from the terms in the table we 
group_mean=column_reorder(vertcat(output_mean{:}),grouping_names);
group_mean.Properties.Description='The - indicates averaging across the given column.\n';
group_std=column_reorder(vertcat(output_std{:}),grouping_names);
group_std.Properties.Description='The - indicates averaging across the given column.\n';
group_median=column_reorder(vertcat(output_median{:}),grouping_names);
group_median.Properties.Description='The - indicates averaging across the given column.\n';
group_IQR=column_reorder(vertcat(output_IQR{:}),grouping_names);
group_IQR.Properties.Description='The - indicates averaging across the given column.\n';


% force order to match our outptut so we can simplify testing.
data_table=column_reorder(data_table,test_grouping);
%Probably broke Variable descirptions so repair from original table.
data_idx=column_find(data_table.Properties.VariableNames,strcat('^(',strjoin(test_grouping,'|'),')$'));
test_descriptions=data_table.Properties.VariableDescriptions(data_idx);

%% fix this table descriptions which broke due to our column elimination and recovery earlier
% because james is crazy, put all the tables in a cell so we can loop. 
% THIS IS CURRENTLY BROKEN FOR STRATIFICAITON 2024-11-04
tables={group_mean,group_std,group_median,group_IQR};
for t_n=1:numel(tables)
    % THIS IS CURRENTLY BROKEN FOR STRATIFICAITON 2024-11-04 -- the data
    % table is causing the issue because sex is a reserved term?
    table_idx=column_find(tables{t_n}.Properties.VariableNames,['^(',strjoin(test_grouping,'|'),')$']);
    tables{t_n}.Properties.VariableDescriptions(table_idx)=test_descriptions;
end
% pull the tables backout of the cell array to return normally
[group_mean,group_std,group_median,group_IQR]=tables{:};


end

function [group_mean,group_std,group_median,group_IQR] = group_summary_math(data_table,data_name,grouping_names)
%% Create local cell math functions
omean = @(x) mean(x,'omitnan');
omedian = @(x) median(x,'omitnan');
ostd = @(x) std(x,'omitnan');
opercentile25 = @(x) prctile(x,25);
opercentile75 = @(x) prctile(x,75);

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
