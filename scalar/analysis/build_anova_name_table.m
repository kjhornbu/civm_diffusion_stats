function [name_table,length_name_nointeraction_table,nway_analysis_set]=build_anova_name_table(data_subtable,zscore_grouping,stats_test)
name_table=table;
%% individual Covaraiates 
for n=1:numel(zscore_grouping)
    if ischar(zscore_grouping{n})
        % Need to unwrap the names correctly for feeding into the system
        zscore_GROUPING=zscore_grouping(n);
        name_separate=strsplit(zscore_GROUPING{:},'group');
    else
        zscore_GROUPING=zscore_grouping{n};
        name_separate=strsplit(zscore_GROUPING,'group');
    end
    name_table.idx{n}=n;
    name_table.matrix{n}=zeros(1,numel(zscore_grouping));
    name_table.matrix{n}(n)=1;

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
if size(zscore_grouping,2)~=1
    %Full interaction setting
    for full_setting=1:size(zscore_grouping,2)-1
        length_name_table=size(name_table,1);
        interaction_set=nchoosek(1:size(zscore_grouping,2),1+full_setting);

        for n=1:size(interaction_set,1)
            test_interaction_set=zscore_grouping(interaction_set(n,:)); %pull the terms?
            % slow line (6.5s), do we need to clear this?
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
                % slow line (12.4s), can we preallocate this?
                name_table.idx{length_name_table+n}=interaction_set(n,:);
                name_table.matrix{length_name_table+n}=zeros(1,numel(zscore_grouping));
                name_table.matrix{length_name_table+n}(interaction_set(n,:))=1;

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
            
            % slow line (20s,19.5s), Can this be cached?
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
% counts the occurance of the given character to know how many interactions
% are present in each one.
check_interaction=regexp(name_table.group_type,'*');
for n=1:size(name_table,1)
    name_table.cross_number(n)=numel(check_interaction{n});
end


end