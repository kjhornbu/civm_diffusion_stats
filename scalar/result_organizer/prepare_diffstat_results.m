function prepare_diffstat_results(varargin)
% function prepare_diffstat_results(statistical_view_dir, path_to_config)
%
% Take the complex_figures folders and create a partial replicate with
% obvious organization. (May eventually support figures as well.)
% 
% Obvious pitfalls all over this idea, not the least of which is we'll
% want to greatly change names. 
% Once organization works planing all kinds of bonus ideas, like htm
% composite files, and or re-try complex compositing.
%

%% ALL input options
p = inputParser;

% === Positional arguments ===
% path to statistical view folder. Our config worth of data will be placed
% inside here as "stratificaiton_output_name"
addRequired(p, 'statsViewDir', @validate_dirpath);
addRequired(p, 'configFile', @validate_file);

% the stats out directory 
addParameter(p,'stats_main_previous','unchanged',@validate_path);
addParameter(p,'stats_main_current','.',@validate_dirpath);
% old option flags... 
addParameter(p,'base_path_old','unchanged',@validate_path);
% have to use default '.' default when using validate_dirpath, as the directory
% must exist.
addParameter(p,'base_path_new','.',@validate_dirpath);

% A way to swap which dataframe is used in the case we renamed our
% dataframe manually. Dataframe needs dated-file support in some flavor as
% it will also be auto moved on re-write detected.
addParameter(p,'override_data_frame', 'unchanged', @validate_filepath);
% default '', allows specifying alternate scalar_paths table, useful if data has been moved/re-arranged and/or re-run.
addParameter(p,'override_scalar_paths','unchanged', @validate_filepath);
% default false, if scalar paths sheet has been lost, this will not use it,
% and will instead use hard-coded formula to get info.
addParameter(p,'guess_scalar_paths', false, @validate_bool); 

% have to use default '.' default when using validate_dirpath, as the directory
% must exist. These can be fragments of directories, so we dont use
% validate_dirpath
% addParameter(p,'override_complex_figures','.',@validate_path);
% %unimplemented
addParameter(p,'additional_complex_figures', {'.'}, @(x) iscell(x) && all( cellfun(@validate_path, x)))

% was to change the complex config, use + or - "param" to add to the output
% entries we prepare. if +/- are not specified we replace the existing
% list.
addParameter(p,'complex_stat_param', 'unchanged', @validate_strings);
addParameter(p,'complex_pairwise', 'unchanged', @validate_strings);

% when we break up our data before the stats pipeline ever sees it, how
% will we indicate that so that our subjects table is not overwritten?
% I guess for now, external_stratification is clear enough 
addParameter(p,'external_stratification',false,@validate_bool);
%addParameter(p,'partial_project',false,@validate_bool);
%addParameter(p,'limited_stats_input',false,@validate_bool);

% if we have pairwise comaprisons for sex, should they also be included.
% default true.
addParameter(p,'include_pairwise_sex',true,@validate_bool);
% only_pairwise_sex will help if we ran a special batch later to replace
% just sex; incompatible with include_pairwise_sex=false, but it doesnt
% check.
addParameter(p,'only_pairwise_sex',true,@validate_bool);
% filetype inclusions
addParameter(p,'include_subject_table',true,@validate_bool);
addParameter(p,'include_group_table',true,@validate_bool);
addParameter(p,'include_result_table',true,@validate_bool);
addParameter(p,'include_effect_distribution',true,@validate_bool);
addParameter(p,'include_significant_summary_table',true,@validate_bool);
addParameter(p,'include_summary_presentation',true,@validate_bool);
addParameter(p,'include_summary_figures',true,@validate_bool);


% need another option which will create an additional folder layer
% when we have "bonus" sex comparisons to go with our primary study
% condition. for now it'll just default off... 
% I dont like this otpion name. 
addParameter(p,'pairwise_sex_separate_combined',false,@validate_bool);

% should include sprintf apprpriate place holders for the stratifications
% of interest, probably one of these ( %i, %02i, %f, %0.2f, %g, %s )
addParameter(p, 'stratification_output_name', '', @validate_text);
addParameter(p, 'stratification_selection', '.*', @(x) iscellstr(x) || validate_text(x));

% If there is more than one group column (indicating primary study element),
% which one will we be organizing? 
% We only support one at a time! 
% This column name SHOULD be in reference to the stratification_output_name 
% which is tied to a name for this experiement!
addParameter(p, 'primary_study_column', '', @validate_text);

% at most hemispheres could have 3 entries, Bilateral, Left, Right
% where are my civm-definitions which would tell me that?
addParameter(p, 'hemispheres_to_process',{'Bilateral'}, ...
    @(x) iscell(x) && 1 <= numel(x) && numel(x) < 3 && all(reg_match(x,'^(Left|Bilateral|Right)$')) );

% in case we ever stop hemisphere stratification.
addParameter(p, 'stratify_on_hemisphere',true,@validate_bool);

addParameter(p, 'contrast_limit',false, @(x) iscellstr(x) || validate_text(x));

% which of our defacto 4 slices should be used. input reasonably flexible,
% but doesnt have 100% safety. If a cell array passed validation
% incomplete.
addParameter(p, 'slice_selection', [1, 2, 3, 4], ...
    @(x) ( ( isnumeric(x) || isstring(x) || iscellstr(x) ) && 1 <= numel(x) && numel(x) <= 4 ) ...
    || ( islogical(x) && numel(x)==4 && 1 <= nnz(x) )  );

% when files are missing, do we error right away, or transfer all possible?
addParameter(p,'abort_on_missing',true,@validate_bool);
% do we add dot prefix and/or set hidden file attrib on windows.
addParameter(p,'hide_transfer_log',true,@validate_bool);

parse(p, varargin{:});
opts=p.Results; 

%% Standard Definitions
% Hemisphere and slice levels
% matlab civm-definitions anyone? 
hemisphere_mapping=struct('Left',-1, 'Bilateral',0, 'Right', 1);
scalar_complex_fig_slice_levels=list2cell('M1p98 M2p96 M3p96 M4p88');

%% Checking if moving files. 
moved_data=false;
if not( strcmp(opts.base_path_old,'unchanged') )
    warning([ ...
        'Deprecated input flag detected! please change to stats_main_previous from base_path_old\n' ... 
        'Deprecated input flag detected! please change to stats_main_current from base_path_new' ...
        ]);
    pause(3);
    opts.stats_main_previous=opts.base_path_old;
    opts.stats_main_current=opts.base_path_new;
end
if not( strcmp(opts.stats_main_previous,'unchanged') )
    moved_data=true;
    assert( ~exist(opts.stats_main_previous,'dir'), 'You''ve specified moved data by setting stats_main_previous and/or stats_main_current, however the old data folder still exists: %s',opts.stats_main_previous);
    assert( exist(opts.stats_main_current,'dir'), 'You''ve specified moved data by setting stats_main_previous and/or stats_main_current, however the new data folder does not exist: %s',opts.stats_main_current);
end

% TODO: more validation for stratification_output_name.
% opts.stratification_output_name='%02iMonth_zQ175DN';

% TODO: more validation on contrast limit.
% from con_opts.scalarContrastMetrics.List, which entries shall we use
% opts.contrast_limit=list2cell('fa_mean volume_fraction');

% TODO: more validation for hemisphere related opts.
%opts.hemispheres_to_process={'Bilateral'};
% in case we ever stop hemisphere stratification.
%opts.stratify_on_hemisphere=true;


% TODO: more slice-seleciton valiation
selected_slices=ones(size(scalar_complex_fig_slice_levels),'logical');
% input is allowing numeric, string, cell, or logical.
if isnumeric(opts.slice_selection)
    selected_slices(:)=false;
    selected_slices(opts.slice_selection)=true;
elseif islogical(opts.slice_selection)
    selected_slices=opts.slice_selection;
else
    % cell or string input
    if isstring(opts.slice_selection)
       opts.slice_selection=cellstr(opts.slice_selection);
    end
    if iscell(opts.slice_selection)
        selected_slices=ismember(scalar_complex_fig_slice_levels,opts.slice_selection);
        assert(all(ismember(opts.slice_selection,scalar_complex_fig_slice_levels)), ...
            'Unrecognized slice level keywords %s are not all %s', ... 
            cell2str(opts.slice_selection), cell2str(scalar_complex_fig_slice_levels) );
    else
        error('Untested condition, not sure how you got here');
    end
end

warning('so many input flags! what should i use!');

%% helper vars to reduce workspace clutter.
% structs to hold the many name parts, defind here so the fields are in a
% satisfyingly order, highly similar to their use in file/folder paths (at the time this code was written).
% 
% Later in the code, name and files and dirs will continually reuse the
% same fields, upating them for the file of interst and its properties.
names=struct;
dirs=struct;
files=struct;
names.config='UNRESOLVED';
names.config_dated='UNRESOLVED';
names.diff_stat_opts='UNRESOLVED';
names.scalar_paths='UNRESOLVED';
names.scalar_stat='Scalar_and_Volume';
names.stat_test='UNRESOLVED';
names.stat_factors='UNRESOLVED';
names.stat_model='UNRESOLVED';
names.erode_dirs={'UNRESOLVED'};
% if there is stratification this will be a struct array.
names.stratification=struct;
names.stratification.input='UNRESOLVED';
names.stratification.output='UNRESOLVED';
names.stratification.hemisphere=NaN;
names.stratification.hemisphere_name='UNRESOLVED';
% Considered adding this, but decided its spurious
%names.stratification.erode='UNRESOLVED';
names.stratification.column_and_val='UNRESOLVED';
names.stratification.relevant_stat_runs=table();

names.erode='UNRESOLVED';
% folder name for scalar figures
names.figures='figures';
% folder name for scalar summary
names.summary='Summary';
% names.figures='figures_withoutFDR';
names.complex_figures='complex_figures';
names.fig_dirs={'UNRESOLVED'};
names.significant_table='UNRESOLVED';
names.summary_ppt='UNRESOLVED';
names.effect_distribution='UNRESOLVED';
names.slice=struct( ...
    'input','UNRESOLVED', ...
    'output','UNRESOLVED');
names.strat=struct( ...
    'input','UNRESOLVED', ...
    'output','UNRESOLVED');
names.output_types=struct();

dirs.stats_save='UNRESOLVED';
dirs.strat_container='UNRESOLVED';
dirs.stratification='UNRESOLVED';
dirs.scalar_figs='UNRESOLVED';
dirs.scalar_figure_set='UNRESOLVED';
dirs.scalar_figure_set_metric='UNRESOLVED';
dirs.scalar_figure_set_metric_svg='UNRESOLVED';
dirs.scalar_summary='UNRESOLVED';
dirs.scalar_complex_figs='UNRESOLVED';
dirs.scalar_complex_set='UNRESOLVED';
dirs.scalar_complex_set_colorbar='UNRESOLVED';
dirs.scalar_complex_set_metric='UNRESOLVED';
dirs.scalar_complex_lookup='UNRESOLVED';
dirs.scalar_complex_metric_svg='UNRESOLVED';

