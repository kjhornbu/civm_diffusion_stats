function [group,subgroup,test_criteria,test_remove_criteria,stats_test_scalar,stats_test_manova,plot_criteria,studymodel,compare_criteria,Summary_Criteria] = clean_up_stats_setup(configuration_struct,pairwise_criteria,pval_threshold)
%% Layout of Group and subgroup Factors
%group={'genotype','stratifier'};
%subgroup={'sex'};

GROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.GROUP);
GROUP_positional_idx=find(GROUP_logical_idx);
[valGROUP,~,idxGROUP]=unique(configuration_struct.test_criteria.GROUP(GROUP_positional_idx));

group=configuration_struct.test_criteria.Column_Names(GROUP_positional_idx(idxGROUP))';
group_random=configuration_struct.test_criteria.RANDOM(GROUP_positional_idx(idxGROUP))';
group_random_logical=~cellfun(@isempty,group_random);

for n=1:numel(group_random_logical)
    if group_random_logical(n)
        group_random_vector{n}= 'random';
    else
        group_random_vector{n}= 'fixed';
    end
end

SUBGROUP_logical_idx=~cellfun(@isempty,configuration_struct.test_criteria.SUBGROUP);
SUBGROUP_positional_idx=find(SUBGROUP_logical_idx);
[valSUBGROUP,~,idxSUBGROUP]=unique(configuration_struct.test_criteria.SUBGROUP(SUBGROUP_positional_idx));

subgroup=configuration_struct.test_criteria.Column_Names(SUBGROUP_positional_idx(idxSUBGROUP))';
subgroup_random=configuration_struct.test_criteria.RANDOM(SUBGROUP_positional_idx(idxSUBGROUP))';
subgroup_random_logical=~cellfun(@isempty,subgroup_random);

for n=1:numel(subgroup_random_logical)
    if subgroup_random_logical(n)
        subgroup_random_vector{n}= 'random';
    else
        subgroup_random_vector{n}= 'fixed';
    end
end

%% Layout of test_criteria
%in group and subgroup naming 
% test_criteria={ {'group2' ; {'group1','subgroup1'}} };
%test_criteria={{'group2';{'group1','subgroup1'}},{'group1','group2','subgroup1'}};

model_array=table2array(configuration_struct.model_table);
idx_pos = sum(model_array)>0;
matrix=double(model_array(:,idx_pos));
model_names = configuration_struct.model_table.Properties.VariableNames(idx_pos);
plot_criteria=model_names;

for n=1:size(model_array,1)
    studymodel{n}=strjoin(configuration_struct.model_table.Properties.VariableNames(model_array(n,:)),':');
end
studymodel=strjoin(studymodel,'+');

for n=1:numel(model_names)
    group_compare=strcmp(group,model_names{n});
    subgroup_compare=strcmp(subgroup,model_names{n});

    if sum(group_compare)>0 && sum(subgroup_compare)==0
        idx_pos=find(group_compare);
        model{n}=strcat('group',num2str(idx_pos));
    elseif sum(group_compare)==0 && sum(subgroup_compare)>0
        idx_pos=find(subgroup_compare);
        model{n}=strcat('subgroup',num2str(idx_pos));
    elseif (sum(subgroup_compare)== 0 && sum(group_compare)==0) ||  (sum(subgroup_compare)> 0 && sum(group_compare)>0)
        keyboard;
    end
end
%% Layout of including stratification
%hard to straify with more than 1 thing so not supporting that at this
%moment. Do some fancy work in a dataframe if that is desired. 
if strcmp(configuration_struct.stratification,'none')
    test_criteria = {model};
else
    group_compare=strcmp(group,configuration_struct.stratification);
    subgroup_compare=strcmp(subgroup,configuration_struct.stratification);

    if sum(group_compare)>0
        idx_pos=find(group_compare);
        test_criteria={strcat('group',num2str(idx_pos));{model}};
    elseif sum(subgroup_compare)>0
        idx_pos=find(subgroup_compare);
        test_criteria={strcat('subgroup',num2str(idx_pos));{model}};
    end
end

%% Layout adding in a zscoring requirement
if strcmp(configuration_struct.zscore,'none')
    test_remove_criteria={{}};
