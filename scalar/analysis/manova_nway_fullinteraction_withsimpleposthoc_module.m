function [output_fullspecification, Multi_Compare] = manova_nway_fullinteraction_withsimpleposthoc_module(data_subtable,test_criteria,stats_test)

%The posthoc does not include interaction terms!!!

output=table;
name_table=table;
Multi_Compare=table;

%Get columns of data in correct form for the analysis
data_actual_keep_list=list2cell("fa_mean ad_mean md_mean rd_mean volume_fraction");

%normalized volume too that these should be appropriately scaled to just
%put straght into the model.

data_cells=regexpi(data_subtable.Properties.VariableNames,strcat('^(',strjoin(data_actual_keep_list,'|'),')$|^(',strjoin(test_criteria,'|'),')$'));
data_idx=find(~cellfun(@isempty,data_cells)==1);


data_dependent_actual_keep_cells=regexpi(data_subtable.Properties.VariableNames,strcat('^(',strjoin(data_actual_keep_list,'|'),')$'));
data_dependent_actual_keep_idx=find(~cellfun(@isempty,data_dependent_actual_keep_cells)==1);
data_dependent_name=data_subtable.Properties.VariableNames(data_dependent_actual_keep_idx);

assert(numel(data_dependent_name)==numel(data_actual_keep_list),"The number of dependent variables in the MANOVA are incorrect. Check to Make sure you have all the contrasts you should.")

%Check for possible posthoc for non interaction cases (we can't do
%intereactions seemingly at this moment

%% individual Covaraiates 
for n=1:numel(test_criteria)
    if ischar(test_criteria{n})
        % Need to unwrap the names correctly for feeding into the system
        zscore_GROUPING=test_criteria(n);
        name_separate=strsplit(zscore_GROUPING{:},'group');
    else
        zscore_GROUPING=test_criteria{n};
        name_separate=strsplit(zscore_GROUPING,'group');
    end
    name_table.idx{n}=n;
    check_subgroup_1=(regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}));
    if ~isempty(check_subgroup_1)&&check_subgroup_1==1
        name_table.group_type{n}=stats_test.subgroup_name{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        name_table.group_type{n}=stats_test.group_name{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        name_table.group_type{n}=stats_test.group_name{1};
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end

    [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,zscore_GROUPING);

    nway_analysis_set{:,n}=group(:);
    name_table.group_separators{n}=group_name(:)';
    name_table.N{n}=sum(group_name_idx==1:size(group_name,1),1);

    %find variables that are continous which are things that aren't
    %strings/char (doubles are entries like age while "young" is a binary category)...
    %You might want to add it as an option in the stats_test on load...
    if iscell(group(1))
        name_table.continous(n)=false;
    else
        name_table.continous(n)=true;
    end

    %Set the Effect Type
    if (regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}))
        name_table.effect_type{n}=stats_test.effect_type_subgroup{str2double(name_separate{end})};

    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        name_table.effect_type{n}=stats_test.effect_type_group{str2double(name_separate{end})};

    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        name_table.effect_type{n}=stats_test.effect_type_group{1};
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end
end

length_name_nointeraction_table=size(name_table,1);

%% interaction component finder
if size(test_criteria,2)~=1
    %Full interaction setting
    for full_setting=1:size(test_criteria,2)-1
        length_name_table=size(name_table,1);
        interaction_set=nchoosek(1:size(test_criteria,2),1+full_setting);

        for n=1:size(interaction_set,1)
            test_interaction_set=test_criteria(interaction_set(n,:)); %pull the terms?
            clear temp_group_type
            for index_test_interaction=1:size(test_interaction_set,2)
                if ischar(test_interaction_set{index_test_interaction})
                    % Need to unwrap the names correctly for feeding into the system
                    zscore_GROUPING_1=test_interaction_set(index_test_interaction);
                    name_separate_1=strsplit(zscore_GROUPING_1{:},'group');

                else
                    zscore_GROUPING_1=test_interaction_set{index_test_interaction};
                    name_separate_1=strsplit(zscore_GROUPING_1,'group');
                end
                name_table.idx{length_name_table+n}=interaction_set(n,:);
                check_subgroup_1=(regexp(name_separate_1{1},'sub')==1)&(~isempty(name_separate_1{end}));
                if ~isempty(check_subgroup_1)&&check_subgroup_1==1
                    temp_group_type{index_test_interaction}=stats_test.subgroup_name{str2double(name_separate_1{end})};
                elseif (isempty(name_separate_1{1}))&(~isempty(name_separate_1{end}))
                    temp_group_type{index_test_interaction}=stats_test.group_name{str2double(name_separate_1{end})};
                elseif (isempty(name_separate_1{1}))&(isempty(name_separate_1{end}))
                    %for group 1 we have the ability to not add the 1 after wards so
                    %just pull it directly
                    temp_group_type{index_test_interaction}=stats_test.group_name{1};
                else
                    keyboard;
                    %groups are being weird you need to double check people are using the
                    %correct subgroup[0-9] and group|group[0-9] terms
                end
            end

            name_table.group_type{length_name_table+n}=strjoin(temp_group_type(:),'*'); %this will always indicate A+B+A:B which is useufl if the full iteraction is kept. 

            [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,test_interaction_set);

            name_table.group_separators{length_name_table+n}=group_name(:)';
            name_table.N{length_name_table+n}=sum(group_name_idx==1:size(group_name,1),1);

            for m=1:size(interaction_set(n,:),2)
                temp_effect_type{m}=name_table.effect_type{interaction_set(n,m)};
                temp_continous(m)=name_table.continous(interaction_set(n,m));
            end

            name_table.continous(length_name_table+n)=sum(temp_continous)>0;

            if sum(~cellfun(@isempty,regexpi(temp_effect_type,'random')))>0
                name_table.effect_type{length_name_table+n}='random';
            else
                name_table.effect_type{length_name_table+n}='fixed';
            end
        end
    end