dirs.colorbar_out='UNRESOLVED';
dirs.LUT_out='UNRESOLVED';
dirs.stratification_out='UNRESOLVED';
dirs.table_out='UNRESOLVED';
dirs.summary_out='UNRESOLVED';
dirs.effect_distribution_out='UNRESOLVED';
dirs.slicer_lookup_out='UNRESOLVED';
dirs.contrast_out='UNRESOLVED';
dirs.slice_out={};

files.config_file=opts.configFile;
files.diff_stat_opts='UNRESOLVED';
files.data_frame='UNRESOLVED';
files.scalar_sheet_paths='UNRESOLVED';
files.subject_table='UNRESOLVED';
files.group_table='UNRESOLVED';
files.stat_results_table='UNRESOLVED';
files.stat_posthoc='UNRESOLVED';
files.significant_table='UNRESOLVED';
files.significant_graph_sov='UNRESOLVED';
files.significant_graph_contrast='UNRESOLVED';
files.summary_ppt='UNRESOLVED';
files.effect_distribution='UNRESOLVED';

files.colorbar='UNRESOLVED';
files.LUT_file='UNRESOLVED';
files.slicer_lookup='UNRESOLVED';

files.slice='UNRESOLVED';
% full ontology ?
% partial ontologies?

files.colorbar_out='UNRESOLVED';
files.slice_out='UNRESOLVED';
files.effect_out='UNRESOLVED';
files.significant_graph_sov_out='UNRESOLVED';
files.significant_graph_contrast_out='UNRESOLVED';

% Structure array of html configurations or something like that. 
% if using structure, will have an html type
% Expected types are; "multi-slice+colorbar", "effect_distribution",
% ontology, summary? Only the first two are close to being defined. 
% should contain all html output.
files.html_out=containers.Map();

[p,names.config,e]=fileparts(files.config_file);
% get civm_diffuion_stats opts from mat file if present.
if ~reg_match(names.config,'.*_[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{4}$') 
    % check if this is a dated backup file
    names.diff_stat_opts=[names.config '_opts' e];
    % get names.config_dated
    info=dir(files.config_file);
    c_date=datetime(info.date);
    c_date.Format='yyyy-MM-dd HHmm';
    d_str=strrep(char(c_date),' ','T');
    names.config_dated=sprintf('%s_%s',names.config,d_str);
    clear info c_date d_str;
else
    names.diff_stat_opts=[regexprep(names.config,'(.*)(_[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{4})$','$1_opts$2') e];
    names.config_dated=names.config;
    warning('Should fix name.config to remove date');
    pause(2);
end
files.diff_stat_opts=fullfile(p,names.diff_stat_opts);
con_opts=struct;
if exist(files.diff_stat_opts,'file')
    %breaks if you use strings.
    con_opts=matfile(files.diff_stat_opts);
    con_opts=con_opts.opts;
    dirs.stats_save=con_opts.statSaveDir;
    files.data_frame=con_opts.dataframePath;

    if moved_data
        dirs.stats_save=file_basepath_swap(dirs.stats_save,opts.stats_main_previous,opts.stats_main_current);
        files.data_frame=file_basepath_swap(files.data_frame,opts.stats_main_previous,opts.stats_main_current);
    end

    if not( strcmp(opts.override_data_frame,'unchanged') )
        % if user specifies a data frame we MUST use it, we dont care if
        % files.data_frame is set to a real file otherwise.
        files.data_frame=opts.override_data_frame;
    end
end
% get scalar sheet paths
if strcmp(opts.override_scalar_paths,'unchanged')
    files.scalar_sheet_paths=fullfile(p,[names.config '_Scalar*Sheet*Paths.csv']);
else
    files.scalar_sheet_paths=opts.override_scalar_paths;
end
sp_info=dir(files.scalar_sheet_paths);
if ~isempty(sp_info)
    assert(numel(sp_info)==1,'Too many scalar sheet paths found');
    names.scalar_paths=sp_info(1).name;
    files.scalar_sheet_paths=fullfile(sp_info(1).folder,names.scalar_paths);
    ScalarPaths=civm_read_table(files.scalar_sheet_paths,[],[],1);
else
    ScalarPaths=table();
end
clear sp_info p e;
%%%
% get relevant stats files, generally we only want bilateral but this'll
% extend to others as well. 
idx_stat=zeros(height(ScalarPaths),1,'logical');
for hemisphere_name=opts.hemispheres_to_process
    idx_stat=idx_stat | row_find(ScalarPaths, ...
        'hemisphere', hemisphere_mapping.(uncell(hemisphere_name)), 1);
end
relevant_stat_runs=ScalarPaths(idx_stat,:);
clear idx_stat hemisphere_name;
%%%
% These log file locations MAY NOT be the final ones. 
% If the stats directory we're working on does not have multiple outputs(eg
% no stratification, only bilateral data, one of non-erode and erode), then
% we'll save the log to the output stratification directory 
% 
hidden_dot='.';
if ~opts.hide_transfer_log
    hidden_dot='';
end

files.log_out=fullfile(opts.statsViewDir,sprintf('%stransfer_%s.log',hidden_dot,names.config_dated));
% mat log, only used when there is an error.
files.log_out_mat=fullfile(opts.statsViewDir,sprintf('transfer_err_%s.mat',names.config_dated));
%% load the config
% maybe this should be first?
conf_stats=matfile(files.config_file);
conf_stat=conf_stats.configuration_struct;
conf_pair=conf_stats.pairwise_criteria;

%% get group and subgroup with their numbers.
% Get Groups and subgroupsutlized in the model 
%... do i need this?
column_config=struct;
idx_group= not( cellfun('isempty',conf_stat.test_criteria.GROUP) );
groups=conf_stat.test_criteria.Column_Names(idx_group);
group_nums=cellfun(@str2num,conf_stat.test_criteria.GROUP(idx_group));
[~,ic]=sort(group_nums);
group_nums(ic)=group_nums;
groups(ic)=groups;
for idx_g=1:numel(groups)
    desc=sprintf('group%i',group_nums(idx_g));
    column_config.(desc)=groups{idx_g};
    column_config.(groups{idx_g})=struct( ...
        'Name',groups{idx_g}, ...
        'Group',true, ...
        'SubGroup',false, ...
        'Stratification',false, ...
        'desc',desc ... 
        );
end
clear idx_g desc;
idx_subgroup=not( cellfun('isempty',conf_stat.test_criteria.SUBGROUP) );
subgroups=conf_stat.test_criteria.Column_Names(idx_subgroup);
subgroup_nums=cellfun(@str2num,conf_stat.test_criteria.SUBGROUP(idx_subgroup));
[~,ic]=sort(subgroup_nums);
%subgroup_nums(ic)=numble;
subgroup_nums(ic)=subgroup_nums;
subgroups(ic)=subgroups;
for idx_g=1:numel(subgroups)
    desc=sprintf('subgroup%i',subgroup_nums(idx_g));
    column_config.(desc)=subgroups{idx_g};
    column_config.(subgroups{idx_g})=struct( ...
        'Name',subgroups{idx_g}, ...
        'Group',false, ...
        'SubGroup',true, ...
        'Stratification',false, ...
        'desc',desc ... 
        );
end
clear idx_g desc;

clear clear idx_group idx_subgroup numble ic;
% This is equivalent to the model_table headings.
%columns_of_interest=[groups;subgroups];
% [group_nums;subgroup_nums]
columns_of_interest=conf_stat.model_table.Properties.VariableNames;
% This is the columns of interset - the stratications.
statmodel_columns=columns_of_interest;
if ~isempty(conf_stat.stratification)

    statmodel_columns(reg_match(statmodel_columns,conf_stat.stratification))=[];
    % todo: more testing around stratification!
    % for next study, found that stratification in group instead of
    % subgroup. It appears it should be pulled from both. 
    
    groups( ismember(groups,conf_stat.stratification) )=[];
    subgroups( ismember(subgroups,conf_stat.stratification) )=[];

end
clear group_nums subgroup_nums;
%% get the complex config
% complex config doesnt exist(yet) have to improvise it here.
% after thinking just a little more with what i have, instead of
% conf_complex, i should extend column_config based on the info in the
% compare table including all the little details.
conf_complex=struct;
% keys which are tied to the groups/subgroup folders I want to dynamically
% switch to cohenF if cohenD is not available.
% Thinking back to mutli-entry treatment vs single control, its not clear
% how I'd integrate those sort of things. In the upcoming context I expect
% to have multiple strains vs a control set. That is highly unclear how
% I'll manage. (Have to wait for that data to be avilable for testing
% before I can think it out.)
% conf_complex.stat_param=list2cell('result effect');
conf_complex.stat_param=list2cell('result effect');

if ~ischar(opts.complex_stat_param) || ~strcmp(opts.complex_stat_param,'unchanged')
    opts.complex_stat_param=list2cell(opts.complex_stat_param);
    conf_complex.stat_param=list_update(conf_complex.stat_param,opts.complex_stat_param);
end

% Some of these are hard coded which isn't really that great. 

conf_complex.result=struct;
conf_complex.result.param='pval_BH'; % or pval
conf_complex.result.color_table='pvalue_extended'; % or pvalue, or pvalue_robadingdong... for his extra green version
conf_complex.effect=struct;
conf_complex.effect.param='cohenF'; % ... ? what other effect measure comes from the stat test? do any?
conf_complex.effect.color_table='singleside_cohen';
conf_complex.pairwise={'cohenD_WN', 'percent_change_WN'};
if ~ischar(opts.complex_pairwise) || ~strcmp(opts.complex_pairwise,'unchanged')
    opts.complex_pairwise=list2cell(opts.complex_pairwise);
    conf_complex.pairwise=list_update(conf_complex.pairwise,opts.complex_pairwise);
end

% what is the primary study condition (column desc == group1)
conf_complex.primary_comparison='UNRESOLVED';
% when resovled primary sex should have a female and male version of
% primary
conf_complex.primary_sex={'UNRESOLVED'};
% This should be the CONTROL comparison of sexes
% This choice is based on users confusion when discussing what was
% compared. I believe commonly this is NOT what we care to analyze unless
% sex was the primary study condition. I should think how to handle that...
conf_complex.sex_comparison='UNRESOLVED';
% This should be multi-comprison for each non-control study condition
% EXCLUDING the mixed study comparison.
conf_complex.sex_study={'UNRESOLVED'};


