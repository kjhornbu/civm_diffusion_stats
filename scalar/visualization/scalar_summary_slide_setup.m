function [slidepointer] = scalar_summary_slide_setup(ppt,figure_dir,Interesting_Data,Group_Table,control_setting,noncontrol_setting)

cohenF_Threshold=0.4;

import mlreportgen.ppt.*;

[contrast,~,contrast_idx]=unique(Interesting_Data.contrast);
[source_of_variation,~,source_of_variation_idx]=unique(Interesting_Data.source_of_variation);

Group_Table_VariableNames=Group_Table.Properties.VariableNames;

[control_setting_VariableNames,~] = select_setting_terms(control_setting);
[noncontrol_setting_VariableNames,start_idx] = select_setting_terms(noncontrol_setting);

%% Check if we have any interesting comparisions at all
%We look at the comparisons we list for key sources of variations and compare
%it to the interesting data sheet to see if any remain when I consider the sheet.
%This is different than the outside check which looks for if the Interesting table
% is a literal empty where as this is looking at says is the comparisons I care most about literally empty.

counter = 0; 
[unique_sources_inControlSheet,~,~]=unique(control_setting.source_of_variation);
for keyGroupings=1:numel(unique_sources_inControlSheet)
    logicalKeyGrouping_idx=~cellfun(@isempty,regexpi(source_of_variation,unique_sources_inControlSheet{keyGroupings}));
    if sum(logicalKeyGrouping_idx)==0

        %If we can't find in the interesting comparisions the key groupings for the sheet
        %we will just iterate a counter

        counter = counter +1;
    end
end

%if all the sources of variation that are key groupings are missing then
%indicate that.
if counter == numel(unique_sources_inControlSheet)
    %Make "Blank Filler Slide for the Key Groupings"
    slidepointer = add(ppt,'Title Slide');
    replace(slidepointer,'Title',strcat('No Significant Results for Key Groupings in',32,strjoin(unique_sources_inControlSheet,', '),32,'as Defined'));
    return;
end

%% Data Slide Setup
%we look through all the sources of variations in the interesting rather
%than in the key comparisions.

