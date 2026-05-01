function [filtered_Stats,filtered_Data] = stat_filtering(stats_Filter,Filter)
%This selects in the stat data and the group data table and selects what we
%actually want to compare on x and y axis.

for n = 1:height(Filter)
    for m = 1:width(Filter.Field{n})
        [idx(:,m)] = filterData_byInput(Filter.Data{n},Filter.Field{n}{m},Filter.Entry{n}{m});
    end
    combo_filter(:,n) = (sum(idx,2)==width(idx));
    filtered_Data{n} = sortrows(Filter.Data{n}(combo_filter(:,n),:),"GN_Symbol");
end

for c = 1:height(stats_Filter)
    [contrast_value,~,contrast_idx] = unique(stats_Filter.Data{c}.contrast); %will look up different contrasts? -- not now... we are doing one unit of work but this still allows flexiablity
    [source_idx] = filterData_byInput(stats_Filter.Data{c},'source_of_variation',stats_Filter.source{c}); %fixed unit of source to compare x and y axis.

    contrast_lookup_logical_idx = ~cellfun(@isempty,regexpi(contrast_value,stats_Filter.contrast{c}));
    contrast_lookup_positional_idx = find(contrast_lookup_logical_idx);

    combo_filter = source_idx & (contrast_idx==contrast_lookup_positional_idx);

    filtered_Stats{c} = sortrows(stats_Filter.Data{c}(combo_filter,:),"GN_Symbol");
    clear combo_filter

    %if we have a nan pval it is likely a BRN region --- we remove it for
    %the given contrast (but we don't want to just clear it out)
    if  sum(isnan(filtered_Stats{c}.pval))~=0
        rm_Region_lookup_logical_idx = isnan(filtered_Stats{c}.pval);

        temp = filtered_Stats{c}(rm_Region_lookup_logical_idx,:);
        filtered_Stats{c}(rm_Region_lookup_logical_idx,:) = [];

        for n = 1:width(filtered_Data)
            rm_Region_inData_logical_idx = filterData_byInput(filtered_Data{n},"GN_Symbol",temp.GN_Symbol);
            filtered_Data_byContrast{n} = filtered_Data{n}(~rm_Region_inData_logical_idx,:);
        end
    end

    %if we had to filter out a region then use that otherwise use the
    %normal filtered data.
    if exist('filtered_Data_byContrast','var')
        filtered_Stats{c}.PercentChange = (filtered_Data_byContrast{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')))-filtered_Data_byContrast{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))./filtered_Data_byContrast{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('BASIS_',strjoin(unique(filtered_Data_byContrast{1}{:,1:numel(Filter.Entry{1})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))=filtered_Data_byContrast{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('TEST_',strjoin(unique(filtered_Data_byContrast{2}{:,1:numel(Filter.Entry{2})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))=filtered_Data_byContrast{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('BASIS_',strjoin(unique(filtered_Data_byContrast{1}{:,1:numel(Filter.Entry{1})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_std'))))=filtered_Data_byContrast{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_std')));
        filtered_Stats{c}.(strcat('TEST_',strjoin(unique(filtered_Data_byContrast{2}{:,1:numel(Filter.Entry{2})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_std'))))=filtered_Data_byContrast{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_std')));
        
    else
        filtered_Stats{c}.PercentChange = (filtered_Data{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')))-filtered_Data{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))./filtered_Data{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('BASIS_',strjoin(unique(filtered_Data{1}{:,1:numel(Filter.Entry{1})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))=filtered_Data{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('TEST_',strjoin(unique(filtered_Data{2}{:,1:numel(Filter.Entry{2})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_mean'))))=filtered_Data{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_mean')));
        filtered_Stats{c}.(strcat('BASIS_',strjoin(unique(filtered_Data{1}{:,1:numel(Filter.Entry{1})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_std'))))=filtered_Data{1}.(cell2str(strcat(stats_Filter.contrast{c},'_group_std')));
        filtered_Stats{c}.(strcat('TEST_',strjoin(unique(filtered_Data{2}{:,1:numel(Filter.Entry{2})}),'_'),'_',cell2str(strcat(stats_Filter.contrast{c},'_group_std'))))=filtered_Data{2}.(cell2str(strcat(stats_Filter.contrast{c},'_group_std')));
    end
    clear filtered_Data_byContrast
end
end