function [ ] = civm_diffusion_stats(user, studyID, google_doc, cleaned_google_doc_path,...
    dataframe_path, setup_file, polished_sheets, project_research_archive, atlas_ontology_path, pval_cols, pval_threshold, save_dir,which_tests,optional_suffix,suffix)
% Expected that google_doc is a file which civm_read_table will load
% will save updated copy to cleaned_google_doc_path
% from cleaned googledoc, will build and save dataframe sheet to dataframe.
% scans which are accepted into datframe are polished into polished_sheets
% project_research_archive is the search location for connectome dirs
%    (alternative name connecome_search_dir?)
% atlas_ontology_path is path to a lookup table. (in the future is should
% be optional. Alternative name "substitute_lookup_table"? )
% pval_cols are the pvalue columns we're testing ...?
% pval_theshold is our significance threshold.
% save dir is where our bulk stat processing will be saved. Internally
% save_dir will be separated for scalar_and_volume and connectomics.
%
% maybe we should re-arrange the function args to sorted by "inputs in order used
% or simplicity", "outputs in order used or simplicity".
% user, google_doc, project_research_archive, atlas_ontolgoy_path,
% pval_cols, pval_threshold, save_dir, cleaned_google_doc_path,
% dataframe_path

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end
output_paths=fullfile(save_dir,'Scalar_Data_Sheet_Paths.csv');

%% Data setup -- User Input form
keep_last_dataframe = 0;
if exist(dataframe_path,'file')
    [keep_last_dataframe] = do_dataframe_ui(dataframe_path);
    if ~keep_last_dataframe
        [path,name,extension]=fileparts(dataframe_path);
        info=dir(dataframe_path);
        idate=datetime(info.date);
        idate.Format='yyyy-MM-dd''T''HHmm';
        old_file_path=fullfile(path,sprintf('%s_%s%s',name,char(idate),extension));
        movefile(dataframe_path,old_file_path)
    end
end
if ~keep_last_dataframe
    %Do standard metadata cleanup
    extendedStudyColumns={};
    cloud_notebook=civm_read_table(google_doc);
    cloud_notebook=column2text(cloud_notebook,cloud_notebook.Properties.VariableNames);

    cloud_notebook = civm_metadata_cleanup(cloud_notebook,extendedStudyColumns);
    %do visualization to do final cleanup of cloudnotebook
    cloudnotebook_table_ui(cloud_notebook,cleaned_google_doc_path);
    % take cloudnotebook and convert into a dataframe
    cloudnotebook_to_dataframe('CIVM_Scan_ID',cleaned_google_doc_path,atlas_ontology_path,polished_sheets,dataframe_path,project_research_archive,optional_suffix,suffix)
end

%% Stats Setup
% set a setup.mat path where we can save the configuration data, to let
% people skip it next time.
if isempty(setup_file)
    [~,n,~]=fileparts(dataframe_path);
    setup_file=fullfile(save_dir,sprintf('%s_setup.mat',n));
end
clear n;
% check thing exists -- intialize to do it.
keep_last_setup=0;
if exist(setup_file,'file')
    % prompt for keeping configuration (1 == keep)
    keep_last_setup=do_configuration_ui(setup_file);

    if ~keep_last_setup
        % when NOT keeping, rename the previous to contain its save date so
        % we can tell what we ran and when.
        info=dir(setup_file);
        [p,n,~]=fileparts(setup_file);
        idate=datetime(info.date);
        idate.Format='yyyy-MM-dd''T''HHmm';
        old_file=fullfile(p,sprintf('%s_setup_%s.mat',n,char(idate)));
        movefile(setup_file,old_file)
        clear info idate old_file;
    end
end
clear p n;

if ~keep_last_setup
    configuration_table=stats_configuration_ui(dataframe_path);
    configuration_struct=assignmodelmatrix_ui(configuration_table);
    [pairwise_criteria]=pairwise_compare_ui_apply2summary(configuration_struct,dataframe_path);

    %save pairwise_criteria, configuration struct
    save(setup_file,'pairwise_criteria','configuration_struct','-mat');