else
    group_compare=reg_match(group,strjoin(configuration_struct.zscore,'|'));
    subgroup_compare=reg_match(subgroup,strjoin(configuration_struct.zscore,'|'));

    idx_pos_g=find(group_compare);
    idx_pos_sg=find(subgroup_compare);
    if sum(group_compare)>0
        group_cells=list2cell(sprintf('group%i ',idx_pos_g));
    else
        group_cells={};
    end
    if sum(subgroup_compare)>0
        subgroup_cells=list2cell(sprintf('subgroup%i ',idx_pos_sg));
    else
        subgroup_cells={};
    end

   test_remove_criteria={[group_cells, subgroup_cells]};
end


%% Make Stats_Test Groupings
stats_test_scalar=struct;

stats_test_scalar.name=configuration_struct.scalar_name;
stats_test_scalar.effect_type_group=group_random_vector;
stats_test_scalar.group_name=group;
if ~isempty(subgroup)
    stats_test_scalar.effect_type_subgroup=subgroup_random_vector;
    stats_test_scalar.subgroup_name=subgroup;
end
stats_test_scalar.matrix{1}=matrix;
stats_test_scalar.pval_threshold=pval_threshold;

stats_test_manova=struct;
stats_test_manova.name=configuration_struct.manova_name;
stats_test_manova.effect_type_group=group_random_vector;
stats_test_manova.group_name=group;
if ~isempty(subgroup)
    stats_test_manova.effect_type_subgroup=subgroup_random_vector;
    stats_test_manova.subgroup_name=subgroup;
end
stats_test_manova.matrix{1}=matrix;
stats_test_manova.pval_threshold=pval_threshold;

%% Compare Criteria that are used to do pairwise comparisions in the datasheets
% wo regard to the source of variation
%only doing one test at a time right now

%This can't work if it is things you have not called group or subgroup! we
%should just keept it to those and then from there apply other things. Have
%a button in the script to port from one sheet to the other and just apply
%the 
source={'control','treatment'};
for o=1:numel(source)
    for n=1:height(pairwise_criteria.(source{o}))
        temp='';
        for m=1:numel(model_names)
            logical_idx=~cellfun(@isempty,regexpi(pairwise_criteria.(source{o}).Properties.VariableNames,strcat('^(',model_names{m},')$')));
            positional_idx=find(logical_idx);
            temp_data=pairwise_criteria.(source{o}){n,positional_idx};
            if strcmp(string(temp_data),"None")||strcmp(string(temp_data),"Select")
               clear temp_split
               temp_split{2}='-';
            else
                temp_split=strsplit(char(temp_data),'"');
            end
            if  m==numel(model_names)
                temp=strcat(temp,model{positional_idx},':',temp_split{2});
            else
                temp=strcat(temp,model{positional_idx},':',temp_split{2},',');
            end
        end
        compare_criteria{1}{o,n}=temp;
    end
end

%% Clean Pairwise Comparisions that are used to reduce the complexity of the summary powerpoints
%w regard to the source of variation
source={'control','treatment'};
for o=1:numel(source)
    Summary_Criteria.(source{o})=table;
    for n=1:height(pairwise_criteria.(source{o}))
        temp=pairwise_criteria.(source{o})(n,:);
        temp_varnames=pairwise_criteria.(source{o}).Properties.VariableNames;
        for m=1:width(temp)
            if strcmp(string(temp{1,m}),"None")||strcmp(string(temp{1,m}),"Select")
                temp2{m}='-';
            elseif strcmp(temp_varnames{m},'case') || strcmp(temp_varnames{m},'source_of_variation')
                temp2{m}=char(temp{1,m});
            elseif  strcmp(temp_varnames{m},'applytosummary')
                if temp{1,m}
                    temp2{m}= 1;
                else
                    temp2{m}= 0;
                end
            else
                temp_split=strsplit(char(temp{1,m}),'"');
                temp2{m}=temp_split{2};
            end
        end

        Summary_Criteria.(source{o})(n,:)=cell2table(temp2,'VariableNames',temp_varnames);
    end
    Summary_Criteria.(source{o})=Summary_Criteria.(source{o})(Summary_Criteria.(source{o}).applytosummary==1,:);
    Summary_Criteria.(source{o})=removevars(Summary_Criteria.(source{o}),'applytosummary');
    Summary_Criteria.(source{o})=column_reorder(Summary_Criteria.(source{o}),{'case','source_of_variation'});
end

end