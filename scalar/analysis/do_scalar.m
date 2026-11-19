function [opts] = do_scalar(opts)
%% Scalar Analysis
if sum(reg_match(opts.analysisPipelineType,'^(Scalar)$'))>0
    dataframe=civm_read_table(opts.dataframePath);
    dataframe=column2text(dataframe,{opts.statistical_model.group,opts.statistical_model.subgroup});

    %Setup folder naming
    if ~exist(fullfile(opts.statSaveDir,'Scalar_and_Volume'),'dir')
        mkdir(fullfile( opts.statSaveDir,'Scalar_and_Volume'))
    end

    check_names=fieldnames(opts.statistical_model.stats_test_scalar);
    idx_subgroup=~cellfun(@isempty,regexpi(check_names,'^(subgroup_name)$'));
    positional_idx_subgroup=find(idx_subgroup);

    if ~isempty(positional_idx_subgroup)
        name_augment=strcat(strjoin(strrep(opts.statistical_model.stats_test_scalar.group_name,'_',''),'_'),'_',strjoin(strrep(opts.statistical_model.stats_test_scalar.subgroup_name,'_',''),'_'));
    else
        name_augment=strcat(strjoin(strrep(opts.statistical_model.stats_test_scalar.group_name,'_',''),'_'));
    end

    if strcmp(opts.statistical_model.stats_test_scalar.name,'anovan_defined_matrix')
        temp_testname=strsplit(opts.statistical_model.stats_test_scalar.name,'_');
        temp_turned_matrix=opts.statistical_model.stats_test_scalar.matrix{:}';
        temp_matrix_numbercode=strrep(char(num2str(temp_turned_matrix(:)))',' ', '');

        if ~exist(fullfile( opts.statSaveDir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode)),'dir')
            mkdir(fullfile( opts.statSaveDir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode)));
        end

        save_scalar=fullfile( opts.statSaveDir,'Scalar_and_Volume',strcat(temp_testname{1},'_',temp_matrix_numbercode),name_augment);
    else
        if ~exist(fullfile( opts.statSaveDir,'Scalar_and_Volume',opts.statistical_model.stats_test_scalar.name),'dir')
            mkdir(fullfile( opts.statSaveDir,'Scalar_and_Volume',opts.statistical_model.stats_test_scalar.name));
        end
        save_scalar=fullfile( opts.statSaveDir,'Scalar_and_Volume',opts.statistical_model.stats_test_scalar.name,name_augment);
    end

    if ~exist(save_scalar,'dir')
        mkdir(save_scalar);
    end

    

    %% MAKE THIS THE SCALAR FOLDER
    [~,setup_name,~]=fileparts(opts.configFile);
    output_paths=fullfile( opts.statSaveDir,sprintf('%s_Scalar_Sheet_Paths.csv',setup_name));

    if ~file_time_check(output_paths, 'newer', opts.configFile)
        output_paths_table=scalar_processing_main(dataframe,save_scalar,group,subgroup,test_criteria,test_remove_criteria,stats_test_scalar,opts);

        %save output path tables to a location
        output_paths_table.hemisphere=cell2mat(output_paths_table.hemisphere);
        civm_write_table(output_paths_table,output_paths);
    else
        % load files if don't want to file check
        output_paths_table=civm_read_table(output_paths);
    end

    %% Scalar Analysis Post Processing

    % limit the plotted data-sets according to limit vars set at beginning.
    % (james likes to only plot bilateral non-erode to save some time)
    % In theory to plot more just modify plotting_sheet_types and
    % plotting_hemispheres to whatever you want.

    px=sprintf('^%s$',strjoin(opts.plotting_sheet_types,'|'));
    st_idx=row_find(output_paths_table,'voxel_wise',px,1);
    h_idx=any( row_find(output_paths_table,'hemisphere',opts.plotting_hemispheres,1), 2);
    limited_output_paths_table=output_paths_table(st_idx&h_idx,:);
    output_paths_table=limited_output_paths_table;

    % sort by subject,group,stats for efficiency of plotting
    strat_specific_cols=list2cell('SubjectTable GroupTable StatsResults Posthoc');
    output_paths_table=sortrows(output_paths_table,['SubjectTable' strat_specific_cols]);

    %% create Basic Advanced Figures
    for pt=opts.pvalType
        pvalue_type=pt{1};
        % need to assign to temp to prevent handling pval different from pval_BH
        output_paths_with_compare=Generate_PairwiseSheet_Plotting( output_paths_table, compare_criteria, pvalue_type, opts.pvalThreshold, {plot_criteria}); %

        close all
    end
    output_paths_table=output_paths_with_compare;

    %% Complex figure generation for Scalar Bilateral Non Erode
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    % need to select the proper row of the output_paths_table

    [values,~,idx]=unique(output_paths_table.stratification);

    if (numel(values) == 1 && ~cellfun(@isempty,regexpi(values,'^(-)$'))) || (numel(values)>1 && height(output_paths_table)==numel(values))

        %% Create Summary Powerpoint for scalars
        for n=1:numel(values)
            output_paths_table_single=output_paths_table(n,:);
            for pt=opts.pvalType
                pvalue_type=pt{1};
                generate_summary_ppts( output_paths_table_single, studyID, user,pvalue_type, opts.pvalThreshold, studymodel, Summary_Criteria);
            end
        end

        if isempty(test_remove_criteria{1})
            col_types={'cohenD','percent_change'};
        else
            col_types={'absolute_error'};
        end

        for n=1:numel(values)
            group_stats_file=output_paths_table.StatsResults{n};
            processed_stats_dir=fileparts(group_stats_file);
            scalar_complex_vis_dir=fullfile(processed_stats_dir,'complex_figures');
            previously_loaded_labelfile={};

            %% list off the "cool" columns to go plot

            %these are set columns that are fixed color ranges for the data
            %col_types={'cohenD','percent_change'};
            column_setup = {
                'singleside_cohen','cohenF'
                'pvalue_extended', 'pval'
                'pvalue_extended', 'pval_BH'
                };

            % indicies of the summary criteria, we dont use summary criterais because
            % its not as well connected to what we want.

            summary_idx=pairwise_criteria.control.applytosummary==1;

            % comparison_names version -- technically could be defined so
            % each one is different.
            case_names=pairwise_criteria.control.case(summary_idx);
            name_code=cell(size(case_names));
            sum_compare=compare_criteria{1}(:,summary_idx);

            for col_type_idx=1:numel(col_types)
                for m=1:size(sum_compare,2)
                    test_name_ctrl=strsplit(sum_compare{1,m},{':',','});
                    test_name_treat=strsplit(sum_compare{2,m},{':',','});

                    name_code{m}=strcat(strjoin(test_name_ctrl(2:2:end),'_'),'_',strjoin(test_name_treat(2:2:end),'_'));
                    name_code{m}=strrep(name_code{m},'.','p');

                    % expect 1 column here?
                    %name_code_idx=column_find(col_names,sprintf('.*(%s)$',name_code{n}),1);
                    %n_idx=name_code_idx&col_idx{col_type_idx};
                    %if nnz(n_idx)==1
                    %    column_setup(end+1,:)={col_types{col_type_idx},col_names{n_idx}};
                    %end
                    % WARNING: ONLY the neutral works right now, make james fix the color
                    % table junk (or replace the whole thing with something smart(er/ish)).

                    column_setup(end+1,:)={sprintf('%s_WN',col_types{col_type_idx}), sprintf('%s_%s',col_types{col_type_idx},name_code{m})};
                end
            end

            % internally, composite ontology and slice generator follows the structure
            % of our figures (as it was programmed at the time). If we change that
            % orgzanization wed have to update the composite code.

            %this generates our master queue for the dataset.
            [main_plot_queue{n},main_composite_queue{n},~]=ontology_and_slice_generator(group_stats_file, column_setup, scalar_complex_vis_dir, previously_loaded_labelfile);

        end

        % Do Actual Running of queues
        plot_queue=vertcat(main_plot_queue{:});
        composite_queue=vertcat(main_composite_queue{:});
        [function_success] = tracking_running_queues(plot_queue,composite_queue);

    end
end

opts.Scalar_Sheet_Path_csv=output_paths_table;
end