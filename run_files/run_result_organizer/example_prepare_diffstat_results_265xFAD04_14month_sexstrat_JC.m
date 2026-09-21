% helper clutter reduction structs
dirs=struct;
files=struct;
names=struct;
%%
studyID='26.5xFAD.04';
% this will be used as the stratification_output_name.
% This is set for ONE part of stratification! If there will be more than
% one (eg for Female/Male stratifcations) this must include an appropriate
% place holder. Eg, for Female/Male %s should be included 'something_%s'
% would give "something_Female", "something_Male". 
% 
% This is NOT perfect.
names.experiment='14Month_nTg-vs-5xFAD_%s';
% Where is our input config file. Not used directly.
dirs.stat_out='Z:\All_Staff\26.5xFAD.04\Analysis_20260622_14mo';

% this is the input we require.
files.config=fullfile(dirs.stat_out,'26.5xFAD.04_DataFrame_20260622_PostSAMBA_PreAlign_BothPhase-14mo_setup_2026-06-22T1110.mat');
dirs.additonal_complex_figures={'STRATIFICATION_DIR\complex_figures_TEST_EstimatedPower-260714'};
dirs.statistical_view=fullfile('B:',studyID,'statistical_view');

% these are special inputs to prepare_diffstat_results to help with path
% adjustments. stats_main_previous is the start of paths encoded in the config file, stats_main_current is how
% you want that replaced. In both cases simple string replacement is used.
dirs.stats_main_previous='Z:\';
dirs.stats_main_current='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60';
files.config=file_basepath_swap(files.config,dirs.stats_main_previous,dirs.stats_main_current);

%%
% sub-set 14month only subject table for later.
% '\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\26.5xFAD.04\Analysis_20260622_14mo\Scalar_and_Volume\anovan_1000010000100001\Genotype_Sex_Strain_scannerconsole_amplifier\Non_Erode\Subject_Data_Table.csv'

% stat stratification dir of interest
% somehow should only transfer this one.
% also, do not want sex pair-wise as we'll re-handle those later with pvalues.
% dirs.strat= '\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\26.5xFAD.04\Analysis_20260622_14mo\Scalar_and_Volume\anovan_1000010000100001\Genotype_Sex_Strain_scannerconsole_amplifier\Non_Erode\Bilateral_F'
% dirs.strat= '\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\26.5xFAD.04\Analysis_20260622_14mo\Scalar_and_Volume\anovan_1000010000100001\Genotype_Sex_Strain_scannerconsole_amplifier\Non_Erode\Bilateral_M'

%%
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',studyID,'statistical_view_TESTVERSION6'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end

%'stratification_selection','geriatric', ... if we have stratification, but we only want some of the stratification components, this is how we limit it
prepare_diffstat_results(dirs.statistical_view_test, files.config, ...
    'stratification_output_name', names.experiment, ... what is the name pattern for our stratifications
    'guess_scalar_paths', true, ... default false, if scalar paths sheet has been lost, this will let us guess the correct locations using hard-coded formula to get info.
    'include_subject_table', false, ... default true, sometimes we reduce the subject table later, and dont want to re-transfer it.
    'include_pairwise_sex', false,  ... default true, set this to false to omit pairwise primary study condition separated by sex.
    'stats_main_previous', dirs.stats_main_previous,... required when we move data
    'stats_main_current', dirs.stats_main_current, ... required when we move data
    'additional_complex_figures', dirs.additonal_complex_figures, ... 'A cell of char-array holding folder paths. If we have more complex figure run into an alternate folder, this is how we can find them.
    'complex_pairwise', {'+estimated_power_WN'},... 
    'hide_transfer_log',true ...  default true, set this to false to avoid setting hidden attribute (and dot prefix) on transfer.log
    );