if 1 < numel(conf_complex.stat_param)
    % while we've though ahead for both pval_BH and cohenF, and considered
    % pval, we're really NOT ready for arbitrary combinations, and we're
    % missing input. So i've added this hard stop here to annoy you ;)
    warning('testing limited transfering more than one of: %s (error potential increased)',strjoin(conf_complex.stat_param));
    pause(2);
end

% use these vars to pick out what we'll be organizing
% column_config
% conf_stat.stratification
% conf_pair
% ugh, at a cross roads between enhance config and just get this one
% working.
% I think I should probably err on just make it go. The resolution path
% will be to add a config version to output files. We'll use that to chose
% sub functions that take care of the various internal elements of
% operation.

% What to call the components of percent change.
% control, treatment
% inital, final
% basis, compare
% ref, value
% theoretical, experimental
% ref, measurement
% ref, test
% 
% I like basis and/or reference for the control val.
% 
% To make it easier to change words in the future, using this struct of
% words. 
pairwise_keywords=struct;
% alternate words.
% reference, basis, control, initial, theoretical
pairwise_keywords.reference='reference';
% compare, treatment, final, 
pairwise_keywords.compare='compare';
 %% join the pariwise tables into a comparison table
reference_tab=conf_pair.control;
reference_tab.order=permute(1:height(reference_tab),[2,1]);
reference_tab=column_reorder(reference_tab,'order');
test_tab=conf_pair.treatment;
test_tab.order=permute(1:height(test_tab),[2,1]);
test_tab=column_reorder(test_tab,'order');
for col=statmodel_columns
    reference_tab=column_rename(reference_tab, ...
        uncell(col), sprintf('%s_%s',uncell(col), pairwise_keywords.reference));
    test_tab=column_rename(test_tab, ...
        uncell(col), sprintf('%s_%s',uncell(col), pairwise_keywords.compare));
end

% key order very specific to sort in order of comparisons to match input. 
% ordering key added to ensure exact match without relying on auto sort of
% others.
comparison_table=outerjoin(reference_tab,test_tab,'Keys',{'order','applytosummary','source_of_variation','case'},'MergeKeys',true);
% running in reverse to make it easier to order columns without thinking
% about it.
for idx_col=numel(statmodel_columns):-1:1
    col_names=comparison_table.Properties.VariableNames(column_find(comparison_table,statmodel_columns{idx_col}));
    comparison_table=column_reorder(comparison_table,col_names);
end
clear reference_tab test_tab idx_col col_names

if  1 < numel(groups)
    % I envision our big 5XFad study having groups of transgene-status,
    % age, and sex. That is what i think makes sense for what we're
    % studying and how. I should add support to this organizer to treat
    % subgroups as groups becuase I expect we'll forget this idea.
    %
    % On disucssion with Kathryn, she's fairly certain we'll never be so
    % organized that multiple-models can be handled in the same pass.
    % SO, we'll have to make sure our output config is sufficiently
    % advanced that we can offer the proper comparisons under the same umbrella.
    %
    % Going further in that trouble, it is my responsiblity to decide how
    % we'll mesh mutliple comparisons. ... Lets see what i come up with :D
    warning('%s','IDK what to do with multiple groups, I''m only prepared to organize a primary output. Pausing here to let you figure it out :D');
    % My first hint of what to do would be to add source-of-variation under
    % the output metric directories. No matter what I do, some cross refernces are
    % harder than others. 
    pause(15);
end
idx_pairwise=struct;
% areas where the primary pair is NOT none may be the primary comparison
idx_pairwise.primary_control    = ~ row_find(conf_pair.control,column_config.group1,'None',1);
idx_pairwise.primary_treatment  = ~ row_find(conf_pair.treatment,column_config.group1,'None',1);
% idx.primary_diff=row_find(conf_pair.control,column_config.group1,conf_pair.treatment.(column_config.group1),1)
%idx.primary_diff=setdiff(conf_pair.control.(column_config.group1),conf_pair.treatment.(column_config.group1))
idx_pairwise.primary_diff = conf_pair.control.(column_config.group1) ~= conf_pair.treatment.(column_config.group1);
idx_pairwise.primary_potential = idx_pairwise.primary_control & idx_pairwise.primary_treatment & idx_pairwise.primary_diff;
% will idx.primary_sov and idx.primary_potential ever be different?
idx_pairwise.primary_sov=row_find(comparison_table,'source_of_variation',column_config.group1,1);

idx_pairwise.sex_potential = zeros(size(idx_pairwise.primary_potential),'logical');
if ~reg_match(conf_stat.stratification,'sex') ...
    && isfield(column_config,'Sex') || isfield(column_config,'sex')
    idx_pairwise.sex_control =   ~ row_find(conf_pair.control,  'Sex','None',1);
    idx_pairwise.sex_treatment = ~ row_find(conf_pair.treatment,'Sex','None',1);
    idx_pairwise.sex_diff = conf_pair.control.Sex ~= conf_pair.treatment.Sex;
    idx_pairwise.sex_potential = idx_pairwise.sex_control & idx_pairwise.sex_treatment & idx_pairwise.sex_diff;
    % will idx.sex_sov and idx.sex_potential ever be different?
    idx_pairwise.sex_sov=row_find(conf_pair.control,'source_of_variation','Sex',1);
else
    % test data was chdi which had plenty of samples for sex, and it was a
    % study condition.
    warning('Limited testing study when using sex stratification, or omitting it entirely. (error potential increased)');
    pause(2);
    idx_pairwise.sex_control = idx_pairwise.sex_potential;
    idx_pairwise.sex_treatment = idx_pairwise.sex_potential;
    idx_pairwise.sex_diff = idx_pairwise.sex_potential;
    idx_pairwise.sex_potential = idx_pairwise.sex_potential;
    idx_pairwise.sex_sov = idx_pairwise.sex_potential;
end

idx_pairwise.primary_comparison=idx_pairwise.primary_potential & idx_pairwise.primary_sov & ~idx_pairwise.sex_control & ~idx_pairwise.sex_treatment;
idx_pairwise.primary_sex=       idx_pairwise.primary_potential & idx_pairwise.primary_sov & ~idx_pairwise.sex_diff    & ~idx_pairwise.primary_comparison;

% Now that we've identified the primary test, narrow down idx.primary_control
% to only those lines where it is the primary control.
kw=sprintf('%s_val',pairwise_keywords.reference);
%pairwise_keywords.(kw)= ...
%    conf_pair.control.(column_config.group1)(idx_pairwise.primary_comparison);
pairwise_keywords.(kw)=conf_pair.control.(column_config.group1);

idx_pairwise.primary_control = idx_pairwise.primary_control & conf_pair.control.(column_config.group1) == pairwise_keywords.(kw);
% Like idx.primary_control, nail down idx.primary_treatment.
pairwise_keywords.(sprintf('%s_val',pairwise_keywords.compare))= ...
    conf_pair.treatment.(column_config.group1)(idx_pairwise.primary_comparison);

kw=sprintf('%s_val',pairwise_keywords.compare);
%pairwise_keywords.(kw)= ...
%    conf_pair.treatment.(column_config.group1)(idx_pairwise.primary_comparison);
pairwise_keywords.(kw)=conf_pair.treatment.(column_config.group1);

idx_pairwise.primary_treatment = idx_pairwise.primary_treatment & conf_pair.treatment.(column_config.group1)== pairwise_keywords.(kw);

idx_pairwise.sex_comparison=idx_pairwise.sex_potential & idx_pairwise.sex_sov & idx_pairwise.primary_control & ~idx_pairwise.primary_diff;
idx_pairwise.sex_study=     idx_pairwise.sex_potential & idx_pairwise.sex_sov & idx_pairwise.primary_treatment & ~idx_pairwise.primary_diff;

%% warning about applytosummary overuse
if nnz(comparison_table.applytosummary) ~= numel(comparison_table.applytosummary)
    warning('Not all comparisons were generated in complex figures! We have a config deficiency between applytosummary and generate complex');
end
%% watchout, last second blending of applytosummary with indcies
conf_complex.primary_comparison=comparison_table(idx_pairwise.primary_comparison&comparison_table.applytosummary,:);
conf_complex.primary_sex=comparison_table(idx_pairwise.primary_sex&comparison_table.applytosummary,:);

conf_complex.sex_comparison=comparison_table(idx_pairwise.sex_comparison&comparison_table.applytosummary,:);
conf_complex.sex_study=comparison_table(idx_pairwise.sex_study&comparison_table.applytosummary,:);

if ~ opts.include_pairwise_sex
    % delete rows if we're NOT supposed to include pairwise sex
    % comparisons.
    conf_complex.primary_sex(:,:)=[];
end
clear kw;
%% get name of stats folder and the factor dir
% 'anovan_1001' % should be stored in setup someplace. 
if strcmp(conf_stat.scalar_name,'anovan_defined_matrix')
    % temp model tabel
    tmp_mt=conf_stat.model_table;
    if ~isempty(conf_stat.stratification)
        idx_st=column_find(conf_stat.model_table, conf_stat.stratification);
        tmp_mt(:,idx_st)=[];
    end
    % temp model binary
    tmp_mb=table2array(tmp_mt);
    % temp model string
    tmp_ms=string(uint8(tmp_mb))';
    tmp_ms=strjoin(tmp_ms(:),'');
    names.stat_test=sprintf('anovan_%s',tmp_ms);
    clear tmp_mt idx_st tmp_mb tmp_ms;
else 
    warning('unimplemented stat handling: %s',conf_stat.scalar_name);
    keyboard