else
    % load pairwise_criteria, configuration struct
    %setup_mat=matfile(setup_file);
    load(setup_file,'pairwise_criteria','configuration_struct');
end

[group, subgroup, test_criteria, test_remove_criteria, stats_test_scalar, stats_test_manova, plot_criteria, studymodel, compare_criteria, Summary_Criteria] = ...
    clean_up_stats_setup(configuration_struct, pairwise_criteria,pval_threshold);

%% Scalar Analysis
dataframe=civm_read_table(dataframe_path);
dataframe=column2text(dataframe,{group,subgroup});

if sum(reg_match(which_tests,'^(Scalar)$'))>0

    if ~exist(fullfile(save_dir,'Scalar_and_Volume'),'dir')
        mkdir(fullfile(save_dir,'Scalar_and_Volume'))
    end

    check_names=fieldnames(stats_test_scalar);
    idx_subgroup=~cellfun(@isempty,regexpi(check_names,'^(subgroup_name)$'));
    positional_idx_subgroup=find(idx_subgroup);

    if ~isempty(positional_idx_subgroup)
        name_augment=strcat(strjoin(strrep(stats_test_scalar.group_name,'_',''),'_'),'_',strjoin(strrep(stats_test_scalar.subgroup_name,'_',''),'_'));
    else
        name_augment=strcat(strjoin(strrep(stats_test_scalar.group_name,'_',''),'_'));
    end

    if strcmp(stats_test_scalar.name,'anovan_defined_matrix')
        temp_testname=strsplit(stats_test_scalar.name,'_');
        temp_turned_matrix=stats_test_scalar.matrix{:}';
        temp_matrix_numbercode=strrep(char(num2str(temp_turned_matrix(:)))',' ', '');

        if ~exist(fullfile(save_dir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode)),'dir')
            mkdir(fullfile(save_dir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode)));
        end

        save_scalar=fullfile(save_dir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode),name_augment);
    else
        if ~exist(fullfile(save_dir,'Scalar_and_Volume',stats_test_scalar.name),'dir')
            mkdir(fullfile(save_dir,'Scalar_and_Volume',stats_test_scalar.name));
        end
        save_scalar=fullfile(save_dir,'Scalar_and_Volume',stats_test_scalar.name,name_augment);
    end

    if ~exist(save_scalar,'dir')
        mkdir(save_scalar);
    end

    if ~file_time_check(output_paths, 'newer', setup_file)
        output_paths_table=scalar_processing_main(dataframe,save_scalar,group,subgroup,test_criteria,test_remove_criteria,stats_test_scalar);

        %save output path tables to a location
        output_paths_table.hemisphere=cell2mat(output_paths_table.hemisphere);
        civm_write_table(output_paths_table,output_paths);
    else
        output_paths_table=civm_read_table(output_paths);
    end

    %% Scalar Analysis Post Processing
    plotting_sheet_types={'Non_Erode'};
    plotting_hemispheres=[0];

    % limit the plotted data-sets according to limit vars set at beginning.
    % (james likes to only plot bilateral non-erode to save some time)
    px=sprintf('^%s$',strjoin(plotting_sheet_types,'|'));
    st_idx=row_find(output_paths_table,'voxel_wise',px,1);
    h_idx=any( row_find(output_paths_table,'hemisphere',plotting_hemispheres,1), 2);
    limited_output_paths_table=output_paths_table(st_idx&h_idx,:);
    output_paths_table=limited_output_paths_table;

    % sort by subject,group,stats for efficiency of plotting
    strat_specific_cols=list2cell('SubjectTable GroupTable StatsResults Posthoc');
    output_paths_table=sortrows(output_paths_table,['SubjectTable' strat_specific_cols]);

    %% create Basic Advanced Figures
    for pt=pval_cols
        pvalue_type=pt{1};
        % need to assign to temp to prevent handling pval different from pval_BH
        Generate_PairwiseSheet_Plotting( output_paths_table, compare_criteria, pvalue_type, pval_threshold, {plot_criteria}); %output_paths_with_compare=
    end
    %output_paths_table=output_paths_with_compare;
    %% TO DO: Put complex figure generation here
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    % need to select the proper row of the output_paths_table
    n=1;
    if height(output_paths_table) > 1
        warning('Unexpected more than one output line, james lazyily coded this to only one. You need to select the correct row, or add a loop here.')
        keyboard;
    end
    group_stats_file=output_paths_table.StatsResults{n};
    processed_stats_dir=fileparts(group_stats_file);
    scalar_complex_vis_dir=fullfile(processed_stats_dir,'complex_figures');
    previously_loaded_labelfile={};

    %% list off the "cool" columns to go plot
    %{
% We could be cool and look up the columns to prevent error, but really we
% should know them. So, we'll just assume they're righteous to avoid loading
% the table one more time.
col_idx=cell(size(col_types));
for col_type_idx=1:numel(col_types)
    col_idx{col_type_idx}=column_find(col_names,sprintf('%s_.+',col_types{col_type_idx}),1);
end
col_names=group_stat_table.Properties.VariableNames;
    %}
    col_types={'cohenD','percent_change'};

    column_setup = {
        'pvalue_extended', 'pval'
        'pvalue', 'pval_BH'
        };
    % indicies of the summary criteria, we dont use summary criterais because
    % its not as well connected to what we want.
    summary_idx=pairwise_criteria.control.applytosummary==1;
    % comparison_names
    case_names=pairwise_criteria.control.case(summary_idx);
    name_code=cell(size(case_names));
    sum_compare=compare_criteria{1}(:,summary_idx);
    for col_type_idx=1:numel(col_types)
        for n=1:size(sum_compare,2)
            test_name_ctrl=strsplit(sum_compare{1,n},{':',','});
            test_name_treat=strsplit(sum_compare{2,n},{':',','});

            name_code{n}=strcat(strjoin(test_name_ctrl(2:2:end),'_'),'_',strjoin(test_name_treat(2:2:end),'_'));
            name_code{n}=strrep(name_code{n},'.','p');

            % expect 1 column here?
            %name_code_idx=column_find(col_names,sprintf('.*(%s)$',name_code{n}),1);
            %n_idx=name_code_idx&col_idx{col_type_idx};
            %if nnz(n_idx)==1
            %    column_setup(end+1,:)={col_types{col_type_idx},col_names{n_idx}};
            %end
            column_setup(end+1,:)={col_types{col_type_idx},sprintf('%s_%s',col_types{col_type_idx},name_code{n})};
        end
    end

    % internally, composite ontology and slice generator follows the structure
    % of our figures (as it was programmed at the time). If we change that
    % orgzanization wed have to update the composite code.
    try
        label_nrrd = ontology_and_slice_generator(group_stats_file, column_setup, scalar_complex_vis_dir, previously_loaded_labelfile{:});
        % this is ONLY useful if we re-run.
        if exist('label_nrrd','var')
            previously_loaded_labelfile={label_nrrd};
        end
    catch merr
        warning(merr.message);
        fprintf('ontology and slice gen failed, see above\n');
        pause(3);
    end

    %% Create Summary Powerpoint for scalars
    for pt=pval_cols
        pvalue_type=pt{1};
        generate_summary_ppts( output_paths_table, studyID, user,pvalue_type, pval_threshold, studymodel, Summary_Criteria);
    end
