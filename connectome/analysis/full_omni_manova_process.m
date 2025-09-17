function [regional_paths, global_paths] = full_omni_manova_process( ...
    dataframe_path, save_dir, group, subgroup, test_criteria, zscore_configuration, stats_test_manova, ...
    do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale)

%Determine stratificaiton
straified_dim=1;
stratified=size(test_criteria,1)==2;

%omnibus embedding
[regional_paths, global_paths, dataframe] = omnibus_embedding_prelim_processing(dataframe_path, save_dir, ...
    group, subgroup,test_criteria, zscore_configuration, ...
    do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale);

%Check that number of saved ASE terms are > the total number of terms
ase_global=civm_read_table(global_paths.ase);
ase_regional=civm_read_table(regional_paths.ase);
ase_param_count_G=numel(column_find(ase_global,'^X[0-9]+$'));
ase_param_count_R=numel(column_find(ase_regional,'^X[0-9]+$'));

dataframe=sortrows(dataframe,'CIVM_Scan_ID','ascend');

max_ase_param_count=inf;
test_idx=1;
for r=1:height(stats_test_manova.matrix{test_idx})
    criteria_idx=logical(stats_test_manova.matrix{test_idx}(r,:));
    if ~stratified
        [~,group_names,group_member_to_name_idx] = find_group_information_from_groupingcriteria(dataframe,test_criteria{test_idx}(criteria_idx));
        [group_counts, group_count_to_name_idx] = groupcounts(group_member_to_name_idx);
    else
        [~,strat_names,strat_member_to_name_idx] = find_group_information_from_groupingcriteria(dataframe,test_criteria(1));
        [~,group_names,group_member_to_name_idx] = find_group_information_from_groupingcriteria(dataframe,test_criteria{2}{test_idx}(criteria_idx)); %need to move the straatification checking of numbers up here.

        global_idx_range=1:numel(strat_names);

        for m=1:numel(group_names)
            group_select(r,m,:)=sum(strat_member_to_name_idx(group_member_to_name_idx==m)==1:numel(strat_names));
        end
        temp_group=squeeze(group_select(r,:,:));
        %remove any group that has <2 for a sampling we are working with.
        reduce_idx_to_workable_model=global_idx_range(sum(temp_group<2)==0);

        %find smallest maximal group for each delineation which will force
        %all delinations to keep the same embedding term #
        group_counts=min(max(squeeze(group_select(r,:,reduce_idx_to_workable_model))));
    end
    max_ase_param_count=min([max_ase_param_count;group_counts]);
end

[regional_paths] = switch_ase_file_on_counts(regional_paths,max_ase_param_count,ase_param_count_R);
[global_paths] = switch_ase_file_on_counts(global_paths,max_ase_param_count,ase_param_count_G);

count_G=min([max_ase_param_count,ase_param_count_R]);
count_R=min([max_ase_param_count,ase_param_count_G]);

%Then convert between both and adjust number of the ase to have. filter
%the ase and then push straified if exist through

if stratified
    %save the original_paths
    temp_global=global_paths.ase;
    temp_regional=regional_paths.ase;

    ase_global=civm_read_table(global_paths.ase);
    ase_regional=civm_read_table(regional_paths.ase);
    %We need to know the number of specimen that exist for each stratification
    %type... if only 1 or two specimen of the category cannot do manova. must have manova terms be greater than or equal to the number of parameters selected...

    %make sure ase_global is sorted the same as the data frame.
    ase_global=sortrows(ase_global,'CIVM_Scan_ID','ascend');
    ase_regional=sortrows(ase_regional,'CIVM_Scan_ID','ascend');

    [~,stratification_groups_global,group_name_idx_global] = find_group_information_from_groupingcriteria(ase_global, test_criteria(straified_dim));
    [~,stratification_groups_regional,group_name_idx_regional] = find_group_information_from_groupingcriteria(ase_regional, test_criteria(straified_dim));
    
    TotalDF=sum(group_name_idx_global==1:numel(stratification_groups_global))-1;

    count_idx=1;
    for r=1:height(stats_test_manova.matrix{test_idx})
       
        criteria_idx=logical(stats_test_manova.matrix{test_idx}(r,:));
        [~,group_names,group_member_to_name_idx] = find_group_information_from_groupingcriteria(dataframe,test_criteria{2}{test_idx}(criteria_idx));
        
        DF(r)=numel(group_names)-1;

        for m=1:numel(group_names)
            strat_select(count_idx,:)=sum(group_name_idx_global(group_member_to_name_idx==m)==1:numel(stratification_groups_global));
            count_idx=count_idx+1;
        end
    end

    global_idx_range=1:numel(stratification_groups_global);
    regional_idx_range=1:numel(stratification_groups_regional);

    %need to be sampled such that not 0 or 1 for N in a grouping we are
    %measuring AND have enough degree of freedom in the residuals so that
    %we can account for the number of ASE terms maintained. 

    global_idx_range=global_idx_range(sum(strat_select<2)==0 & (TotalDF-sum(DF))-count_G>0);
    regional_idx_range=regional_idx_range(sum(strat_select<2)==0 &(TotalDF-sum(DF))-count_R>0);

    for strat=1:numel(global_idx_range)

        [ad,an,ae]=fileparts(regional_paths.ase);
        ase_path=fullfile(ad,stratification_groups_regional{regional_idx_range(strat)});
        ase_file=fullfile(ase_path,strcat(an,ae));

        if ~exist(ase_path,'dir')
            mkdir(ase_path);
        end

        ase_regional_select=ase_regional(group_name_idx_regional==regional_idx_range(strat),:);
        writetable(ase_regional_select, ase_file);
        regional_paths.ase=ase_file;

        [ad,an,ae]=fileparts(global_paths.ase);
        ase_file=fullfile(ad,stratification_groups_global{global_idx_range(strat)},strcat(an,ae));

        if ~exist(ase_path,'dir')
            mkdir(ase_path);
        end

        ase_global_select=ase_global(group_name_idx_global==global_idx_range(strat),:);
        writetable(ase_global_select, ase_file);
        global_paths.ase=ase_file;

        [regional_paths,global_paths] = run_manova_in_R(ase_path,group, subgroup,test_criteria{2}, stats_test_manova,regional_paths,global_paths,stratification_groups_global{global_idx_range(strat)});

        regional_paths.ase=temp_regional;
        global_paths.ase=temp_global;
    end
else
    [regional_paths,global_paths] = run_manova_in_R(save_dir,group, subgroup,test_criteria, stats_test_manova,regional_paths,global_paths,'');
end

end