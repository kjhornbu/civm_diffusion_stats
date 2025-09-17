function [output_paths] = save_output_from_scalar_analysis(save_location,hemisphere,filter_group,group,subgroup,zscore_grouping,group_summary_stats,specimen_zscore,result_table_BHFDR,multi_compare_table)

%if group or group1 the only criteria for the zscore grouping then just put
%as hemisphere else make the grouping condition and the hemisphere
%do a check on if the groupings contain

%the heading information for hte data should be the real entry name rather
%than "group1" "subgroup1" etc This pulls it back together.

[zscore_grouping_name] = clean_general_entries_to_study_conditional(group,subgroup,zscore_grouping);

%clean entry names of group_summmary_stats back to meaningful ones from the original dataframe
for n=1:numel(zscore_grouping)
    group_summary_find_general_name=~cellfun(@isempty,regexpi(group_summary_stats.Properties.VariableNames,strcat('^(',zscore_grouping{n},')$')));
    group_summary_stats.Properties.VariableDescriptions(group_summary_find_general_name)=group_summary_stats.Properties.VariableNames(group_summary_find_general_name);
    group_summary_stats.Properties.VariableNames(group_summary_find_general_name)=zscore_grouping_name(n);
end

%Remove the Trash Accuminlating in the Variable Descriptions Prior to
%Confusing others on Save
%group_summary_stats.Properties.VariableDescriptions={};
result_table_BHFDR.Properties.VariableDescriptions={};
group_summary_stats.Properties.Description='';
result_table_BHFDR.Properties.Description='';

group_summary_stats.Properties.Description='The - indicates averaging across the given column.\n';

%filter group is the filtering prior to the secondary analysis
if isempty(filter_group)
    save_location_name_check=dir(fullfile(save_location,hemisphere));

    if ~exist(char(save_location_name_check.folder), 'dir')
        mkdir(fullfile(save_location,hemisphere));
    end

    %save in the hemisphere folder the data with the grouping name
    civm_write_table(specimen_zscore,fullfile(save_location,hemisphere,strcat('Subject_Median_Zscore_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(multi_compare_table,fullfile(save_location,hemisphere,strcat('Posthoc_Results_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(group_summary_stats,fullfile(save_location,hemisphere,strcat('Group_Data_Table_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(result_table_BHFDR,fullfile(save_location,hemisphere,strcat('Group_Statistical_Results_withoutPairwiseComparisions_',strjoin([zscore_grouping_name],'_'),'.csv')));

    output_paths.Posthoc=fullfile(save_location,hemisphere,strcat('Posthoc_Results_',strjoin([zscore_grouping_name],'_'),'.csv'));
    output_paths.GroupTable=fullfile(save_location,hemisphere,strcat('Group_Data_Table_',strjoin([zscore_grouping_name],'_'),'.csv'));
    output_paths.StatsResults=fullfile(save_location,hemisphere,strcat('Group_Statistical_Results_withoutPairwiseComparisions_',strjoin([zscore_grouping_name],'_'),'.csv'));

else
    save_location_name_check=dir(fullfile(save_location,strjoin({hemisphere,filter_group},'_')));
    if ~exist(char(save_location_name_check.folder), 'dir')
        mkdir(fullfile(save_location,strjoin({hemisphere,filter_group},'_')));
    end

    %save in the hemisphere+filter folder the data with the grouping name
    civm_write_table(specimen_zscore,fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Subject_Median_Zscore_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(multi_compare_table,fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Posthoc_Results_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(group_summary_stats,fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Group_Data_Table_',strjoin([zscore_grouping_name],'_'),'.csv')));
    civm_write_table(result_table_BHFDR,fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Group_Statistical_Results_withoutPairwiseComparisions_',strjoin([zscore_grouping_name],'_'),'.csv')));

    output_paths.Posthoc=fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Posthoc_Results_',strjoin([zscore_grouping_name],'_'),'.csv'));
    output_paths.GroupTable=fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Group_Data_Table_',strjoin([zscore_grouping_name],'_'),'.csv'));
    output_paths.StatsResults=fullfile(save_location,strjoin({hemisphere,filter_group},'_'),strcat('Group_Statistical_Results_withoutPairwiseComparisions_',strjoin([zscore_grouping_name],'_'),'.csv'));

end
end