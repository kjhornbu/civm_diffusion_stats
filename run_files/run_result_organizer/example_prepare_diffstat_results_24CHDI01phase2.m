warning('This example requires manual curation to blend two separate directories when done');

% helper clutter reduction structs
dirs=struct;
files=struct;
names=struct;
%%
project_code={'24.chdi.01'};
studySuffix={'-phase2'};
names.study_dir=strjoin([project_code,studySuffix],'');
    %{
Within each Bilateral_Age Folder:
Adjusted_CohenD_ColorRange_2026-08-17_HETWILD_SexSeparated -> M/F (Het v Wild)
      Cohen D threshold: 2
Adjusted_CohenD_ColorRange_2026-08-17_HETWILD -> Het v Wild
      Cohen D threshold: 1.5
    %}

dirs.additonal_complex_figures={'STRATIFICATION_DIR\Adjusted_CohenD_ColorRange_2026-08-17_HETWILD'};

%% Prepare output statistical views
% test_dir before we're ready to reveal
w_settings=wks_settings(wks_settings.default_name(),struct('verbosity',0));
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',names.study_dir,'statistical_view_TESTVERSION7t'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end
files.stat_config='b:\24.chdi.01-phase2\work\stats\2026-06-12\24.chdi.01_DataFrame_2026-06-12_setup.mat';

prepare_diffstat_results( ...
    dirs.statistical_view_test, files.stat_config, ...
    'stratification_output_name', '%02iMonth_zQ175DN', ...
    'include_pairwise_sex', false,  ... default true, set this to false to omit pairwise primary study condition separated by sex.
    'additional_complex_figures', dirs.additonal_complex_figures, ... 'A cell of char-array holding folder paths. If we have more complex figure run into an alternate folder, this is how we can find them.
    'pairwise_sex_separate_combined', false );

%%
%{
'include_subject_table',false,...
'include_group_table',false,...
'include_result_table',false,...
'include_effect_distribution',false,...
'include_significant_summary_table',false,...
'include_summary_presentation',false,...
'include_summary_figures',false,...
%}
dirs.additonal_complex_figures={'STRATIFICATION_DIR\Adjusted_CohenD_ColorRange_2026-08-17_HETWILD_SexSeparated'};
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',names.study_dir,'statistical_view_TESTVERSION7tt'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end
prepare_diffstat_results( ...
    dirs.statistical_view_test, files.stat_config, ...
    'stratification_output_name', '%02iMonth_zQ175DN', ...
    'include_pairwise_sex', true,  ... default true, set this to false to omit pairwise primary study condition separated by sex.
    'only_pairwise_sex', true, ... default false, this allows us to patch in partial dirs later which are only sex stratified pairwise.
    'additional_complex_figures', dirs.additonal_complex_figures, ... 'A cell of char-array holding folder paths. If we have more complex figure run into an alternate folder, this is how we can find them.
    'pairwise_sex_separate_combined', false );


error('manual blending of separately created elements required');