end

%% The cross Calculation
check_interaction=regexp(name_table.group_type,'*');

for n=1:size(name_table,1)
    name_table.cross_number(n)=numel(check_interaction{n});
end

%% Do actual manova

data_subsubtable=data_subtable(:,data_idx);
manova_setup=manova(data_subsubtable,data_dependent_name,ModelSpecification=strcat(strjoin(data_dependent_name,','),"~",strjoin(test_criteria,'*')),CategoricalFactors=[test_criteria],FactorNames=[test_criteria]);
statistical_summary=manova_setup.stats;

length_output=size(output,1);

data_result=statistical_summary(1:end-2,:);

    output.Structure(length_output+(1:(size(data_result,1))))=repmat(unique(data_subtable.Structure),size(data_result,1),1);
    output.contrast(length_output+(1:(size(data_result,1))))=repmat({strjoin(data_dependent_name,',')},size(data_result,1),1);

    temp=name_table.group_type;

    output.study_model(length_output+(1:(size(data_result,1))))=repmat({strcat(strjoin(data_dependent_name,','),"~",temp(name_table.cross_number==max(name_table.cross_number)))},size(data_result,1),1);
    output.statistical_test(length_output+(1:(size(data_result,1))))={'N-Way MANOVA'};

    for n=1:size(data_result,1)
            output.source_of_variation(length_output+(n))=strrep(temp(n),'*',':'); %since we aren't truely doing interaction we are doing some super combination do underscore
            
            output.df(length_output+(n))=statistical_summary.DF(n);
            output.F_Statistic(length_output+(n))=statistical_summary.F(n);

            output.Number_of_Groupings(length_output+n)=numel(name_table.N{n});
            output.pval(length_output+n)=statistical_summary.pValue(n);
            output.eta2(length_output+n)=(output.F_Statistic(length_output+(n))*output.df(length_output+(n)))/((output.F_Statistic(length_output+(n))*output.df(length_output+(n)))+statistical_summary.DF(end-1));

            output.cohenF(length_output+n)=sqrt(output.eta2(length_output+n)/(1-output.eta2(length_output+n)));
    end

   %% WE can't do posthoc on the interactin terms in the current form of manova in matlab also don't want to look at pvalues with no chance of significance

   check_significant=output.pval(1:length_name_nointeraction_table)<stats_test.pval_threshold;
   check_number=output.Number_of_Groupings(1:length_name_nointeraction_table)>2;
   positional_idx_check_numberANDcheck_signficant=find(check_number==1 & check_significant==1);
   
   length_multicompare=size(Multi_Compare,1);

   for n=1:size(positional_idx_check_numberANDcheck_signficant)
       posthoc_summary=multcompare(manova_setup,test_criteria{positional_idx_check_numberANDcheck_signficant(n)});

        Multi_Compare.Structure(length_multicompare+(1:size(posthoc_summary,1)))=repmat(unique(data_subtable.Structure),size(posthoc_summary,1),1);
        Multi_Compare.ROI(length_multicompare+(1:size(posthoc_summary,1)))=repmat(unique(data_subtable.ROI),size(posthoc_summary,1),1);
        Multi_Compare.contrast(length_multicompare+(1:size(posthoc_summary,1)))=repmat(unique(output.contrast),size(posthoc_summary,1),1);
        Multi_Compare.source_of_variation(length_multicompare+(1:size(posthoc_summary,1)))=repmat({name_table.group_type{positional_idx_check_numberANDcheck_signficant(n)}},size(posthoc_summary,1),1);
        Multi_Compare.Inital_Study_Model(length_multicompare+(1:size(posthoc_summary,1)))=repmat({output.study_model{1}},size(posthoc_summary,1),1);
        Multi_Compare.Inital_Statistical_Test(length_multicompare+(1:size(posthoc_summary,1)))={'N-Way MANOVA'}; 
        Multi_Compare.Group_A(length_multicompare+(1:size(posthoc_summary,1)))=posthoc_summary.Group1;
        Multi_Compare.Group_B(length_multicompare+(1:size(posthoc_summary,1)))=posthoc_summary.Group2;
        Multi_Compare.Pval(length_multicompare+(1:size(posthoc_summary,1)))=posthoc_summary.pValue;

        length_multicompare=size(Multi_Compare,1);

   end

 check_rob_sheet=sum(~cellfun(@isempty,regexpi(data_subtable.Properties.VariableNames,'GN_Symbol')));

 if check_rob_sheet==1
     Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','GN_Symbol','ARA_abbrev','id64_fSABI','id32_fSABI','Structure_id','GroupCount'};
 elseif check_rob_sheet==0
     Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','Structure_id','GroupCount'};

 end

 data_grouping_regex=strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),')$');

Information_idx=regexpi(data_subtable.Properties.VariableNames,data_grouping_regex);
Information_positional_idx=~cellfun(@isempty,Information_idx);
InformationSet=unique(data_subtable(:,Information_positional_idx),'rows');

output_fullspecification=outerjoin(InformationSet,output,'MergeKeys',true);


end