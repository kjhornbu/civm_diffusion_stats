function [ ] = civm_diffusion_stats(varargin)
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

% pretend we've parsed options, and found an assume nlsam option.
% Input Options Parser
p = inputParser;

%{

StudyProperties={ "google_doc" "cleaned_google_doc" "dataframe"} "at least one of these is required" "if missing lower level thats fine if have higher"
    
ModelProperties={"config_file"} 

CleanedStats={"project_research_archive" "polished sheet path" }

OutputLocation= save_dir;

OptionalOptions=("studyID" "required",'Override_LabelLUT" PATH, "PvalThreshold", "Pvalcols", "AnalysisPipeline" "isSuffixOptional" "suffix" "Allow Missing" default false}_

user, studyID, google_doc, cleaned_google_doc_path,...
    dataframe_path, config_file, polished_sheet_path, project_research_archive, ...
    atlas_ontology_path, pval_cols, pval_threshold, save_dir, which_tests, ...
    optional_suffix, suffix,
%}

% === Positional arguments ===
addRequired(p, 'studyID', @(x) ischar(x) || isstring(x));
addRequired(p, 'dataframePath', @(x) ischar(x) || isstring(x));
addRequired(p, 'googleDocPath', @(x) ischar(x) || isstring(x));
addRequired(p, 'cleanedGoogleDocPath', @(x) ischar(x) || isstring(x));
addRequired(p, 'configFile', @(x) ischar(x) || isstring(x));
addRequired(p, 'statSaveDir', @(x) ischar(x) || isstring(x));
addRequired(p, 'researchArchivePath', @(x) ischar(x) || isstring(x));
addRequired(p, 'polishedSheetPath', @(x) ischar(x) || isstring(x));


% Add parameters -- Optional Options
addParameter(p, 'overrideLabelLUT', [], @(x) ischar(x) || isstring(x));
addParameter(p, 'pvalThreshold', 0.05, @(x) isnumeric(x) && numel(x) == 1 && x>=0 && x <=1);
addParameter(p, 'pvalType', list2cell('pval_BH pval'), @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'analysisPipelineType', list2cell('Scalar Connectome'), @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'isSuffixOptional', false,  @(x) isscalar(x) && ismember(x, [false, true]));
addParameter(p, 'suffix',[], @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'allowMissing', false,  @(x) isscalar(x) && ismember(x, [false, true])); %If you are missing stuff you are caring about change option to true
addParameter(p, 'assumeNLSAM', false,  @(x) isscalar(x) && ismember(x, [false, true])); %hey if you are missing all your data you need to look for NLSAM (change to true)

if isempty(getenv('USER')), user_name=getenv('USERNAME'); end
addParameter(p, 'user', user_name, @(x) ischar(x) || isstring(x) || iscell(x)); %hey if you are missing all your data you need to look for NLSAM (change to true)


%addParameter(p, 'directionality', 'double', @(x) ( ischar(x) || isstring(x) ) && reg_match(x,'negative|double|positive') );

% Parse input
parse(p, varargin{:});

opts=p.Results; 

%Unpack back into variable form
user=opts.user;
studyID=opts.studyID;
google_doc=opts.googleDocPath;
cleaned_google_doc_path=opts.cleanedGoogleDocPath;
dataframe_path=opts.dataframePath;
config_file=opts.configFile;
polished_sheet_path=opts.polishedSheetPath;
project_research_archive=opts.researchArchivePath;
atlas_ontology_path=opts.overrideLabelLUT;
pval_cols=opts.pvalType;
pval_threshold=opts.pvalThreshold;
save_dir=opts.statSaveDir;
which_tests=opts.analysisPipelineType;
optional_suffix=opts.isSuffixOptional;
suffix=opts.suffix;


if ~exist(save_dir,'dir')
    mkdir(save_dir);
end


%% Data setup -- User Input form
keep_last_dataframe = 0; % if 0 we are NOT keeping the last data frame, if 1 we ARE keeping the last dataframe
if exist(dataframe_path,'file')
    [keep_last_dataframe] = do_dataframe_ui(dataframe_path);
    if ~keep_last_dataframe
        [path,name,extension]=fileparts(dataframe_path);
        info=dir(dataframe_path);
        idate=datetime(info.date);
        idate.Format='yyyy-MM-dd''T''HHmm';
        old_file_path=fullfile(path,sprintf('%s_%s%s',name,char(idate),extension));
        movefile(dataframe_path,old_file_path) %stashing prior dataframe at same name location
    else
        %Clear out any lingering names in the dataframe table related to
        %the past group/subgrouping.
        dataframe=civm_read_table(dataframe_path);
        not_empty_logical=~cellfun(@isempty,dataframe.Properties.VariableDescriptions);
        not_empty_positional=find(not_empty_logical);

        for n=1:numel(not_empty_positional)
            dataframe.Properties.VariableDescriptions(not_empty_positional(n))={''};
        end

        civm_write_table(dataframe,dataframe_path);
    end
end

%% Need to get rid of James stuff because it is erroring out redoing data sheets for things... his example is not typical use?
if ~keep_last_dataframe
    %Clean James goop better here? This isn't what I intended at all at
    %this point... it was to write with a saving of the old entry
    if ~exist(cleaned_google_doc_path,'file')
        %Do standard metadata cleanup
        extendedStudyColumns={};
        warning('james is playing with this :D');
        % warning: james is playing with this :D
        % I'm looking to combine(smartly?) any mostly-compatible googlesheet...
        % not that I know how to tell if they're mostly compatible.
        % The use case is; a project which has more than one sheet, most of
        % the columns exist in both. I think I'll use blanks for fields which are
        % not present in both.
        if iscell(google_doc) && 1 < numel(google_doc)
            warning('%s\n\t%s\n','experimental conjoining of data sheets.','THESE MUST BE HIGHLY COMPATIBLE FOR THIS TO WORK');
            % should I enter auto-debug for any thing requiring user intervention with
            % helpful suggestions?
            db_inplace(mfilename,'auto-debug for experimental feature. DO NOT provide cell arrays of sheets if you dont want this.');
            % load all, get column headings into cell of struct
            docs=cell([numel(google_doc),1]);
            fields=cell([numel(google_doc),1]);
            field_matching_required=zeros(size(google_doc),'logical');
            colname_match_data=cell([numel(google_doc),1]);
            for idx_d=1:numel(google_doc)
                docs{idx_d}=civm_read_table(google_doc{idx_d});
                % force all columns to be treated as text.
                docs{idx_d}=column2text(docs{idx_d},docs{idx_d}.Properties.VariableNames);
                fields{idx_d}=docs{idx_d}.Properties.VariableNames;
                [not_uniform,idx_1,idx_n]=setxor(fields{1},fields{idx_d},'stable');
                if numel( not_uniform )
                    field_matching_required(idx_d)=true;
                    colname_match_data(idx_d)={{idx_1,idx_n}};
                end
            end
            % allow user to somehow pick which columns could conjoin...
            if any(field_matching_required)
                all_columns=unique([fields{:}],'stable');
                non_matching=cell2table(cell([0,numel(all_columns)]),'VariableNames',all_columns);
                for idx_d=1:numel(google_doc)
                    %[columns_to_add,idx_all]=setxor(all_columns,fields{idx_d},'stable');
                    [common_column_names,idx_all,idx_n]=intersect(all_columns,fields{idx_d},'stable');
                    %[idx_1,idx_n]=colname_match_data{idx_d}{:}
                    row_dat=zeros([1,numel(all_columns)],'logical');
                    row_dat(idx_all)=true;
                    non_matching(idx_d,:)=num2cell(row_dat);

                    % just invent columns as empties :-p
                    idx_all=find(~row_dat);
                    for idx_a=idx_all
                        col_name=all_columns{idx_a};
                        %fprintf('\t%s',col_name);
                        docs{idx_d}.(col_name)=repmat({''},[height(docs{idx_d}),1]);
                    end
                end

            end
            cloud_notebook=concat_tables({},docs{:});
            clear docs fields field_matching_required colname_match_data idx_d idx_all idx_a idx_n col_name non_matching idx_1 all_columns not_uniform;
        elseif iscell(google_doc)
            google_doc=uncell(google_doc);
        end
        if ~exist('cloud_notebook','var')
            % if we've not loaded a bunch of notebooks and combined them
            % already, load the notebook now.
            cloud_notebook=civm_read_table(google_doc);
            % force all columns to be treated as text.
            cloud_notebook=column2text(cloud_notebook,cloud_notebook.Properties.VariableNames);
        end

        cloud_notebook = civm_metadata_cleanup(cloud_notebook,extendedStudyColumns);
        if opts.assumeNLSAM
            % alternative options, tryNLSAM where we would at some later point
            % try with and without NLSAM, although James doesnt like that due to the ambiguouity.
            % assumes nlsam is not part of runno, and adds it.
            %cloud_notebook.CIVM_Scan_ID=cellfun(@(x) sprintf('%sNLSAM',x),cloud_notebook.CIVM_Scan_ID,'UniformOutput',false);
            % forces nlsam at end of runno, but doesnt accidentially add it
            % when it already exists.
            cloud_notebook.CIVM_Scan_ID=cellfun(@(x) regexprep(x,'^(.*?)(NLSAM)?$',"$1NLSAM"),cloud_notebook.CIVM_Scan_ID,'UniformOutput',false);
        end

        %do visualization to do final cleanup of cloudnotebook
        cloudnotebook_table_ui(cloud_notebook,cleaned_google_doc_path);
    end

    % take cloudnotebook and convert into a dataframe
    cloudnotebook_to_dataframe('CIVM_Scan_ID',cleaned_google_doc_path,atlas_ontology_path,polished_sheet_path,dataframe_path,project_research_archive,optional_suffix,suffix,opts.allowMissing)
end

%% Stats Setup
% set a setup.mat path where we can save the configuration data, to let
% people skip it next time.
if isempty(config_file)
    [~,n,~]=fileparts(dataframe_path);
    config_file=fullfile(save_dir,sprintf('%s_setup.mat',n));
end
clear n;
% check thing exists -- intialize to do it.
keep_last_setup=0;
if exist(config_file,'file')
    % prompt for keeping configuration (1 == keep)
    keep_last_setup=do_configuration_ui(config_file);

    if ~keep_last_setup
        % when NOT keeping, rename the previous to contain its save date so
        % we can tell what we ran and when.
        info=dir(config_file);
        [p,n,~]=fileparts(config_file);
        idate=datetime(info.date);
        idate.Format='yyyy-MM-dd''T''HHmm';
        old_file=fullfile(p,sprintf('%s_setup_%s.mat',n,char(idate)));
        movefile(config_file,old_file)
        clear info idate old_file;
    end
end
clear p n;

if ~keep_last_setup
    configuration_table=stats_configuration_ui(dataframe_path);
    configuration_struct=assignmodelmatrix_ui(configuration_table);
    [pairwise_criteria]=pairwise_compare_ui_apply2summary(configuration_struct,dataframe_path);

    %save pairwise_criteria, configuration struct
    save(config_file,'pairwise_criteria','configuration_struct','-mat');
else
    % load pairwise_criteria, configuration struct
    load(config_file,'pairwise_criteria','configuration_struct');
end

[group, subgroup, test_criteria, test_remove_criteria, stats_test_scalar, stats_test_manova, plot_criteria, studymodel, compare_criteria, Summary_Criteria] = ...
    clean_up_stats_setup(configuration_struct, pairwise_criteria,pval_threshold);

%% Scalar Analysis
dataframe=civm_read_table(dataframe_path);
dataframe=column2text(dataframe,{group,subgroup});

if sum(reg_match(which_tests,'^(Scalar)$'))>0

    %Setup folder naming
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

    % easy to screw up scalar sheet paths
    %output_paths=fullfile(save_dir,'Scalar_Data_Sheet_Paths.csv');
    % less easy to screw up.
    [~,setup_name,~]=fileparts(config_file);
    %output_paths=fullfile(save_dir,'Scalar_Data_Sheet_Paths.csv');
    output_paths=fullfile(save_dir,sprintf('%s_Scalar_Sheet_Paths.csv',setup_name));
    if ~file_time_check(output_paths, 'newer', config_file)
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
    % In theory to plot more just modify plotting_sheet_types and
    % plotting_hemispheres to whatever you want.


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
        output_paths_with_compare=Generate_PairwiseSheet_Plotting( output_paths_table, compare_criteria, pvalue_type, pval_threshold, {plot_criteria}); %

        close all
    end
    output_paths_table=output_paths_with_compare;

    %% TO DO: Put complex figure generation here
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    % need to select the proper row of the output_paths_table

    [values,~,idx]=unique(output_paths_table.stratification);

    if (numel(values) == 1 && ~cellfun(@isempty,regexpi(values,'^(-)$'))) || (numel(values)>1 && height(output_paths_table)==numel(values))
        for n=1:numel(values)
            output_paths_table_single=output_paths_table(n,:);
            group_stats_file=output_paths_table.StatsResults{n};
            processed_stats_dir=fileparts(group_stats_file);
            scalar_complex_vis_dir=fullfile(processed_stats_dir,'complex_figures');
            previously_loaded_labelfile={};

            %% list off the "cool" columns to go plot

            col_types={'cohenD','percent_change'};
            column_setup = {
                'pvalue_extended', 'pval'
                'pvalue_extended', 'pval_BH'%This was pvalue regular before but as rob loves getting all the exact pvalues, I did more
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
                    % WARNING: ONLY the neutral works right now, make james fix the color
                    % table junk (or replace the whole thing with something smart(er/ish)).
                    column_setup(end+1,:)={sprintf('%s_WN',col_types{col_type_idx}), sprintf('%s_%s',col_types{col_type_idx},name_code{n})};
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
                generate_summary_ppts( output_paths_table_single, studyID, user,pvalue_type, pval_threshold, studymodel, Summary_Criteria);
            end
        end
    end
end
%% Omni Manova Analysis
if sum(reg_match(which_tests,'^(Connectome)$'))>0

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
    do_binarize=0; do_mean_subtract=0; do_ptr=0; do_augment=0; t_start=tic;
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
        [regional_paths,global_paths]=full_omni_manova_process(dataframe_path,o_dir,group, subgroup,test_criteria,test_remove_criteria,stats_test_manova,do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale,pval_threshold);

        %placed back inside the full_omni_manova process -- to allow
        %for stratification summarizing
        % global_interesting_results(o_dir,global_paths.pval,pval_threshold); % These are doing the summary plottign here
        % regional_interesting_results(o_dir,regional_paths.pval,pval_threshold); % These are doing the summary plottign here

        % Need to figure out how this is done for the scalar data...

        Paths_Pval.(connectome_outputs{n}).name{1}='All';
        Paths_Pval.(connectome_outputs{n}).regional{1}=regional_paths.pval;
        Paths_Pval.(connectome_outputs{n}).global{1}=global_paths.pval;
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
    dataLimit=(A.MaxPossibleArrayBytes/double_array_data_sizeByte)-((number_of_leafs*num_specimen)^2)*num_specimen; %only works in windows machines
    max_1rm=((A.MaxPossibleArrayBytes/double_array_data_sizeByte)/(number_of_leafs)^2)^(1/3);
    %approx_specimenspace_remaining=max_specimen-2*(num_specimen+(num_specimen-1)^2); %total specimen possible based on memory - (2x because scaled/unscale) (specimen in inital omni  + all the one remove at the same time (so just )^2)
%its really related to how many entries need to keep to hold the data...
%which is more related to how many significant terms are we keeping

oneRM_done=0;

%Check groupings for n in them if <2 then cannot actually do 1-remove
%testing without breaking the test.

use_subgroup=isfield(stats_test_manova,'subgroup_name');
use_group=isfield(stats_test_manova,'group_name');
if use_group==1
    if use_subgroup==1
        grouping_names=[stats_test_manova.group_name,stats_test_manova.subgroup_name];
    else
        grouping_names=[stats_test_manova.group_name];
    end
else
    warning('No Groups with Names defined, you need at least one!')
end
grouping_models=stats_test_manova.matrix{1};

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
                    writetable(remove1_dataframe, updated_dataframe_path,'Delimiter', '\t'); %added  tab deliminator

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
                    param_list_1_rm{s}={updated_dataframe_path,o_dir,group,subgroup,test_criteria,test_remove_criteria,stats_test_manova,do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale,pval_threshold};
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
    else
        fprintf('Not Doing 1 Remove Testing of Omni-Manova -- Too many specimen to do analysis (Have %d, Can Only Do %d)\n',num_specimen,floor(max_1rm));
    end
end
    %% TO DO: Put complex figure generation here for Connectomes
    % they are so dependant for ordering to put together but at least getting
    % the components  here would be a good thing.

    %This should be at least the blue figures

    %% TO DO: Summary PPt for Connectomes

   %generate_summary_ppts_manova(save_cnt,Paths_Pval,studyID,user,connectome_outputs,pval_threshold,studymodel,configuration_struct)

end
end

