function [] = generate_figures(save_location,Subject_Table,Group_Table,Statistical_Results,pvalue_type,pval_threshold,Key_Grouping_Columns)
Save_Interesting_Data= table;

interesting_path=fullfile(save_location,'Summary',strcat('Significant_Statistical_Results.csv'));
if exist(interesting_path,'file')
    warning('Work appears complete, remove %s to re-run',interesting_path);
    return;
end
file_extension={'png','svg'};

direction='descend';
%Direction of sorts
ranking_criteria='cohenF';
%sorting criteria

check_rob_sheet=sum(~cellfun(@isempty,regexpi(Subject_Table.Properties.VariableNames,'GN_Symbol')));

if check_rob_sheet==1
    Bookkeeping_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','structure_id','GroupCount'};
    name_abb="GN_Symbol";
elseif check_rob_sheet==0
    Bookkeeping_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','structure_id','GroupCount'};
    name_abb="Structure";
end

[source_of_variations,~,source_of_variations_idx]=unique(Statistical_Results.source_of_variation);
for m=1:numel(source_of_variations)
    save_location_withSoV=fullfile(save_location,strrep(source_of_variations{m},':','x'));

    Statistical_Results_SOV=Statistical_Results(source_of_variations_idx==m,:);
    [Contrasts,~,Contrasts_idx]=unique(Statistical_Results_SOV.contrast);

    Key_Grouping_Columns_toSources_idx=~cellfun(@isempty,regexpi(Key_Grouping_Columns,strjoin(strsplit(source_of_variations{m},':'),'|')));

    group_sov_lookup_idx=~cellfun(@isempty,regexpi(Group_Table.Properties.VariableNames,strjoin(strsplit(source_of_variations{m},':'),'|')));
    group_key_columns_idx=~cellfun(@isempty,regexpi(Group_Table.Properties.VariableNames,strjoin(Key_Grouping_Columns,'|')));
    group_key_columns_positional_idx=find(group_key_columns_idx);

    group_sov_lookup_idx=group_sov_lookup_idx(group_key_columns_positional_idx);

    [group_full,~,~] = find_group_information_from_groupingcriteria(Group_Table,Key_Grouping_Columns);

    if sum(Key_Grouping_Columns_toSources_idx)==numel(Key_Grouping_Columns)
        %remove all dashes (not everything that has a dash)
        group_source_of_variation_positional_idx=~contains(group_full,'-');
    else
        %Keep dash entries in the opposite of the condition working on 
        separated_group_full=split(group_full,' ');
        logical_NOT_dash_idx=~strcmp(separated_group_full,'-');

        %The Key_Grouping Columns are not in the same order as
        %the column names in the sheet. 
        group_source_of_variation_positional_idx=sum(logical_NOT_dash_idx==group_sov_lookup_idx,2)==numel(Key_Grouping_Columns); %This is the problem right here... it is grabbing it on the wrong column here??
    end

    for n=1:numel(Contrasts)
        save_location_withSoVContrasts=fullfile(save_location_withSoV,Contrasts{n});

        Statistical_Results_SOV_Contrast=Statistical_Results_SOV(Contrasts_idx==n,:);

        Subject_Table_positional_idx=column_find(Subject_Table.Properties.VariableNames,strjoin([Bookkeeping_list,{'specimen',Contrasts{n},Key_Grouping_Columns{:}}],'|'));
        Subject_Table_Contrast=Subject_Table(:,Subject_Table_positional_idx);

        Group_Table_positional_idx=column_find(Group_Table.Properties.VariableNames,strjoin([Bookkeeping_list,{Contrasts{n},Key_Grouping_Columns{:}}],'|'));
        Group_Table_Contrast_SOV=Group_Table(group_source_of_variation_positional_idx,Group_Table_positional_idx); %this is not selecting the correct indices. 
        
        positional_idx_cohen_f=column_find(Statistical_Results_SOV_Contrast,'cohenF$');
        positional_idx_pval=column_find(Statistical_Results_SOV_Contrast,strcat(pvalue_type,'$'));

        %Make sure sorting is all done before we start to find indices. 
        Statistical_Results_SOV_Contrast=sortrows(Statistical_Results_SOV_Contrast,positional_idx_cohen_f,direction);

        %Find significant ROI to put in plot
        significant_data_logical_idx=Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})<=pval_threshold; 
        signficant_data_positional_idx=find(significant_data_logical_idx==1);

        significant_data_logical_idx=Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})>0.05 & Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})<=0.1; 
        row_idx_G1=find(significant_data_logical_idx==1);
        significant_data_logical_idx=Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})>0.1 & Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})<=0.2; 
        row_idx_G2=find(significant_data_logical_idx==1);
        significant_data_logical_idx=Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})>0.2 & Statistical_Results_SOV_Contrast.(Statistical_Results_SOV_Contrast.Properties.VariableNames{positional_idx_pval})<=0.5; 
        row_idx_G3=find(significant_data_logical_idx==1);

        %Make CohenF Figure
        % cohenf plotting crashes on t-score data. it also doesn't really
        % make sense to plot this for t-scores. 
        if ~startsWith(Contrasts{n},'t_')
            file_name=strcat(strrep(source_of_variations{m},':','x'),'_',Contrasts{n},'_CohenF');
            %makeCohenFFig(save_location_withSoVContrasts,file_name,file_extension,Statistical_Results_SOV_Contrast,signficant_data_positional_idx);
            makeCohenFFig_MultiThresColors(save_location_withSoVContrasts,file_name,file_extension,Statistical_Results_SOV_Contrast,signficant_data_positional_idx,row_idx_G1,row_idx_G2,row_idx_G3)
        end

        %Get Interesting ROIs
        Interesting_ROIs=Statistical_Results_SOV_Contrast(signficant_data_positional_idx,:);

        length_Save_Interesting_Data=height(Save_Interesting_Data);
        if length_Save_Interesting_Data == 0
            Save_Interesting_Data=Interesting_ROIs;
        else
            Save_Interesting_Data(length_Save_Interesting_Data+(1:height(Interesting_ROIs)),:)=Interesting_ROIs;
        end
       
        ROIKeepNum=10;
        if height(Interesting_ROIs)>ROIKeepNum
           Interesting_ROIs=Interesting_ROIs(1:ROIKeepNum,:);
        end
        
        Interesting_Data_Table_Indiv=innerjoin(Subject_Table_Contrast,Interesting_ROIs,"Keys",'ROI','RightVariables',ranking_criteria);
        Interesting_Data_Table_Indiv=sortrows(Interesting_Data_Table_Indiv,ranking_criteria,direction);

        Interesting_Data_Table_Group=innerjoin(Group_Table_Contrast_SOV,Interesting_ROIs,"Keys",'ROI','RightVariables',ranking_criteria);
        Interesting_Data_Table_Group=sortrows(Interesting_Data_Table_Group,ranking_criteria,direction);

        if ~isempty(Interesting_Data_Table_Group) || ~isempty(Interesting_Data_Table_Indiv)%if no data is interesting don't plot
            %Make Group Figure
            file_name=strcat(strrep(source_of_variations{m},':','x'),'_',Contrasts{n},'_Group_Data_Fig');
            group_name_mean=strcat(Contrasts{n},'_group_mean');
            group_name_std=strcat(Contrasts{n},'_group_std');
            makegroupFig(save_location_withSoVContrasts,file_name,file_extension,Interesting_Data_Table_Group,source_of_variations{m},Contrasts{n},group_name_mean,group_name_std,name_abb);

            %Make Indiv Figure
            file_name=strcat(strrep(source_of_variations{m},':','x'),'_',Contrasts{n},'_Subject_Data_Fig');
            makeindivFig(save_location_withSoVContrasts,file_name,file_extension,Interesting_Data_Table_Indiv,Interesting_Data_Table_Group,source_of_variations{m},Contrasts{n},group_name_mean,group_name_std,name_abb);
        end
        %Close all figures on each iteration.
        % this interferes with many aspects of matlab including the
        % profiler. Close moved into the figure creat functions.
        %close all;
    end
end

%Use Save_Interesting_Data to make summary graphics
file_name=strcat('Scalar_Summary_Sig_',pvalue_type);
summary_count_plotting(fullfile(save_location,'Summary'),file_name,file_extension,Save_Interesting_Data,source_of_variations,Contrasts);

%save Save_Interesting_Data
civm_write_table(Save_Interesting_Data, interesting_path);

end