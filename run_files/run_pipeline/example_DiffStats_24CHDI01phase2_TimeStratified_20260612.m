%% init helpers vars
% structs to reduce clutter in workspace.
% Will hold the many files/folders we'll set, also names for folders/dirs and datees
% This facilitates mass uncell, and/or mkdir.
dates=struct; 
names=struct; % these are usually defined first.
dirs=struct; % then all the directories are defined
files=struct; % finally files which probably dont exist yet are defined in those dirs.

%% base project and data definition
project_code={'24.chdi.01'};
studySuffix={'-phase2'};
stratID={};
dates.download={'2026-06-12'};
dates.clean=dates.download;
dates.process=dates.clean;
%names.google_cap=sprintf('%s_%s_%s.txt',studyID,stratID,downloadDate);
names.google_cap='24.chdi.01 - MRI record for Phase II_2026-06-12.tsv';
names.google_cap='24.chdi.01 - MRI record for Phase II_fixed_2026-06-12.tsv';

%% setting dirs
% This would need to change if processing on mac/linux. whatabout our old
% friend wks_settings? (eg, w_set=wks_settings();
names.study_dir=strjoin([project_code,studySuffix],'');
dirs.project=fullfile('b:',names.study_dir);
% kinda-sorta semi-inputs
dirs.work=fullfile(dirs.project,'work');
dirs.cap=fullfile(dirs.work,'google_sheet_caps');
dirs.polished=fullfile(dirs.work,'polished_stats'); %where the polished sheets will be saved 
% kinda-sorta semi-output
dirs.stats=fullfile(dirs.work,'stats');
%%%%%
% Not sure I like setting stat output like this, feels like we're getting
% pretty redundant for naming.
% What if instead we used something about the planned stat model or purpose?
names.stats_run=[stratID dates.process];
% What if instead we used something about the planned stat model or purpose?
% names.stats_run=list2cell('FullByMonth');
% In this example, full my month and sex is kinda silly as the only thing
% left is the primary test condition.
% names.stats_run=list2cell('FullByMonthSex');
%%%%%
dirs.stats_out=fullfile(dirs.stats,strjoin(names.stats_run,'_'));
dirs.statistical_view=fullfile(dirs.project,'statistical_views');

files.doc=fullfile(dirs.cap,names.google_cap);
% formulaic when using stratification
% names.doc_cleaned=[studyID, stratID, 'cleaned', cleanDate];
%files.doc_cleaned=fullfile(dirs.stats_out,sprintf('%s.txt',strjoin(names.doc_cleaned,'_')));
% simplistiy+cleaned when not.
[~,names.doc_cleaned]=fileparts(names.google_cap);
names.doc_cleaned={names.doc_cleaned,'cleaned'};
files.doc_cleaned=fullfile(dirs.cap,sprintf('%s.txt',strjoin(names.doc_cleaned,'_')));
names.frame=[project_code,stratID,'DataFrame',dates.process];
files.frame=fullfile(dirs.stats_out,sprintf('%s.txt',strjoin(names.frame,'_')));
files.stat_config='';
%% semi-static dir/file entries
dirs.archive{1}=fullfile('A:/',project_code,'research');
files.ontology_atlas=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 
%% validate existing elements which must exist to start.
% These validations **could** be the responsibility of civm_diffusion_stats.
assert(exist(files.doc,'file'),'missing google doc %s',files.doc);
assert(~strcmp(files.doc,files.doc_cleaned),'cleaned doc should be different than input');
assert(~strcmp(files.doc_cleaned,files.frame),'cleaned doc should be different than input');
%% uncell for all fields of dirs and files
% Maybe we should do mkdirs here? What should the existing dir assumptions be?
S=dirs;
list=fieldnames(S);
for i=1:numel(list)
    S.(list{i})=uncell(S.(list{i}));
end
dirs=S;
S=files;
list=fieldnames(S);
for i=1:numel(list)
    S.(list{i})=uncell(S.(list{i}));
end
files=S;
clear S list i;
%% bundle opts into super cell to be less ugly. 
% Chains set to scalar only right now.
analysis_chains={'Scalar'};
% analysis_chains={'Scalar','connectome'};
studyParams={
  uncell(project_code),...
  dirs.stats_out,...
  'configFile',files.stat_config,...
  'analysisPipeline', analysis_chains,...
  'googleDocPath',files.doc,...
  'cleanedGoogleDocPath',files.doc_cleaned,...
  'dataframePath',files.frame,...
  'overrideLabelLUT',files.ontology_atlas,...
  'researchArchivePath',dirs.archive,...
  'polishedSheetPath',dirs.polished,...
  'assumeNLSAM',true, ...
  'allowMissing',true};
%% Run civm_diffusion_stats (update files.config)
files.stat_config=civm_diffusion_stats(studyParams{:});
%% Prepare output statistical views
% test_dir before we're ready to reveal
w_settings=wks_settings();
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',names.study_dir,'statistical_view_TESTVERSION2'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end
%prepare_diffstat_results(dirs.statistical_view_test, files.stat_config, ...
%    'stratification_output_name','%02iMonth_zQ175DN', ...
%    'contrast_limit', list2cell('fa_mean volume_fraction'));
prepare_diffstat_results(dirs.statistical_view_test, files.stat_config, ...
    'stratification_output_name','%02iMonth_zQ175DN', ...
    'slice_selection', [1, 3, 4],...
    'pairwise_sex_separate_combined',true );

% correct output
% prepare_diffstat_results(dirs.statistical_view, files.stat_config, ...
%     'stratification_output_name','%02iMonth_zQ175DN', ...
%     'contrast_limit', list2cell('fa_mean volume_fraction'));

