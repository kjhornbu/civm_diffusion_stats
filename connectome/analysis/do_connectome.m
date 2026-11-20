function [opts] = do_connectome(opts)
%% Omni Manova Analysis
if sum(reg_match(opts.analysisPipelineType,'^(Connectome)$'))==0
    return;
else
    %getting memory information for the test
    try
        A=memory;
        number_of_leafs=360;
        single_array_data_sizeByte=8;
        double_array_data_sizeByte=single_array_data_sizeByte^2;
        max_specimen=sqrt(A.MaxPossibleArrayBytes/double_array_data_sizeByte)/number_of_leafs;
        max_specimen=floor(max_specimen);
    catch
        max_specimen=300; % my person mac is like 250
        number_of_leafs=360;
        single_array_data_sizeByte=8;
        double_array_data_sizeByte=single_array_data_sizeByte^2;
        A.MaxPossibleArrayBytes=double_array_data_sizeByte*(max_specimen*number_of_leafs)^2;
    end

    %% MAKE THIS THE CONNECTOME FOLDER and setup subfoldering as needed

    if ~exist(fullfile( opts.statSaveDir,'Connectomics'),'dir')
        mkdir(fullfile( opts.statSaveDir,'Connectomics'))
    end

    check_names=fieldnames(opts.statistical_model.stats_test_connectome);
    idx_subgroup=~cellfun(@isempty,regexpi(check_names,'^(subgroup_name)$'));
    positional_idx_subgroup=find(idx_subgroup);

    if ~isempty(positional_idx_subgroup)
        name_augment=strcat(strjoin(strrep(opts.statistical_model.stats_test_connectome.group_name,'_',''),'_'),'_',strjoin(strrep(opts.statistical_model.stats_test_connectome.subgroup_name,'_',''),'_'));
    else
        name_augment=strcat(strjoin(strrep(opts.statistical_model.stats_test_connectome.group_name,'_',''),'_'));
    end

    if strcmp(opts.statistical_model.stats_test_connectome.name,'omnimanova_defined_matrix')
        temp_testname=strsplit(opts.statistical_model.stats_test_connectome.name,'_');
        temp_turned_matrix=opts.statistical_model.stats_test_connectome.matrix{:}';
        temp_matrix_numbercode=strrep(char(num2str(temp_turned_matrix(:)))',' ', '');

        if ~exist(fullfile( opts.statSaveDir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode)),'dir')
            mkdir(fullfile( opts.statSaveDir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode)));
        end

        save_cnt=fullfile( opts.statSaveDir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode),name_augment);
    else
        if ~exist(fullfile( opts.statSaveDir,'Connectomics',opts.statistical_model.stats_test_connectome.name),'dir')
            mkdir(fullfile( opts.statSaveDir,'Connectomics',opts.statistical_model.stats_test_connectome.name));
        end
        save_cnt=fullfile( opts.statSaveDir,'Connectomics',opts.statistical_model.stats_test_connectome.name,name_augment);
    end

    t_start=tic;
    Paths_Pval=struct;
    %% All specimen OmniManova
    for n=1:numel(opts.connectome_outputs)
        dataframe=civm_read_table(opts.dataframePath);

        if height(dataframe)> max_specimen
            error('Too many specimen in study to complete omni-manova on this system. Max Specimen # for system is %d.',max_specimen);
        end

        dataframe=column2text(dataframe,{opts.statistical_model.group,opts.statistical_model.subgroup});
        Paths_Pval.(opts.connectome_outputs{n})=table;
        o_dir=fullfile(save_cnt,opts.connectome_outputs{n});

        if ~exist(o_dir,'dir')
            mkdir(o_dir);
        end

        if ~isempty(column_find(dataframe,'^(scale)$'))
            find_scale=0;
        else
            find_scale=1;
        end

        set_scale=n-1;
        [regional_paths,global_paths]=full_omni_manova_process(opts.dataframePath,o_dir,opts.statistical_model.group, opts.statistical_model.subgroup,opts.statistical_model.model_layout,opts.statistical_model.test_remove_criteria,opts.statistical_model.stats_test_connectome,opts.connectome_set_do_binarize, opts.connectome_set_do_mean_subtract, opts.connectome_set_do_ptr, opts.connectome_set_do_augment, find_scale, set_scale,opts.pvalThreshold);

        %placed back inside the full_omni_manova process -- to allow
        %for stratification summarizing
        % global_interesting_results(o_dir,global_paths.pval,opts.pvalThreshold); % These are doing the summary plottign here
        % regional_interesting_results(o_dir,regional_paths.pval,opts.pvalThreshold); % These are doing the summary plottign here

        % Need to figure out how this is done for the scalar data...

        Paths_Pval.(opts.connectome_outputs{n}).name{1}='All';
        Paths_Pval.(opts.connectome_outputs{n}).regional{1}=regional_paths.pval;
        Paths_Pval.(opts.connectome_outputs{n}).global{1}=global_paths.pval;
    end

    t_omni=toc(t_start);
    % have some sort of check of the memory requirements so that it won't
    % push too hard. (like if number of specimen >

    %% Then do the one remove testing of Omni Manova
    remove1_dataframe=civm_read_table(opts.dataframePath);
    remove1_dataframe=column2text(remove1_dataframe,{opts.statistical_model.group,opts.statistical_model.subgroup});
    fulldataFrame=remove1_dataframe;

    num_specimen=height(remove1_dataframe);

    total_est_time_1rm=t_omni*num_specimen;
    total_est_time_1rm=total_est_time_1rm/60;
    if total_est_time_1rm > 10
        warning('The estimated time to complete all of one remove testing is %2.2f minutes!!', total_est_time_1rm);
    end

    %max_array_size -- use pval because bigger.
    %max_data_size=520 + sum(pval_check.pval < opts.pvalThreshold)*num_specimen*8;
    dataLimit=(A.MaxPossibleArrayBytes/double_array_data_sizeByte)-((number_of_leafs*num_specimen)^2)*num_specimen; %only works in windows machines
    max_1rm=((A.MaxPossibleArrayBytes/double_array_data_sizeByte)/(number_of_leafs)^2)^(1/3);
    %approx_specimenspace_remaining=max_specimen-2*(num_specimen+(num_specimen-1)^2); %total specimen possible based on memory - (2x because scaled/unscale) (specimen in inital omni  + all the one remove at the same time (so just )^2)
    %its really related to how many entries need to keep to hold the data...
    %which is more related to how many significant terms are we keeping

    oneRM_done=0;

    %Check groupings for n in them if <2 then cannot actually do 1-remove
    %testing without breaking the test.

    use_subgroup=isfield(opts.statistical_model.stats_test_connectome,'subgroup_name');
    use_group=isfield(opts.statistical_model.stats_test_connectome,'group_name');
    if use_group==1
        if use_subgroup==1
            grouping_names=[opts.statistical_model.stats_test_connectome.group_name,opts.statistical_model.stats_test_connectome.subgroup_name];
        else
            grouping_names=[opts.statistical_model.stats_test_connectome.group_name];
        end
    else
        warning('No Groups with Names defined, you need at least one!')
    end
    grouping_models=opts.statistical_model.stats_test_connectome.matrix{1};

    group_keeper=zeros(height(grouping_models),1);
    for n=1:height(grouping_models)
        select_group=grouping_names(logical(grouping_models(n,:)));
        [~,unique_groups,group_idxs]=find_group_information_from_groupingcriteria(dataframe,select_group);
        group_keeper(n)=any(sum(group_idxs==1:numel(unique_groups))<=2);
    end

    if any(group_keeper)
        warning('Not completing 1-Remove Testing, group sizes are too small!\n');
    else
        if dataLimit>0
            % ParFor for One remove testing
            if ~file_time_check(fullfile(save_cnt,'Pval_Paths.mat'),'newer',opts.dataframePath)
                t_start_remove=tic;
                for n=1:numel(opts.connectome_outputs)
                    newDF_dir=fullfile(save_cnt,opts.connectome_outputs{n},'OneRemoveDataFrames');
                    if ~exist(newDF_dir,'dir')
                        mkdir(newDF_dir);
                    end
                    %setup parameters
                    for s=1:num_specimen
                        removed_specimen{s}=remove1_dataframe.CIVM_Scan_ID{s};
                        remove1_dataframe(s,:)=[];
                        updated_dataframe_path=fullfile(newDF_dir, strcat(removed_specimen{s},'_removed_DataFrame.txt'));
                        writetable(remove1_dataframe, updated_dataframe_path,'Delimiter', '\t'); %added  tab deliminator

                        o_dir=fullfile(save_cnt,opts.connectome_outputs{n},'OneRemoveTesting',strcat(removed_specimen{s},'_removed'));
                        if ~exist(o_dir,'dir')
                            mkdir(o_dir);
                        end
                        if ~isempty(column_find(remove1_dataframe,'^(scale)$'))
                            find_scale=0;
                        else
                            find_scale=n-1;
                        end
                        set_scale=n-1;
                        param_list_1_rm{s}={updated_dataframe_path,o_dir,opts.statistical_model.group,opts.statistical_model.subgroup,opts.statistical_model.model_layout,opts.statistical_model.test_remove_criteria,opts.statistical_model.stats_test_connectome,opts.connectome_set_do_binarize, opts.connectome_set_do_mean_subtract, opts.connectome_set_do_ptr, opts.connectome_set_do_augment, find_scale, set_scale,opts.pvalThreshold};
                        remove1_dataframe=fulldataFrame;
                    end

                    % actual run omnimanova process for 1 remove
                    %We keep having problems where with a character parsing
                    %the error in question
                    %{
                Error using civm_diffusion_stats/parfor%consume_1
Conversion to char from cell is not possible.

Error in civm_diffusion_stats (line 662)
                parfor s=1:num_specimen

Error in example_run_stat_pipeline_205xFAD01_KH_QA_20260408_AllTogether (line 37)
civm_diffusion_stats(studyParams{:});
                    %}

                    parfor s=1:num_specimen

                        [regional_paths,global_paths]=full_omni_manova_process(param_list_1_rm{s}{:});

                        name{s}=strcat('No_',removed_specimen{s});
                        regional_path{s}=regional_paths.pval;
                        global_path{s}=global_paths.pval;
                    end

                    try
                        Paths_Pval.(opts.connectome_outputs{n}).name((1:numel(name))+1)=name;
                        Paths_Pval.(opts.connectome_outputs{n}).regional((1:numel(name))+1)=regional_path;
                        Paths_Pval.(opts.connectome_outputs{n}).global((1:numel(name))+1)=global_path;
                    catch
                        disp(n)
                        keyboard;
                    end
                end
                t_oneremove=toc(t_start_remove);
                fprintf('One remove actually took, %g minutes estimate was %g minutes\n',t_oneremove/60,total_est_time_1rm);

                save(fullfile(save_cnt,'Pval_Paths.mat'),'Paths_Pval')
                try
                    [Sig_Among_1RM_global_paths] = global_one_remove_compile(save_cnt,opts.connectome_outputs,Paths_Pval,opts.pvalThreshold);
                    [Sig_Among_1RM_regional_paths] = regional_one_remove_compile(save_cnt,opts.connectome_outputs,Paths_Pval,opts.pvalThreshold);
                catch
                    keyboard;
                end
                global_one_remove_plot(save_cnt,dataframe,Sig_Among_1RM_global_paths);
                for n=1:numel(Sig_Among_1RM_regional_paths)
                    regional_one_remove_plot(save_cnt,dataframe,Sig_Among_1RM_regional_paths{n});
                end
            end

            oneRM_done=1;
        else
            fprintf('Not Doing 1 Remove Testing of Omni-Manova -- Too many specimen to do analysis (Have %d, Can Only Do %d)\n',num_specimen,floor(max_1rm));
        end
    end
    %% TO DO: Put complex figure generation here for Connectomes
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    %This should be at least the blue figures for the key stuff maybe MDS
    %plots?

    %% TO DO: Summary PPt for Connectomes

    %generate_summary_ppts_manova(save_cnt,Paths_Pval,studyID,user,opts.connectome_outputs,opts.pvalThreshold,studymodel,configuration_struct)

    opts.Connectome_Sheet_Path_csv=fullfile(save_cnt,'Pval_Paths.mat');
end

end