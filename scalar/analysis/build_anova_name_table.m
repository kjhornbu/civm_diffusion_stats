function [name_table,length_name_nointeraction_table,nway_analysis_set]=build_anova_name_table(data_subtable,test_condition,stats_test)

name_table=table;
%% individual Covaraiates 
for n=1:numel(test_condition)
    if ischar(test_condition{n})
        % Need to unwrap the names correctly for feeding into the system
        TEST_CONDITION=test_condition(n);
        name_separate=strsplit(TEST_CONDITION{:},'group');
    else
        TEST_CONDITION=test_condition{n};
        name_separate=strsplit(TEST_CONDITION,'group');
    end
    name_table.idx{n}=n;
    name_table.matrix{n}=zeros(1,numel(test_condition));
    name_table.matrix{n}(n)=1;

    check_subgroup_1=(regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}));
    if ~isempty(check_subgroup_1)&&check_subgroup_1==1
        name_table.group_type{n}=stats_test.subgroup_name{str2double(name_separate{end})};
        if strcmp(stats_test.effect_type_subgroup{str2double(name_separate{end})},'random')
            name_table.random(n)=true;
        else
            name_table.random(n)=false;
        end

        if strcmp(stats_test.variable_type_subgroup{str2double(name_separate{end})},'discrete')
            name_table.continous(n)=false;
        else
            name_table.continous(n)=true;
        end

    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        name_table.group_type{n}=stats_test.group_name{str2double(name_separate{end})};
        if strcmp(stats_test.effect_type_group{str2double(name_separate{end})},'random')
            name_table.random(n)=true;
        else
            name_table.random(n)=false;
        end

        if strcmp(stats_test.variable_type_group{str2double(name_separate{end})},'discrete')
            name_table.continous(n)=false;
        else
            name_table.continous(n)=true;
        end
    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        name_table.group_type{n}=stats_test.group_name{1};
        if strcmp(stats_test.effect_type_group{1},'random')
            name_table.random(n)=true;
        else
            name_table.random(n)=false;
        end

        if strcmp(stats_test.variable_type_group{1},'discrete')
            name_table.continous(n)=false;
        else
            name_table.continous(n)=true;
        end

    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end

    [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,TEST_CONDITION);

    nway_analysis_set{:,n}=group(:);
    name_table.group_separators{n}=group_name(:)';
    name_table.N{n}=sum(group_name_idx==1:size(group_name,1),1);

end

length_name_nointeraction_table=size(name_table,1);

%% interaction component finder
if size(test_condition,2)~=1
    %Full interaction setting
    for full_setting=1:size(test_condition,2)-1
        length_name_table=size(name_table,1);
        interaction_set=nchoosek(1:size(test_condition,2),1+full_setting);

        for n=1:size(interaction_set,1)
            test_interaction_set=test_condition(interaction_set(n,:)); %pull the terms?

            clear temp_group_type
            for index_test_interaction=1:size(test_interaction_set,2)
                if ischar(test_interaction_set{index_test_interaction})
                    % Need to unwrap the names correctly for feeding into the system
                    TEST_CONDITION_1=test_interaction_set(index_test_interaction);
                    name_separate_1=strsplit(TEST_CONDITION_1{:},'group');
                else
                    TEST_CONDITION_1=test_interaction_set{index_test_interaction};
                    name_separate_1=strsplit(TEST_CONDITION_1,'group');
                end

                name_table.idx{length_name_table+n}=interaction_set(n,:);
                name_table.matrix{length_name_table+n}=zeros(1,numel(test_condition));
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

            name_table.group_type{length_name_table+n}=strjoin(temp_group_type(:),'*'); %this will always indicate A+B+A:B which is usefull if the full iteraction is kept. 
            
            % slow line (20s,19.5s), Can this be cached?
            [group,group_name,group_name_idx]=find_group_information_from_groupingcriteria(data_subtable,test_interaction_set);

            name_table.group_separators{length_name_table+n}=group_name(:)';
            name_table.N{length_name_table+n}=sum(group_name_idx==1:size(group_name,1),1);

            for m=1:size(interaction_set(n,:),2)
                temp_effect_type(m)=name_table.random(interaction_set(n,m));
                temp_continous(m)=name_table.continous(interaction_set(n,m));
            end

            name_table.random(length_name_table+n)=sum(temp_effect_type)>0;
            name_table.continous(length_name_table+n)=sum(temp_continous)>0;
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