end
%% Omni Manova Analysis
if sum(reg_match(which_tests,'^(Connectome)$'))>0

    try
        A=memory;
        number_of_leafs=360;
        single_array_data_sizeByte=8;
        max_specimen=sqrt(A.MaxPossibleArrayBytes/single_array_data_sizeByte)/number_of_leafs;
        max_specimen=floor(max_specimen);
    catch
        max_specimen=300; % my person mac is like 250
        number_of_leafs=360;
        single_array_data_sizeByte=8;
        A.MaxPossibleArrayBytes=single_array_data_sizeByte*(max_specimen*number_of_leafs)^2; 
    end


    if ~exist(fullfile(save_dir,'Connectomics'),'dir')
        mkdir(fullfile(save_dir,'Connectomics'))
    end

    check_names=fieldnames(stats_test_manova);
    idx_subgroup=~cellfun(@isempty,regexpi(check_names,'^(subgroup_name)$'));
    positional_idx_subgroup=find(idx_subgroup);

    if ~isempty(positional_idx_subgroup)
        name_augment=strcat(strjoin(strrep(stats_test_manova.group_name,'_',''),'_'),'_',strjoin(strrep(stats_test_manova.subgroup_name,'_',''),'_'));
    else
        name_augment=strcat(strjoin(strrep(stats_test_manova.group_name,'_',''),'_'));
    end

    if strcmp(stats_test_manova.name,'omnimanova_defined_matrix')
        temp_testname=strsplit(stats_test_manova.name,'_');
        temp_turned_matrix=stats_test_manova.matrix{:}';
        temp_matrix_numbercode=strrep(char(num2str(temp_turned_matrix(:)))',' ', '');

        if ~exist(fullfile(save_dir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode)),'dir')
            mkdir(fullfile(save_dir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode)));
        end

        save_cnt=fullfile(save_dir,'Connectomics',strcat(temp_testname{1},'_',temp_matrix_numbercode),name_augment);
    else
        if ~exist(fullfile(save_dir,'Connectomics',stats_test_manova.name),'dir')
            mkdir(fullfile(save_dir,'Connectomics',stats_test_manova.name));
        end
        save_cnt=fullfile(save_dir,'Connectomics',stats_test_manova.name,name_augment);
    end
    
    connectome_outputs=list2cell('Unscaled_Omni_Manova BrainScaled_Omni_Manova');
    do_binarize=0; do_mean_subtract=0; do_ptr=0; do_augment=0;
    t_start=tic;
    if ~file_time_check(fullfile(save_cnt, connectome_outputs{1}, 'Pval_sorted_from_ASE_0000.csv'), 'newer', dataframe_path)
        Paths_Pval=struct;

        %% All specimen OmniManova
        for n=1:numel(connectome_outputs)
            dataframe=civm_read_table(dataframe_path);

            if height(dataframe)> max_specimen
                error('Too many specimen in study to complete omni-manova on this system. Max Specimen # for system is %d.',max_specimen);
            end

            dataframe=column2text(dataframe,{group,subgroup});
            Paths_Pval.(connectome_outputs{n})=table;
            o_dir=fullfile(save_cnt,connectome_outputs{n});

            if ~exist(o_dir,'dir')
                mkdir(o_dir);
            end

            if ~isempty(column_find(dataframe,'^(scale)$'))
                find_scale=0;
            else
                find_scale=1;
            end

            set_scale=n-1;
            [regional_paths,global_paths]=full_omni_manova_process(dataframe_path,o_dir,group, subgroup,test_criteria,test_remove_criteria,stats_test_manova,do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale);
           
            
            global_interesting_results(o_dir,global_paths.pval,pval_threshold);
            regional_interesting_results(o_dir,regional_paths.pval,pval_threshold);

            Paths_Pval.(connectome_outputs{n}).name{1}='All';
            Paths_Pval.(connectome_outputs{n}).regional{1}=regional_paths.pval;
            Paths_Pval.(connectome_outputs{n}).global{1}=global_paths.pval;
        end
    end
    t_omni=toc(t_start);
    % have some sort of check of the memory requirements so that it won't
    % push too hard. (like if number of specimen > 

    %% Then do the one remove testing of Omni Manova
    remove1_dataframe=civm_read_table(dataframe_path);
    remove1_dataframe=column2text(remove1_dataframe,{group,subgroup});
    fulldataFrame=remove1_dataframe;

    num_specimen=height(remove1_dataframe);

    total_est_time_1rm=t_omni*num_specimen;
    total_est_time_1rm=total_est_time_1rm/60;
    if total_est_time_1rm > 10
        warning('The estimated time to complete all of one remove testing is %2.2f minutes!!', total_est_time_1rm);
    end

    %max_array_size -- use pval because bigger. 
    %max_data_size=520 + sum(pval_check.pval < pval_threshold)*num_specimen*8; 


    dataLimit=(A.MaxPossibleArrayBytes/single_array_data_sizeByte)-((number_of_leafs*num_specimen)^2)*num_specimen; %only works in windows machines

    %approx_specimenspace_remaining=max_specimen-2*(num_specimen+(num_specimen-1)^2); %total specimen possible based on memory - (2x because scaled/unscale) (specimen in inital omni  + all the one remove at the same time (so just )^2)
%its really related to how many entries need to keep to hold the data...
%which is more related to how many significant terms are we keeping
oneRM_done=0;
    if dataLimit>0
        % ParFor for One remove testing
        if ~file_time_check(fullfile(save_cnt,'Pval_Paths.mat'),'newer',dataframe_path)
            t_start_remove=tic;
            for n=1:numel(connectome_outputs)
                newDF_dir=fullfile(save_cnt,connectome_outputs{n},'OneRemoveDataFrames');
                if ~exist(newDF_dir,'dir')
                    mkdir(newDF_dir);
                end
                %setup parameters
                for s=1:num_specimen
                    removed_specimen{s}=remove1_dataframe.CIVM_Scan_ID{s};
                    remove1_dataframe(s,:)=[];
                    updated_dataframe_path=fullfile(newDF_dir, strcat(removed_specimen{s},'_removed_DataFrame.txt'));
                    writetable(remove1_dataframe, updated_dataframe_path);

                    o_dir=fullfile(save_cnt,connectome_outputs{n},'OneRemoveTesting',strcat(removed_specimen{s},'_removed'));
                    if ~exist(o_dir,'dir')
                        mkdir(o_dir);
                    end
                    if ~isempty(column_find(remove1_dataframe,'^(scale)$'))
                        find_scale=0;
                    else
                        find_scale=n-1;
                    end
                    set_scale=n-1;
                    param_list_1_rm{s}={updated_dataframe_path,o_dir,group,subgroup,test_criteria,test_remove_criteria,stats_test_manova,do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale};
                    remove1_dataframe=fulldataFrame;
                end

                % actual run omnimanova process for 1 remove
                parfor s=1:num_specimen
                    [regional_paths,global_paths]=full_omni_manova_process(param_list_1_rm{s}{:});
                    name{s}=strcat('No_',removed_specimen{s});
                    regional_path{s}=regional_paths.pval;
                    global_path{s}=global_paths.pval;
                end
                Paths_Pval.(connectome_outputs{n}).name((1:numel(name))+1)=name;
                Paths_Pval.(connectome_outputs{n}).regional((1:numel(name))+1)=regional_path;
                Paths_Pval.(connectome_outputs{n}).global((1:numel(name))+1)=global_path;
            end
            t_oneremove=toc(t_start_remove);
            fprintf('One remove actually took, %g minutes estimate was %g minutes\n',t_oneremove/60,total_est_time_1rm);

            save(fullfile(save_cnt,'Pval_Paths.mat'),'Paths_Pval')
try
            [Sig_Among_1RM_global_paths] = global_one_remove_compile(save_cnt,connectome_outputs,Paths_Pval,pval_threshold);
            [Sig_Among_1RM_regional_paths] = regional_one_remove_compile(save_cnt,connectome_outputs,Paths_Pval,pval_threshold);
catch
    keyboard;
end
            global_one_remove_plot(save_cnt,dataframe,Sig_Among_1RM_global_paths);
            for n=1:numel(Sig_Among_1RM_regional_paths)
                regional_one_remove_plot(save_cnt,dataframe,Sig_Among_1RM_regional_paths{n});
            end
        end

        oneRM_done=1;
    end
    %% TO DO: Put complex figure generation here for Connectomes
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    %This should be at least the blue figures

    %% TO DO: Summary PPt for Connectomes

   %generate_summary_ppts_manova(save_cnt,Paths_Pval,studyID,user,connectome_outputs,pval_threshold,studymodel,configuration_struct)

end
end