for source=1:numel(source_of_variation)
    control_idx=~cellfun(@isempty,regexpi(control_setting.source_of_variation,strcat('^(',source_of_variation(source),')$')));
    noncontrol_idx=~cellfun(@isempty,regexpi(noncontrol_setting.source_of_variation,strcat('^(',source_of_variation(source),')$')));

    control_positional_idx=find(control_idx==1);

    temp_control=control_setting(control_idx,start_idx:end);
    temp_noncontrol=noncontrol_setting(noncontrol_idx,start_idx:end);

    if and(isempty(temp_control),isempty(temp_noncontrol))
        continue;
    end

    clear control_idx_inGroupTable noncontrol_idx_inGroupTable;

    for pairs_in_group = 1:size(temp_control,1)

        %if we didn't give a cute name then use a standard name
        if sum(~cellfun(@isempty,regexpi(noncontrol_setting.Properties.VariableNames,'^(case)$')))
            group_name_full{pairs_in_group}=control_setting.case{control_positional_idx(pairs_in_group)};
        else
            group_name_control{pairs_in_group}=strjoin(table2array(temp_control(pairs_in_group,:)),' ');
            group_name_noncontrol{pairs_in_group}=strjoin(table2array(temp_noncontrol(pairs_in_group,:)),' ');
            group_name_full{pairs_in_group}=strcat(group_name_control{pairs_in_group},32,'versus',32,group_name_noncontrol{pairs_in_group});
        end

        for group_n=1:numel(control_setting_VariableNames)
            control_idx_inGroupTable{pairs_in_group}(:,group_n)=~cellfun(@isempty,regexpi(Group_Table.(control_setting_VariableNames{group_n}),strcat('^(',temp_control.(control_setting_VariableNames{group_n}){pairs_in_group},')$')));
        end
        control_idx_inGroupTable{pairs_in_group}=sum(control_idx_inGroupTable{pairs_in_group},2)==numel(control_setting_VariableNames);

        for group_n=1:numel(noncontrol_setting_VariableNames)
            noncontrol_idx_inGroupTable{pairs_in_group}(:,group_n)=~cellfun(@isempty,regexpi(Group_Table.(noncontrol_setting_VariableNames{group_n}),strcat('^(',temp_noncontrol.(noncontrol_setting_VariableNames{group_n}){pairs_in_group},')$')));
        end
        noncontrol_idx_inGroupTable{pairs_in_group}=sum(noncontrol_idx_inGroupTable{pairs_in_group},2)==numel(noncontrol_setting_VariableNames);
    end

    for con=1:numel(contrast)
        Interesting_Data_Lookup_idx=and(contrast_idx==con,source_of_variation_idx==source);
        Interesting_Data_Lookup_positional_idx=find(Interesting_Data_Lookup_idx==1);

        if  ~isempty(Interesting_Data_Lookup_positional_idx)
            %% Add Title to Slide
            slidepointer = add(ppt,"Scalar_Analysis");
            slide_title=['Summary:',' ',contrast{con},' ',source_of_variation{source}];
            replace(slidepointer,"Title",slide_title);

            %% Configure groupings to work from for the Given Contrast
            ROI_numbers=Interesting_Data.ROI(Interesting_Data_Lookup_idx);
            ROI_number_idx=Group_Table.ROI==ROI_numbers';
            data_idx=~cellfun(@isempty,regexpi(Group_Table_VariableNames,strcat('^(',contrast{con},'_group_mean)$')));

            increase_decrease_setting=zeros( numel(control_idx_inGroupTable),size(ROI_number_idx,2));
            for pairs_in_group = 1: numel(control_idx_inGroupTable)
                for roi_list=1:size(ROI_number_idx,2)
                    control_value=Group_Table.(Group_Table_VariableNames{data_idx})(and(ROI_number_idx(:,roi_list),control_idx_inGroupTable{pairs_in_group}));
                    treated_value=Group_Table.(Group_Table_VariableNames{data_idx})(and(ROI_number_idx(:,roi_list),noncontrol_idx_inGroupTable{pairs_in_group}));

                    if (treated_value-control_value)<0
                        increase_decrease_setting(pairs_in_group,roi_list)=-1;
                    elseif (treated_value-control_value)>0
                        increase_decrease_setting(pairs_in_group,roi_list)=1;
                    end
                end
            end

            %% Create summary table of Configured Groupings
            increasing_idx=increase_decrease_setting==1;
            decreasing_idx=increase_decrease_setting==-1;

            summary_table=table;
            summary_table.('Summary Counts'){1}='N';
            summary_table.('Summary Counts'){2}='+';
            summary_table.('Summary Counts'){3}='-';

            summary_table.('All')(1)=sum(Interesting_Data_Lookup_idx);
            summary_table.('All')(2)=sum(sum(increasing_idx,1)>0,'all');
            summary_table.('All')(3)=sum(sum(decreasing_idx,1)>0,'all');

            summary_table.('Large Effects')(1)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_idx)>cohenF_Threshold);
            summary_table.('Large Effects')(2)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_positional_idx(sum(increasing_idx,1)>0))>cohenF_Threshold);
            summary_table.('Large Effects')(3)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_positional_idx(sum(decreasing_idx,1)>0))>cohenF_Threshold);

            if size(increasing_idx,1)>1
                for n=1:size(increasing_idx,1)
                    summary_table.(group_name_full{n})(1)=sum(Interesting_Data_Lookup_idx);
                    summary_table.(group_name_full{n})(2)=sum(increasing_idx(n,:),'all');
                    summary_table.(group_name_full{n})(3)=sum(decreasing_idx(n,:),'all');

                    summary_table.(strcat('Large Effects',32,group_name_full{n}))(1)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_idx)>cohenF_Threshold);
                    summary_table.(strcat('Large Effects',32,group_name_full{n}))(2)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_positional_idx(increasing_idx(n,:)))>cohenF_Threshold);
                    summary_table.(strcat('Large Effects',32,group_name_full{n}))(3)=sum(Interesting_Data.cohenF(Interesting_Data_Lookup_positional_idx(decreasing_idx(n,:)))>cohenF_Threshold);
                end
            end

            replace(slidepointer,"Table",Table(summary_table));

            %% Create Top Increase/Decrease Region Content
            increasing_table=Interesting_Data(Interesting_Data_Lookup_positional_idx(sum(increasing_idx,1)>0),:);
            increasing_table=sortrows(increasing_table,'cohenF','descend');

            decreasing_table=Interesting_Data(Interesting_Data_Lookup_positional_idx(sum(decreasing_idx,1)>0),:);
            decreasing_table=sortrows(decreasing_table,'cohenF','descend');

            % Assign capping of regions notice
            clear Full_Content;
            if  (height(increasing_table)>10) || (height(decreasing_table)>10)
                Full_Content=Paragraph('Abbreviations listed have been capped at a maximum of 10 per direction');
                Full_Content.Style = {Bold(false)};
            end

            %list Increasing regions
            clear Full_Content_I;
            Full_Content_I = Paragraph('Increasing: ');
            Full_Content_I.Style = {Bold(false)};

            [Full_Content_I] = Increase_Decrease_Text(Full_Content_I,increasing_table,cohenF_Threshold);

            %list decreasing regions
            clear Full_Content_D;
            Full_Content_D = Paragraph('Decreasing: ');
            Full_Content_D.Style = {Bold(false)};

            [Full_Content_D] = Increase_Decrease_Text(Full_Content_D,decreasing_table,cohenF_Threshold);

            if exist('Full_Content','var')
                replace(slidepointer,'Content',{Full_Content,Full_Content_I,Full_Content_D});
            else
                replace(slidepointer,'Content',{Full_Content_I,Full_Content_D});
            end

            %% Add Figure
            picture = Picture(fullfile(figure_dir,strrep(source_of_variation{source},':','x'),contrast{con},'png',strcat(strrep(source_of_variation{source},':','x'),'_',contrast{con},'_Subject_Data_Fig.png')));
            replace(slidepointer,"Picture",picture);
        end
    end
end
end