end
% all columns of interest
names.stat_factors=strjoin(strrep(columns_of_interest,'_',''),'_');
% columns of interest - stratification 
% (if no stratification we'll have all columns)
names.stat_model=strjoin(strrep(statmodel_columns,'_',''),'_');

% what is the name for the erosion stratification
names.erode_dirs=[con_opts.scalarContrastMetrics.Name];
% TODO: handle Non_Erode vs Erode correctly.
names.erode_dirs=names.erode_dirs(ismember(names.erode_dirs,'Non_Erode'));

%% get the stratification elements
stratification_elements={''};
if ~isempty(conf_stat.stratification) && ~reg_match(conf_stat.stratification,'none')

    %updated_path=file_basepath_swap(orig,old_base,new_base)
    dataframe=civm_read_table(files.data_frame,[],[],1);
    se=unique(dataframe.(uncell(conf_stat.stratification)));
    % somehow decide if we're string stratification or numeric.
    %if isnumeric(se) && ~reg_match(opts.stratification_output_name,'%.+i')
    %    se=cellfun(@num2str,num2cell(se),'UniformOutput',false);
    %end
    stratification_elements=se;
    
    %% handle partial stratification
    % when stratifying we may have asked for a limit of output. 
    % that should be a regex, or a cell. 
    if ~strcmp(opts.stratification_selection,'.*')
        if ~iscell(opts.stratification_selection)
            se=reg_match(stratification_elements, opts.stratification_selection);
            stratification_elements=stratification_elements(se);
        else
            se=ismember(stratification_elements,opts.stratification_selection);
            stratification_elements=stratification_elements(se);
        end
    end

    clear se;
end

% future proofing, in case we stop prefixing our bilateral data
if opts.stratify_on_hemisphere
    num_h=numel(opts.hemispheres_to_process);
else
    % WARNING: IT IS ASSUMED THAT opts.hemispheres_to_proces WILL CONTAIN
    % A SINGLE EMPTY CELL IF WE'RE NOT STRATIFYING ON HEMISPHERES.
    %
    warning('untested');
    keyboard;
    num_h=1;
end
% force structure array expansion.
names.stratification(numel(stratification_elements)*num_h)=names.stratification;
idx_stn=1;
for idx_h=1:num_h
    hemisphere_name=opts.hemispheres_to_process(idx_h);
    hemisphere_num=hemisphere_mapping.(uncell(hemisphere_name));
    for strat_e=stratification_elements(:)'
        % WARNING: IT IS ASSUMED THAT HN WILL BE AN EMPTY CELL IF WE'RE NOT
        % STRATIFYING ON HEMISPHERES.
        if isnumeric(strat_e)
            strat_name_in=strjoin([hemisphere_name num2str(strat_e)],'_');
            strat_e_out=strat_e;
        else
            % strat_e will be cell with 1 empty string when no
            % stratificaiotn.
            comp=[hemisphere_name strat_e];
            idx_e=cellfun('isempty',comp);
            comp(idx_e)=[];
            strat_name_in=strjoin(comp,'_');
            clear idx_e comp;
            strat_e_out=uncell(strat_e);
            if reg_match(conf_stat.stratification,'sex')
                if reg_match(strat_e,'^F(emale)?|W(oman)?') 
                    strat_e_out='Female';
                elseif reg_match(strat_e,'^M(ale)?|M(an)?')
                    strat_e_out='Male';
                end
            end
        end
        names.stratification(idx_stn).input=strat_name_in;
        names.stratification(idx_stn).hemisphere=hemisphere_num;
        names.stratification(idx_stn).hemisphere_name=hemisphere_name;

        idx_hemi=row_find(relevant_stat_runs,'hemisphere', names.stratification(idx_stn).hemisphere,1);
        % if opts.strat_pat
        if ~isempty(conf_stat.stratification) && ~reg_match(conf_stat.stratification,'none')
            % if data is stratified.
            names.stratification(idx_stn).column_and_val=sprintf('%s=%s',uncell(conf_stat.stratification),string(strat_e));
            idx_val=row_find(relevant_stat_runs,'stratification', names.stratification(idx_stn).column_and_val,1);
            if reg_match(opts.stratification_output_name,'.*[%].+')
                names.stratification(idx_stn).output=...
                    sprintf(opts.stratification_output_name, strat_e_out);
            else
                names.stratification(idx_stn).output=opts.stratification_output_name;
            end
        else
            % this is gonna cause so much trouble.
            assert(numel(stratification_elements)==1,'CONFIG fail, i need an output pattern for stratifications');
            names.stratification(idx_stn).output=opts.stratification_output_name;
            idx_val=true(size(idx_hemi));
        end

        if ~opts.guess_scalar_paths
            names.stratification(idx_stn).relevant_stat_runs=relevant_stat_runs(idx_val&idx_hemi,:);
            assert(height(names.stratification(idx_stn).relevant_stat_runs) > 0, 'Failed to connect stratification to relevant stat runs');
        end

        idx_stn=idx_stn+1;
    end
end
assert(all(   not( cellfun('isempty', {names.stratification.input}) ) ), ...
    'Stratification setup fail, programmer logic error');
clear num_h idx_stn idx_h hemisphere_name strat_e strat_name_in;

%% get figurenames

if isempty(opts.primary_study_column)
    names.fig_dirs=groups;
else
    primary_idx=ismember(groups,opts.primary_study_column);
    names.fig_dirs=groups(primary_idx);
    clear primary_idx
end
assert(numel(names.fig_dirs)==1,'HAVE NOT set up for multi-stat column yet');
names.fig_dirs=[names.fig_dirs(:)', conf_complex.pairwise];

%% init data log struct
% Two logs to hold 1-many or many-1 so we can detect any (1 or many) to (1 or many) mappings.
% Output is saved as our transfer log at end as record of what was done.
% If anything besides 1-to-1 mapping is found, we save the maps as a matlab
% format file instead of a plain text as transfer_err***.mat.
log_outkey=containers.Map();
log_inkey=containers.Map();
% More maps using md5hash values of colorbars, luts, and slicer lookups as keys. 
% Values will be structs of input, output. we'll use check for 
% previous hash and check for output set during setup to make sure we only copy
% unique entries once to only once place. The copy-over requirements for
% these are not as strict as our slice data. Generally, if the LUT file is
% the same, it doesnt matter if the color bar has changed. 
colorbar_jobs=containers.Map();
LUT_jobs=containers.Map();
slicer_lookup_jobs=containers.Map();
% Thought I might need a map for tables, cohenF distribtuion plots, and/or
% summary ppt files. But for right now I'm not adding them. 

% If we choose to avoid stop on errors, this will log every missing input file as a
% struct of parameters including the input path and output path.
log_missing=containers.Map();
missing_template_struct=struct( ...
    'erode','UNRESOLVED',...
    'stratification','UNRESOLVED',...
    'contrast','UNRESOLVED',...
    'stat_param','UNRESOLVED',...
    'slice_num','UNRESOLVED',...
    'in_name','UNRESOLVED',...
    'out_name','UNRESOLVED',...
    'in_file','UNRESOLVED',...
    'out_file','UNRESOLVED'...
    );

% keys to the dirs struct representing different parts of the scalar
% analysis internal structure. 
% This is used to make it easier ot check each dir and error.
scalar_internal_dir_keys=list2cell('stratification scalar_figs scalar_summary scalar_complex_figs');
% dirs i need to make for tables and non complex-figure files
out_dir_keys=list2cell('summary_out table_out effect_distribution_out');

dirs.colorbar_out=fullfile(opts.statsViewDir, 'ColorBar');
dirs.LUT_out=fullfile(opts.statsViewDir, 'LUT');

for k=list2cell('colorbar_out LUT_out')
    if ~exist(dirs.(uncell(k)),'dir') && ~reg_match(dirs.(uncell(k)),'UNRESOLVED')
        mkdir(dirs.(uncell(k)));
    end
end

%% process each erode-name.
for idx_erode=1:numel(names.erode_dirs)
    names.erode=names.erode_dirs{idx_erode};
    dirs.strat_container=fullfile(dirs.stats_save, names.scalar_stat, ...
        names.stat_test, names.stat_factors, names.erode);
    assert(exist(dirs.strat_container,'dir'),'Directory configuration incorrect, the programmers have failed to coordinate. This code is TIGHTLY coupled to civm_diffusion_stats.')
    % this may error when we only do one. Sorry.
    scalar_metrics=con_opts.scalarContrastMetrics(ismember([con_opts.scalarContrastMetrics.Name], {names.erode}));
    % files.subject_table=fullfile(dirs.strat_container,'Subject_Data_table.csv');
    % fullfile(dirs.strat_container,'Subject_CoV_table.csv');
    % fullfile(dirs.strat_container,'Subject_Average_Cov_table.csv');
    % fullfile(dirs.strat_container,'ROI_Average_CoV_table.csv');
    %% process each stratification
    %assert(idx_erode==1,'UNIMPLEMENTED multi-erode support');
    %files.html_out=cell(size(names.stratification));
    for idx_stratification=1:numel(names.stratification)
        % names.strat is kinda dirty because it contains additional
        % properties of the stratification which help us find the correct
        % data.
        names.strat=names.stratification(idx_stratification);
        dirs.stratification=fullfile(dirs.strat_container,names.strat.input);
        dirs.scalar_figs=fullfile(dirs.stratification,names.figures);
        dirs.scalar_summary=fullfile(dirs.scalar_figs,names.summary);
        % This is optional! scalar_complex_figs COULD be someplace else entirely!
        % The scalar_complex_figs probably SHOULD be an (optional) input!
        dirs.scalar_complex_figs=fullfile(dirs.stratification,names.complex_figures);
                        
        missing=cell(size(scalar_internal_dir_keys));
        for idx_scalar_key=1:numel(scalar_internal_dir_keys)
            k=scalar_internal_dir_keys{idx_scalar_key};
            if ~exist(dirs.(k),'dir')
                missing{idx_scalar_key}=dirs.(k);
            end
        end
        missing=missing( ~cellfun('isempty',missing) );
        assert( numel(missing)==0, sprintf('Missing:\n\t%s\n\tProgramers have failed you', strjoin(missing,'\n\t')) );
        clear missing idx_scalar_key k;

        dirs.stratification_out=fullfile(opts.statsViewDir, names.strat.output);
        dirs.table_out=fullfile(dirs.stratification_out,'Tables');
        dirs.summary_out=fullfile(dirs.stratification_out,'Summary');
        % I dont like this name. 
        dirs.effect_distribution_out=fullfile(dirs.summary_out,'effect_distribution');

        
        % Where will the outputs go? 
        %{
        out/stat_data?
        out/stat_data/summary?
        out/stat_data/tables?
        %}
        sheet_table_idx=row_find(names.strat.relevant_stat_runs,'voxel_wise',names.erode);
        assert(opts.guess_scalar_paths || numel(sheet_table_idx)==1,'Failed to select correct row of the relevant stat runs');
        
        % reset intentionally to prevent stale entry confusion.
        files.subject_table='UNRESOLVED';
        files.group_table='UNRESOLVED';
        files.stat_results_table='UNRESOLVED';
        files.stat_posthoc='UNRESOLVED';
        
        % SubjectTable includes all subjects for all stratifications we're
        % processing, and may also include additional subjects!
        if ~opts.guess_scalar_paths
            files.subject_table=names.strat.relevant_stat_runs.SubjectTable{sheet_table_idx};
            files.group_table=names.strat.relevant_stat_runs.GroupTable{sheet_table_idx};

            % This may not have pairwise comparisons, so we'll look for the
            % version which has them.
            files.stat_results_table=names.strat.relevant_stat_runs.StatsResults{sheet_table_idx};
            [sheet_dir,sheet_name,sheet_ext]=fileparts(names.strat.relevant_stat_runs.StatsResults{sheet_table_idx});
            sheet_name=strrep(sheet_name,'_withoutPairwiseComparisions','');
            alt_sheet=fullfile(sheet_dir,sprintf('%s%s',sheet_name,sheet_ext));
            if exist(alt_sheet,'file')
                files.stat_results_table=alt_sheet;
            end
            clear sheet_dir sheet_name sheet_ext alt_sheet;
            files.stat_posthoc=names.strat.relevant_stat_runs.Posthoc{sheet_table_idx};

            if moved_data
                for k=list2cell('subject_table group_table stat_results_table stat_posthoc')
                    files.(uncell(k))=file_basepath_swap(files.(uncell(k)),opts.stats_main_previous,opts.stats_main_current);
                end
            end
            
        else
            files.subject_table=fullfile(dirs.strat_container,'Subject_Data_Table.csv');
            % should match info in scalar table.
            names.strat.group_data_table.input=sprintf('%s.csv',strjoin([list2cell('Group Data Table'),statmodel_columns],'_'));
            files.group_table=fullfile(dirs.stratification,names.strat.group_data_table.input);
            
            names.strat.stat_results_table.input=sprintf('%s.csv',strjoin([list2cell('Group Statistical Results'),statmodel_columns],'_'));
            files.stat_results_table=fullfile(dirs.stratification,names.strat.stat_results_table.input);
            
            names.strat.stat_posthoc.input=sprintf('%s.csv',strjoin([list2cell('Posthoc Results'),statmodel_columns],'_'));
            files.stat_posthoc=fullfile(dirs.stratification,names.strat.stat_posthoc.input);

            assert(exist(files.subject_table,'file'),'Data reorganization has caused a failure.');            
            assert(exist(files.group_table,'file'),'Data reorganization has caused a failure.');
            assert(exist(files.stat_results_table,'file'),'Data reorganization has caused a failure.');
            assert(exist(files.stat_posthoc,'file'),'Data reorganization has caused a failure.');
        end

        names.significant_table='Significant_Statistical_Results.csv';
        files.significant_table=fullfile(dirs.scalar_summary, names.significant_table);

        files.significant_graph_sov=fullfile(dirs.scalar_summary, 'svg', 'Scalar_Summary_Sig_pval_BH_SourceOfVariation.svg');
        files.significant_graph_contrast=fullfile(dirs.scalar_summary, 'svg', 'Scalar_Summary_Sig_pval_BH_Contrast.svg');

        assert(not( opts.include_significant_summary_table ) || exist(files.significant_table,'file'), ...
            'Data reorganization has caused a failure.');
        assert(not( opts.include_summary_figures ) || exist(files.significant_graph_sov,'file'), ...
            'Data reorganization has caused a failure.');
        assert(not( opts.include_summary_figures ) || exist(files.significant_graph_contrast,'file'), ...
            'Data reorganization has caused a failure.');

        % idk how we'll use this.
        % files.subject_median_zscore
        % 24.chdi.01_Non_Erode_Bilateral_Summary_2026-06-15.pptx  
        names.summary_ppt=strjoin( [con_opts.studyID, names.erode, names.strat.hemisphere_name, 'Summary'], '_');
        files.summary_ppt=fullfile(dirs.scalar_summary,sprintf('%s.pptx',names.summary_ppt));

        if ~exist(files.summary_ppt,'file')
            files.summary_ppt=regexpdir(dirs.scalar_summary,sprintf('.*%s.*[.]pptx$',names.summary_ppt));
            % If we find more than one, crash/die. Probably should ask user
            % to select from a modify time ordered list. That gets ugly the
            % more satratifications we have in a directory. 
            if numel(files.summary_ppt) ~= 1 
                warning('More than one summary pptx found, correct choice ambiguous, fix manually right now by removing excess from matlab var files.summary_ppt');
                pause(3);
                
                %% Attempt to pick correct summary table based on results table.
                stat_info=dir(files.stat_results_table);
                group_info=dir(files.group_table);
                stat_date=datetime(stat_info.date);
                group_date=datetime(group_info.date);
                idx_mindir=0;
                min_dir=[];
                duration_0=duration(seconds(0));
                for idx_ppt=1:numel(files.summary_ppt)
                    ppt_info=dir(files.summary_ppt{idx_ppt});
                    ppt_date=datetime(ppt_info.date);

                    %ppt_date-group_date
                    %ppt_date-stat_date
                    % duration_ppt_to_group=ppt_date-group_date;
                    duration_ppt_to_stat=ppt_date-stat_date;
                    if duration_0 < duration_ppt_to_stat
                        if isempty(min_dir) || duration_ppt_to_stat< min_dir
                            min_dir=duration_ppt_to_stat;
                            idx_mindir=idx_ppt;
                        end
                    end
                end
                files.summary_ppt=files.summary_ppt(idx_mindir);
                
                clear stat_info group_info stat_date group_date idx_mindir min_dir duration_0 idx_ppt ppt_info ppt_date duration_ppt_to_group
            end
            assert(numel(files.summary_ppt)==1,'More than one summary pptx found, correct choice ambiguous');
            files.summary_ppt=uncell(files.summary_ppt);
            [~,names.summary_ppt]=fileparts(files.summary_ppt);
        end
        %% mkdir for stat ouputs (non-figure out)
        for k=out_dir_keys
            if ~exist(dirs.(uncell(k)),'dir') && ~reg_match(dirs.(uncell(k)),'UNRESOLVED')
                mkdir(dirs.(uncell(k)));
            end
        end

        %% copy with replicate logging tables and summary
        % output copy index, tables should be copied in order! 
        % expected order: subjects, group, results(pval+pairwise), posthoc
        idx_out_table=1;
        % subject_table
        if opts.include_subject_table
            % Subject tables can conflict if our stratification excluded
            % all other specimen. While we prefer NOT to do it that way, it
            % does happen(and can be much easier to work with). 
            % 
            % In that case, i think we should have the subjects table be in
            % the Tables directory, and have it numbered as 1, bumping the
            % rest of them. 
            % 
            % UNFORTUNATELY, when this is done, this code cannot see that.
            % even more fun, stratification will be 'none'!
            % I think i need a special input flag for this!
            % 
            % To help protect against supereme failure.... i'm going to
            % md5-sum the table, and if it already exists, validate that. 
            % We will then save an md5sum file as .FILENAME and make it
            % hidden.
            % 
            in_filepath=files.subject_table; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            md5=persistentmd5(in_filepath,'file');
            in_info=dir(in_filepath);
            in_info.md5=md5;
            md5_t=struct2table(in_info);
            %out_name=sprintf('%s_%s%s',con_opts.studyID,in_name,in_ext);
            out_name=sprintf('%s_Subjects%s', con_opts.studyID, in_ext);
            out_filepath=fullfile(opts.statsViewDir, out_name);
            if opts.external_stratification
                assert(~exist(out_filepath,'file'), strjoin({ ...
                    'Defacto subjects output found!,' ...
                    'This will create confusion and conflict!' ...
                    'Maybe you forgot to use external_stratification flag on a previous run?' ...
                    'Maybe you should set include_subjects_table to false?'},'\n' ) );
                % Hello friend, if you got the above error. You have a
                % subjects table conflict. Either you should only have one
                % subjects table for your whole study, or you should only
                % have stratified subject tables in each stratification. 
                % 
                % I dont support both. 
                out_name=sprintf('%s_%02i_Subjects%s', names.strat.output, idx_out_table, in_ext);
                out_filepath=fullfile(dirs.table_out, out_name);
                idx_out_table=idx_out_table+1;
            end
            [od,on,oe]=fileparts(out_filepath);
            md5_cache=fullfile(od, sprintf('.%s_md5.txt',on));
                
            if exist(out_filepath,'file')
                % existing output, validate it is identical to current or
                % ERROR. In the case we're changing the subject-table on
                % purpose, we'll have to manually remove it.
                %
                % This check exists to protect studies where we stratified
                % before civm_diffusion_stats saw the list of subjects to
                % build a common subjects data table for stratification.
                %
                existing_out_info=dir(out_filepath);
                if exist(md5_cache,'file')
                    md5_cache_t=civm_read_table(md5_cache,[],[],1);
                else
                    % To fix, we create a replacement table, validate it matches the
                    % data we're about to copy, save this replacement table(if it matches).
                    md5_e=GetMD5(out_filepath,'file');
                    md5_eo_t=struct2table(existing_out_info);
                    md5_eo_t.md5=md5_e;
                    if strcmp(md5_t.date, md5_eo_t.date) && ...
                            md5_t.bytes == md5_eo_t.bytes && ...
                            strcmp(md5_t.md5,  md5_eo_t.md5)
                        % Just replace in memory, normal code path will
                        % re-save the md5 at end.
                        md5_cache_t=md5_eo_t;
                    else
                        warning('MISSING cached md5 file! We cannot prevent error if users re-arrange output!');
                        % Hi programmer, sorry for the interrupt. The
                        % expectation is that for every subjects file, we'll
                        % save a 1-row table containing the output struct of
                        % the dir function + the md5sum of the file.
                        %
                        % I'm letting you fix that manually now.
                        % (Alternatively, you could trash the whole output dir
                        % because someone has been messing with it.)
                        %
                        % I only stopped you due to a probably data change
                        % detection!
                        keyboard;
                    end
                end
                
                assert(height(md5_cache_t)==1,'Cached file info does not match expectations. Expected one row got %i!',height(md5_cache_t));
                % The "same" struct us doing two tests. First, bytes and date 
                % are being used to verify the cached md5 is for the 
                % existing ouput file.
                % Second, md5 is testing the actual file content.
                same=struct( ...
                    'bytes', existing_out_info.bytes == md5_cache_t.bytes,...
                    'date', strcmp(existing_out_info.date, md5_cache_t.date), ...
                    'md5', strcmp(md5_t.md5, md5_cache_t.md5) );
                
                if ~all(struct2array(same)) && ~opts.external_stratification
                    warning('Subject table change detected!\n%s\n%s\n', ...
                        'Maybe you forgot to use external_stratification flag?', ...
                        'Maybe you should set include_subjects_table to false?');
                end
                % validate current file date time and size match the cached
                % values in md5_out_t. 
                assert(same.bytes, 'file size change detected. Potentially stale metadata cache.');
                assert(same.date, 'file modify date updated. Potentially stale metadata cache.');
                assert(same.md5, 'file cksum change detected. Potentially stale metadata cache.');
            end
            update_file(in_filepath, out_filepath, log_inkey, log_outkey);
            existing_out_info=dir(out_filepath);
            same=struct( ...
                'bytes', existing_out_info.bytes == md5_t.bytes,...
                'date', strcmp(existing_out_info.date, md5_t.date) );
            if all( struct2array(same) )
                if exist(md5_cache,'file')
                    delete(md5_cache);
                end
                civm_write_table(md5_t,md5_cache);
            end
            if ispc
                fileattrib(md5_cache,'+h','');
            end
            clear md5 in_info md5_t md5_cache od on oe md5_out md5_eo_t existing_out_info same
        end

        % group_table
        if opts.include_group_table
            in_filepath=files.group_table; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s_%s%s',names.strat.output, in_name, in_ext);
            out_name=sprintf('%s_%02i_Groups%s', names.strat.output, idx_out_table, in_ext);
            out_filepath=fullfile(dirs.table_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
            idx_out_table=idx_out_table+1;
        end

        %stat_results
        if opts.include_result_table
            in_filepath=files.stat_results_table; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s_%s%s', names.strat.output, strrep(in_name,'Group_',''), in_ext);
            out_name=sprintf('%s_%02i_Statistical_Results%s', names.strat.output, idx_out_table, in_ext);
            out_filepath=fullfile(dirs.table_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
            idx_out_table=idx_out_table+1;
        
            % stat_posthoc
            in_filepath=files.stat_posthoc; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s_%s%s',names.strat.output,in_name,in_ext);
            out_name=sprintf('%s_%02i_Posthoc_Results%s', names.strat.output, idx_out_table, in_ext);
            out_filepath=fullfile(dirs.table_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
            idx_out_table=idx_out_table+1;
        end
        
        % summary
        if opts.include_summary_presentation
            in_filepath=files.summary_ppt; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s%s',in_name,in_ext);
            out_name=sprintf('%s_Summary%s', names.strat.output, in_ext);
            out_filepath=fullfile(dirs.summary_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
        end

        if opts.include_summary_figures
            in_filepath=files.significant_graph_sov; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            % out_name=sprintf('%s_SignficantCount_by_SourceOfVariation%s', names.strat.output, in_ext);
            out_name=sprintf('SignficantCount_by_SourceOfVariation_for_%s%s', names.strat.output, in_ext);

            out_filepath=fullfile(dirs.summary_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
            files.significant_graph_sov_out=out_filepath;

            in_filepath=files.significant_graph_contrast; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s_SignficantCount_by_ScalarValue%s', names.strat.output, in_ext);
            out_name=sprintf('SignficantCount_by_ScalarValue_for_%s%s', names.strat.output, in_ext);

            out_filepath=fullfile(dirs.summary_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
            files.significant_graph_contrast_out=out_filepath;
        end

        % Significant results
        if opts.include_significant_summary_table
            % 'Significant_Statistical_Results.csv'
            in_filepath=files.significant_table; [in_dir,in_name,in_ext]=fileparts(in_filepath);
            %out_name=sprintf('%s%s',in_name,in_ext);
            %out_name=sprintf('%s_05_Key_Statistically_Signficant_Results%s', names.strat.output, in_ext);
            out_name=sprintf('%s_Signficant_Statistical_Results%s', names.strat.output, in_ext);
            out_filepath=fullfile(dirs.summary_out, out_name);
            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
        end
        
        clear sheet_table_idx in_filepath out_name out_filepath;
        %% loop to handle complex figures... 
        for fig_set=names.fig_dirs             
            fig_set=uncell(fig_set);

            %% handle study-column vs pairwise naming
            names.stat_param={ struct( ...
                'param',strrep(fig_set,'_WN',''),...
                'color_table',fig_set )
                };
            names.pairwise=nan;
            if ~ismember(names.stat_param{1}.param,statmodel_columns)
                names.pairwise=true;
                dirs.scalar_figure_set='NOT_APPLICABLE';
            else
                names.pairwise=false;
                % uh, could this be done ahead of time?
                names.stat_param=cell(size(conf_complex.stat_param));
                for idx_stparam=1:numel(names.stat_param)
                    names.stat_param{idx_stparam}=conf_complex.(conf_complex.stat_param{idx_stparam});
                end
                clear idx_stparam;
                dirs.scalar_figure_set=fullfile(dirs.scalar_figs,fig_set);
                assert(exist(dirs.scalar_figure_set,'dir'),'Missing %s\nProgramers have failed you',dirs.scalar_figure_set);
            end

            
            % this is the default dir for the scalar_complex_set.
            dirs.scalar_complex_set=fullfile(dirs.scalar_complex_figs,fig_set);
            % names.fig_dirs
            if numel(opts.additional_complex_figures)
                % If user specified additional_complex_figures, we will
                % check if this fig set is in ANY of those. When found in
                % ONLY ONE, we will use that one. If found in NONE, we will
                % proceed normally. If found in MANY aditional dirs we will error.
                dirs.scalar_complex_set_alt=containers.Map();
                for alt_complex=opts.additional_complex_figures(:)'
                    % we support limited substituion of inputs
                    % today, it is ONLY the stratification dir.
                    alt_complex=uncell(alt_complex);
                    alt_complex_path=alt_complex;
                    if ~dirs.scalar_complex_set_alt.isKey(alt_complex)
                        directory_substitution.STRATIFICATION_DIR='stratification';
                        for sub_text=fieldnames(directory_substitution)
                            sub_text=uncell(sub_text);
                            dir_key=directory_substitution.(sub_text);
                            value=dirs.(dir_key);
                            if reg_match(alt_complex_path,sub_text)
                                alt_complex_path=strrep(alt_complex_path,sub_text,value);
                            end
                        end
                        if ~exist(alt_complex_path,'dir')
                            warning('couldnt find alternate complex dir specified!');
                            keyboard;
                        end
                        alt_complex_path=fullfile(alt_complex_path,fig_set);
                        if exist(alt_complex_path,'dir')
                            dirs.scalar_complex_set_alt(alt_complex)=alt_complex_path;
                        end
                    end
                end
                % alt paths.
                ap=dirs.scalar_complex_set_alt.values();
                if numel(ap)==1
                    % one found, use it
                    dirs.scalar_complex_set=ap{1};
                elseif isempty(ap)
                    % none found, dont use
                else
                    % more than one found, error
                    error('Found mutliple matches for %s in the addtional_complex_figures: %s', fig_set, strjoin(ap,'\n'));
                end
            end
            assert(exist(dirs.scalar_complex_set,'dir'),'Missing %s\nProgramers have failed you',dirs.scalar_complex_set);
           
            %% work through the contrasts
            idx_selected_contrasts=ones(size(scalar_metrics.List),'logical');
            if iscellstr(opts.contrast_limit)
                % the else case **SHOULD** be that it is a single logical
                % false indicating we dont have a contrast limit.
                idx_selected_contrasts=ismember(scalar_metrics.List,opts.contrast_limit);
            end

            files.effect_out=struct();
            for contrast=scalar_metrics.List(idx_selected_contrasts)
                contrast=char(contrast);

                % transfer to output with cooler name.
                dirs.scalar_complex_set_metric=fullfile(dirs.scalar_complex_set,contrast);
                dirs.scalar_complex_set_colorbar=fullfile(dirs.scalar_complex_set,'ColorBars');
                dirs.scalar_complex_lookup=fullfile(dirs.scalar_complex_set_metric,'lookup_tables');
                dirs.scalar_complex_metric_svg=fullfile(dirs.scalar_complex_set_metric,'svg');

                assert( exist(dirs.scalar_complex_set_metric,'dir'), 'Missing %s\nProgramers have failed you',dirs.scalar_complex_set_metric);
                assert( exist(dirs.scalar_complex_lookup,'dir'), 'Missing %s\nProgramers have failed you',dirs.scalar_complex_lookup);
                assert( exist(dirs.scalar_complex_metric_svg,'dir'), 'Missing %s\nProgramers have failed you',dirs.scalar_complex_metric_svg);

                dirs.contrast_out=fullfile(opts.statsViewDir, names.strat.output, contrast);
                dirs.slicer_lookup_out=fullfile(dirs.contrast_out, 'SlicerLookups');

                if ~exist(dirs.slicer_lookup_out,'dir')
                    mkdir(dirs.slicer_lookup_out);
                end
                
                % for each primary compare, and for each
                % conf_complex.primary_sex
                % conf_complex.primary_comparison  conf_complex.primary_sex
                for idx_stparam=1:numel(names.stat_param)
                    names.colorbar=struct;
                    names.colorbar.in='UNRESOLVED';
                    names.colorbar.out='UNRESOLVED';

                    names.LUT=struct;
                    names.LUT.in='UNRESOLVED';
                    names.LUT.out='UNRESOLVED';
                    
                    names.slicer_lookup=struct;
                    names.slicer_lookup.in='UNRESOLVED';
                    names.slicer_lookup.out='UNRESOLVED';

                    files.colorbar='UNRESOLVED';
                    files.LUT_file='UNRESOLVED';
                    files.slicer_lookup='UNRESOLVED';
                   
                    % need another loop sexo switches between '', 'F', and 'M'
                    % or '', 'Female', and 'Male'
                    names.pair={'UNRESOLVED'};
                    names.pair_sex_suff={''};
                    if opts.only_pairwise_sex
                        names.pair_sex_suff={};
                    end
                    if names.pairwise %ismember(fig_set,conf_complex.pairwise)
                        %% pairwise naming conventions
                        % names.stat_param{idx_stparam}.param
                        dirs.scalar_figure_set_metric='NOT_APPLICABLE';
                        dirs.scalar_figure_set_metric_svg='NOT_APPLICABLE';
                        try
                            if ~opts.only_pairwise_sex
                                temp_table=vertcat(conf_complex.primary_comparison, ...
                                    conf_complex.primary_sex);
                            else
                                temp_table=conf_complex.primary_sex;
                            end
                            
                        catch merr
                            % we'll probably end up in this position if
                            % sex is not a factor in a study.
                            warning('Sorry, didnt test this enough');
                            merr
                            keyboard;
                        end
                        temp_column_names=temp_table.Properties.VariableNames;
                        % get indicies for the column categories,
                        % group1, sex, reference, comare
                        idx_g1_cols=column_find(temp_column_names, sprintf('^%s', column_config.group1), 1);
                        idx_sex_cols=zeros(size(idx_g1_cols),'logical');
                        req_sex_col=0;
                        if ~reg_match(conf_stat.stratification,'sex') ...
                                && isfield(column_config,'Sex') || isfield(column_config,'sex')
                            idx_sex_cols=column_find(temp_column_names, '^sex_', 1);
                            req_sex_col=2;
                        end

                        assert(nnz(idx_g1_cols)==2,'should only find %s with sufixes: %s and %s', ...
                            column_config.group1, pairwise_keywords.reference, pairwise_keywords.compare)
                        assert(nnz(idx_sex_cols)==req_sex_col,'should only find sex with sufixes: %s and %s', ...
                            pairwise_keywords.reference, pairwise_keywords.compare);
                        if req_sex_col
                            assert(~any(find(idx_g1_cols)==find(idx_sex_cols)),'%s and sex columns should be unique.', ...
                                column_config.group1);
                        end

                        idx_col_ref=column_find(temp_column_names, sprintf('_%s$',pairwise_keywords.reference), 1);
                        idx_col_comp=column_find(temp_column_names, sprintf('_%s$',pairwise_keywords.compare), 1);
                        % alternate recipe to get idx_cols
                        %col_reg=sprintf('^(%s)_(%s|%s)$',strjoin(statmodel_columns,'|'), ...
                        % pairwise_keywords.reference, pairwise_keywords.compare);
                        %idx_cols=column_find(temp_column_names, col_reg);
                        idx_cols=idx_g1_cols | idx_sex_cols;

                        % simplify the stat-model columns removing the N marking and converting to cell of char.
                        names.pair=cell(1,height(temp_table));
                        %for idx_tmp_r=1:height(temp_table)
                        for idx_col=find(idx_cols)
                            column=temp_table.(idx_col);
                            if ~iscell(column)
                                column=cellstr(column);
                            end
                            column=cellfun(@(x) regexprep(x,'^"(.+)".*$','$1'),column,'uniformoutput',false);
                            %{
OR we just look for '_None$' and regexprep that?
                             % set any Nones to empty cell in hope we
                             % can cheese combination code later.
                             idx_none=reg_match(column,'None');
                             if nnz(idx_none)
                                 column{idx_none}='';
                             end
                            %}
                            temp_table.(idx_col)=column;
                            clear column;
                        end
                        %end
                        clear idx_cols idx_tmp_r idx_col
                        %% set our primary comparison names
                        % order our column indicies to properly hold group
                        % and sex for reference, followed by group and sex
                        % for compare.
                        name_order=[
                            find(idx_g1_cols & idx_col_ref)
                            find(idx_sex_cols & idx_col_ref)
                            find(idx_g1_cols & idx_col_comp)
                            find(idx_sex_cols & idx_col_comp)
                            ];
                        names.pair=join(table2cell(temp_table(:,name_order)),'_');
                        names.pair=cellfun(@(x) regexprep(x,'(_None)',''),names.pair,'uniformoutput',false);

                        %% sort out and sex suffix for the comparison name
                        % conver from logicals to numeric indicies
                        idx_sex_cols=find(idx_sex_cols);
                        % ... want to set this automatically, and not
                        % hard-code.
                        % this should represent the primary compariaon,
                        % and primary+sex comparisons.
                        names.pair_sex_suff=cell(1,height(temp_table));
                        if ~reg_match(conf_stat.stratification,'sex')
                            % Validate that sex cols ar both the same meaning
                            % we're not testing female vs male.
                            diff_1=setdiff( temp_table.(idx_sex_cols(1)), temp_table.(idx_sex_cols(2)) );
                            diff_2=setdiff( temp_table.(idx_sex_cols(2)), temp_table.(idx_sex_cols(1)) );
                            assert(numel(diff_1)==0 && numel(diff_2)==0,'Unexpected test configuration, potential configuration mistake');
                            % Now that we know they're the same we'll just use
                            % the fist sex column.
                            idx_female_comparison=reg_match(temp_table.(idx_sex_cols(1)),'^F(emale)?|W(oman)?');
                            idx_male_comparison=reg_match(temp_table.(idx_sex_cols(1)),'^M(ale)?|M(an)?');
                            idx_nonsex_comparison= ~(idx_female_comparison|idx_male_comparison);
                            names.pair_sex_suff(idx_nonsex_comparison)={''};
                            names.pair_sex_suff(idx_female_comparison)={'Female'};
                            names.pair_sex_suff(idx_male_comparison)={'Male'};
                        else
                            warning('stratify on sex special handling doodly doo!');
                            assert(numel(names.pair_sex_suff)==1,'programmer is getting too complex');
                            if reg_match(names.strat.output,'_F(emale)?|W(oman)?')
                                names.pair_sex_suff{1}='Female';
                            elseif reg_match(names.strat.output,'_M(ale)?|M(an)?')
                                names.pair_sex_suff{1}='Male';
                            else
                            end
                        end
                        % colorbars are not ready to be set yet. each pair gets its own
                        % copy, even though they're normally the same.
                        % We could fiddle faddle and make name arrangements
                        % for all pairs, but since they're the same, and
                        % that is testable, lets defer until we're ready
                        % for each pair worth of slices.
                        names.colorbar.out=sprintf('%s.svg',strjoin(["ColorBar" names.stat_param{idx_stparam}.param],"_"));
                        names.LUT.out=sprintf('%s.txt',strjoin(["LUT" names.stat_param{idx_stparam}.param],"_"));

                    else
                        %% non pairwise naming conventions
                        dirs.scalar_figure_set_metric=fullfile(dirs.scalar_figure_set,contrast);
                        dirs.scalar_figure_set_metric_svg=fullfile(dirs.scalar_figure_set_metric,'svg');

                        assert( exist(dirs.scalar_figure_set_metric_svg,'dir'), 'Missing %s\nProgramers have failed you',dirs.scalar_figure_set_metric_svg);

                        %% TODO: Color bar ?
                        % I think this is the place to add colorbar.
                        % colorbars are re-used and overlap sometimes. To avoid
                        % unnecessary bits, we'll use checksum on the color bars.
                        %
                        % stat-colorbars(pval, cohenF) live in dirs.scalar_complex_figs
                        names.colorbar.in=sprintf('%s.svg',strjoin(["ColorBar" names.stat_param{idx_stparam}.color_table],"_"));
                        names.colorbar.out=sprintf('%s.svg',strjoin(["ColorBar" names.stat_param{idx_stparam}.param],"_"));
                        names.LUT.in=sprintf('%s.txt',strjoin(["LUT" names.stat_param{idx_stparam}.color_table],"_"));
                        names.LUT.out=sprintf('%s.txt',strjoin(["LUT" names.stat_param{idx_stparam}.param],"_"));
                        names.slicer_lookup.in=strjoin([fig_set contrast, struct2cell(names.stat_param{idx_stparam})' 'lookup.txt'],"_");
                        names.slicer_lookup.out=strjoin([{names.strat.output} contrast, names.stat_param{idx_stparam}.param 'lookup.txt'],"_");

                        files.colorbar=fullfile(dirs.scalar_complex_figs, names.colorbar.in);
                        files.LUT_file=fullfile(dirs.scalar_complex_figs, names.LUT.in);
                        files.slicer_lookup=fullfile(dirs.scalar_complex_lookup, names.slicer_lookup.in);

                        assert(exist(files.colorbar,'file'));
                        assert(exist(files.LUT_file,'file'));
                        assert(exist(files.slicer_lookup,'file'));

                        %% LUT
                        job_holder=LUT_jobs;
                        in_filepath=files.LUT_file;
                        out_filepath=fullfile(dirs.LUT_out,names.LUT.out);
                        queue_singleton_transfer(job_holder,in_filepath,out_filepath);

                        %% colorbar
                        job_holder=colorbar_jobs;
                        %in_filepath=files.colorbar;
                        out_filepath=fullfile(dirs.colorbar_out,names.colorbar.out);
                        queue_singleton_transfer(job_holder,in_filepath,out_filepath);
                        files.colorbar_out=out_filepath;

                        %% slicer_lookup
                        job_holder=slicer_lookup_jobs;
                        in_filepath=files.slicer_lookup;
                        out_filepath=fullfile(dirs.slicer_lookup_out,names.slicer_lookup.out);
                        queue_singleton_transfer(job_holder,in_filepath,out_filepath);
                        files.slicer_lookup_out=out_filepath;

                        clear job_holder in_filepath out_filepath;
                    end
                    param_pair='UNRESOLVED';
                    for idx_pair=1:numel(names.pair)
                        names.slice=struct();
%{
sorry this gets confusing, this is how I control for: 
  "outparam", "outparamfemale", and "outparammale"
when it should be outparamfemale and/or outparammale, and we'll have
outparam as well,  opts bool opts.pairwise_sex_separate_combined==true will
separate the sex-combined pariwise comparisons into their own directory.
eg, when true AND you have sex-separated pairwise, you'll have 
cohenD/cohenD/(slice_files 1..4)
cohenD/cohenDFemale/(slice files 1..4)
cohenD/cohenDMale/(slice files 1..4)
Otherwise, when false and you have sex separated pairwise, you'll have
cohenD/(slice_files 1..4)
cohenD/cohenDFemale/(slice files 1..4)
cohenD/cohenDMale/(slice files 1..4)
%}         
                        if numel(names.pair)==1
                            % only outparam (for pairwise when not
                            % include_pairwise_sex)
                            %stat_f=names.strat.output;
                            param_pair=names.stat_param{idx_stparam}.param;
                            if reg_match(conf_stat.stratification,'Sex')
                                %stat_f=strep(stat_f,['_' names.pair_sex_suff{idx_pair} ],'');
                                param_pair=sprintf('%s%s', names.stat_param{idx_stparam}.param, names.pair_sex_suff{idx_pair});
                            end
                            dirs.slice_out=[
                                {dirs.contrast_out}
                                param_pair
                                ];
                        else
                            % outparam with include_pairwise_sex
                            param_pair=sprintf('%s%s', names.stat_param{idx_stparam}.param, names.pair_sex_suff{idx_pair});
                            dirs.slice_out=[
                                {dirs.contrast_out}
                                names.stat_param{idx_stparam}.param
                                ];

                            if opts.pairwise_sex_separate_combined || ~isempty(names.pair_sex_suff{idx_pair})
                                % i dont know if there will be other times
                                % when the pairwise comparisons deserve a
                                % suffix. Sex is the only time i can forsee
                                % at the moment.
                                dirs.slice_out=[ dirs.slice_out; param_pair ];
                            end
                        end
                        if names.pairwise
                            % for pairwise comparisons.
                            % sex-stratification name optimization.
                            % result is that no matter what test we did,
                            % cohenDFemale will always be cohenDFemale.
                            % (same for male).
                            stat_f=names.strat.output;
                            if reg_match(conf_stat.stratification,'Sex')
                                stat_f=strrep(stat_f,['_' names.pair_sex_suff{idx_pair} ],'');
                            end
                            % volume_mm3_cohenD_WILD_F_HET_F_slice_M1p98
                            names.slice.in_t=[
                                contrast
                                names.stat_param{idx_stparam}.param
                                names.pair(idx_pair)
                                'slice'];
                            names.slice.out_t=[
                                {stat_f}
                                contrast
                                param_pair
                                ];

                            %% TODO: LUT, colorbar, slicer_lookup?
                            names.colorbar.in=sprintf('%s.svg',strjoin(["ColorBar" names.stat_param{idx_stparam}.color_table, names.pair(idx_pair) ],"_"));
                            names.LUT.in=sprintf('%s.txt',strjoin(["LUT" names.stat_param{idx_stparam}.color_table, names.pair(idx_pair) ],"_"));

                            names.slicer_lookup.in=strjoin([ contrast, names.stat_param{idx_stparam}.param names.pair(idx_pair) 'lookup.txt'],"_");
                            %names.slicer_lookup.out=strjoin([{names.strat.output} contrast, sprintf('%s%s', names.stat_param{idx_stparam}.param, names.pair_sex_suff{idx_pair}) 'lookup.txt'],"_");
                            names.slicer_lookup.out=strjoin([{names.strat.output} contrast, param_pair, 'lookup.txt'],"_");
                            %names.stat_param{idx_stparam}.param, names.pair_sex_suff{idx_pair})

                            files.colorbar=fullfile(dirs.scalar_complex_set_colorbar, names.colorbar.in);
                            files.LUT_file=fullfile(dirs.scalar_complex_set_colorbar, names.LUT.in);
                            files.slicer_lookup=fullfile(dirs.scalar_complex_lookup, names.slicer_lookup.in);

                            assert(exist(files.colorbar,'file'),'no %s in %s',names.colorbar.in,dirs.scalar_complex_set_colorbar);
                            assert(exist(files.LUT_file,'file'),'no %s in %s',names.LUT.in,dirs.scalar_complex_set_colorbar);
                            assert(exist(files.slicer_lookup,'file'),'no %s in %s',names.slicer_lookup.in,dirs.scalar_complex_lookup );

                            %% LUT
                            job_holder=LUT_jobs;
                            in_filepath=files.LUT_file;
                            out_filepath=fullfile(dirs.LUT_out,names.LUT.out);
                            queue_singleton_transfer(job_holder,in_filepath,out_filepath);

                            %% colorbar
                            job_holder=colorbar_jobs;
                            %in_filepath=files.colorbar;
                            out_filepath=fullfile(dirs.colorbar_out,names.colorbar.out);
                            queue_singleton_transfer(job_holder,in_filepath,out_filepath);
                            files.colorbar_out=out_filepath;

                            %% slicer_lookup
                            job_holder=slicer_lookup_jobs;
                            in_filepath=files.slicer_lookup;
                            out_filepath=fullfile(dirs.slicer_lookup_out,names.slicer_lookup.out);
                            queue_singleton_transfer(job_holder,in_filepath,out_filepath);
                            files.slicer_lookup_out=out_filepath;
                            
                            clear job_holder in_filepath out_filepath;
                        else
                            % for outpuTs of the statistical test, pval, pval_BH
                            % and cohenF
                            %% effect distribution
                            names.effect_distribution=sprintf('%s_%s_CohenF.svg', fig_set, contrast);
                            files.effect_distribution=fullfile(dirs.scalar_figure_set_metric_svg, names.effect_distribution);

                            in_filepath=files.effect_distribution;

                            %out_name=sprintf('%s_%s_%s_CohenF.svg',names.strat.output, fig_set, contrast);
                            out_name=sprintf('%s_%s_CohenF_%s.svg', contrast, fig_set, names.strat.output);

                            


                            out_filepath=fullfile(dirs.effect_distribution_out,out_name);
                            update_file(in_filepath,out_filepath,log_inkey,log_outkey);
                            files.effect_out.(contrast)=out_filepath;

                            clear in_filepath out_name out_filepath;
                            %% slice name template in and out set 
                            % (does not include the offset suffix yet)
                            % Using array concatenation while forcing
                            % one element to be a cell to better control
                            % output as a 1-D cell array. Ensusing I dont
                            % accidentiall get a 1-D cell of mixed cells or
                            % char-arrays.
                            names.slice.in_t=[
                                {fig_set}
                                contrast
                                names.stat_param{idx_stparam}.param
                                names.stat_param{idx_stparam}.color_table
                                'slice'];
                            % actual
                            % 'Genotype_volume_mm3_pval_BH_pvalue_extended_slice_M4p88.svg'
                            % proposal param first
                            % 02month_ad_mean_cohend_M1p98.svg
                            % proposal slice first
                            % CohenD_ad_mean_02month_M1p98.svg
                            names.slice.out_t=[
                                {names.strat.output}
                                contrast
                                names.stat_param{idx_stparam}.param
                                ];
                        end
                        % param_pair
                        % scalar_metrics.List(idx_selected_contrasts)
                        %{names.fig_dirs{:} vertcat(names.stat_param{:}).param}
                        % resetting every chance we get is not really
                        % necessary, but this is easier than
                        % pre-calculating. We'll may make use of this at
                        % the end of the stratification.
                        names.output_types.(param_pair)=dirs.slice_out;

                        files.slice_out=struct();
                        for slice_lvl=scalar_complex_fig_slice_levels(selected_slices)
                            names.slice.in=sprintf('%s.svg', strjoin([names.slice.in_t; slice_lvl],'_'));
                            names.slice.out=sprintf('%s.svg', strjoin([names.slice.out_t; slice_lvl],'_'));
                            if ~exist(fullfile(dirs.slice_out{:}),'dir')
                                mkdir(fullfile(dirs.slice_out{:}))
                            end
                            files.slice=char(fullfile(dirs.scalar_complex_metric_svg, names.slice.in));
                            files.slice_out.(uncell(slice_lvl))=fullfile(dirs.slice_out{:},names.slice.out);
                            
                            slice_ok=exist(files.slice,'file');
                            if slice_ok
                                %% copy with replicate logging
                                update_file(files.slice,files.slice_out.(uncell(slice_lvl)),log_inkey,log_outkey);
                            elseif ~opts.abort_on_missing
                                m_struct=missing_template_struct;
                                m_struct.erode=names.erode;
                                m_struct.stratification=names.strat.output;
                                m_struct.contrast=contrast;
                                m_struct.stat_param=names.slice.out_t{3};
                                m_struct.slice_num=uncell(slice_lvl);
                                m_struct.in_name=names.slice.in;
                                m_struct.out_name=names.slice.out;
                                m_struct.in_file=files.slice;
                                m_struct.out_file=files.slice_out.(m_struct.slice_num);
                                log_missing(m_struct.in_file)=m_struct;
                            else
                                error('Missing %s\nProgramers have failed you',files.slice);
                            end                            
                        end
                        %% TODO: get the ontology some place and how.

                        %% TODO: write helpful html for this  MRH-measure, stat-param(pairsuffix),
                        % glorp! what are my html inputs?
                        % title
                        % heading info
                        % slices
                        % colorbar
                        % html-out-location
                                               
                        % slice-out is a multi-part cell array where the
                        % final element is specific to different types of
                        % stat param/pairwise combos.
                        %names.htm=sprintf('%s_%s',contrast, dirs.slice_out{end});
                        %names.html=sprintf('%s.htm',names.htm);
                        names.html=sprintf('%s_%s.htm',contrast, dirs.slice_out{end});
                        out_filepath=fullfile(dirs.contrast_out,names.html);
                        htm_conf=struct( ...
                            'type', 'slice',...
                            'stratification', names.strat.output, ...
                            'contrast', contrast, ...
                            'column_name', names.stat_param{idx_stparam}.param, ...
                            'column_variant', param_pair, ...
                            'color_table_type', names.stat_param{idx_stparam}.color_table, ...
                            'output', out_filepath,...
                            'slices', files.slice_out, ... 
                            'colorbar', files.colorbar_out );
                        
                        assert( not( files.html_out.isKey(out_filepath)  ) , 'output collision some how, programmer needs to gig gud');
                        files.html_out(out_filepath) = htm_conf;
                                                 
                        % simple-html-generator ... bla bla bla files.slice_out

                    end
                end
            end
            
            %% TODO: write effect-distribution html
            if numel( fieldnames(files.effect_out) )
                % files.effect_out.contrast

                names.html=sprintf('%s_distribution.htm', dirs.slice_out{end});
                out_filepath=fullfile(dirs.summary_out, names.html);
                htm_conf=struct( ...
                    'type', 'effect_distribution',...
                    'stratification', names.strat.output, ...
                    'column_name', names.stat_param{idx_stparam}.param, ...
                    'color_table_type', names.stat_param{idx_stparam}.color_table, ...
                    'output', out_filepath, ...
                    'summary_sov', files.significant_graph_sov_out, ...
                    'summary_contrast', files.significant_graph_contrast_out, ...
                    'effects', files.effect_out );

                assert( not( files.html_out.isKey(out_filepath)  ) , 'output collision some how, programmer needs to gig gud');
                files.html_out(out_filepath) = htm_conf;

                clear out_filepath;
            end

        end

        %% TODO: for each stratification, write helpful html
        names.html=sprintf('%s_statistical_view.htm', names.strat.output);
        out_filepath=fullfile(dirs.stratification_out, names.html);
        htm_conf=struct( ...
            'type', 'statistical_view',...
            'stratification', names.strat.output, ...
            'contrasts', scalar_metrics.List(idx_selected_contrasts), ...
            'out_types', names.output_types, ...
            'output', out_filepath );

        assert( not( files.html_out.isKey(out_filepath)  ) , 'output collision some how, programmer needs to gig gud');
        files.html_out(out_filepath) = htm_conf;

        clear out_filepath;
    end
end
clear m_struct;

%% transfer all the colorbars, luts,  and slicer lookups
processFigures(LUT_jobs,slicer_lookup_jobs,colorbar_jobs,log_inkey,log_outkey)

%% Create actual HTML Pages
generateHtmlPages(files)

%% Setup and Create Output Log
%% change log output position when there is only one stratification element
if 1 == numel(names.erode_dirs) ...
        && 1 == numel(names.stratification)
    files.log_out=fullfile(opts.statsViewDir, names.strat.output, ...
        sprintf('%stransfer_%s_%s.log', hidden_dot, names.config_dated, names.strat.output) );
    % mat log, only used when there is an error.
    files.log_out_mat=fullfile(opts.statsViewDir, names.strat.output, ...
        sprintf('transfer_err_%s_%s.mat', names.config_dated, names.strat.output) );
end
%% go through the missing log
if ~opts.abort_on_missing
    ms=log_missing.values;
    missing_table=struct2table(vertcat(ms{:}));
    disp(missing_table);
    pause(15);
end

createOutputLog(files,opts,log_outkey,log_inkey)
end














