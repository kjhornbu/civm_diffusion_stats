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
names.experiment='14Month_nTg-vs-5xFAD';
% Where is our input config file. Not used directly.
dirs.stat_out='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\26.5xFAD.04\Analysis_20260618_AgeStratified';
% this is the input we require.
files.config=fullfile(dirs.stat_out,'26.5xFAD.04_DataFrame_20260618_PostSAMBA_PreAlign_BothPhase_setup.mat');
dirs.additonal_complex_figures={'STRATIFICATION_DIR\complex_figures_TEST_EstimatedPower-260714'};
dirs.statistical_view=fullfile('B:',studyID,'statistical_view');

% these are special inputs to prepare_diffstat_results to help with path
% adjustments. base_path_old is the start of paths encoded in the config file, base_path_new is how
% you want that replaced. In both cases simple string replacement is used.
dirs.stats_main_previous='Z:\';
dirs.stats_main_current='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60';

%%
% stat stratification dir of interest
% somehow should only transfer this one.
% also, do not want sex pair-wise as we'll re-handle those later with pvalues.
dirs.strat= '\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\26.5xFAD.04\Analysis_20260618_AgeStratified\Scalar_and_Volume\anovan_1000001000001000001000001\Genotype_AgeGroup_Strain_Sex_scannerconsole_amplifier\Non_Erode\Bilateral_geriatric';


%%
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',studyID,'statistical_view_TESTVERSION6'));
%dirs.statistical_view_test=uncell(fullfile('Z:\All_Staff\26.5xFAD.04','test',studyID,'statistical_view_TESTVERSION'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end


prepare_diffstat_results(dirs.statistical_view_test, files.config, ...
    'stratification_output_name', names.experiment, ... what is the name pattern for our stratifications
    'stratification_selection','geriatric', ... if we have stratification, but we only want some of the stratification components, this is how we limit it
    'include_pairwise_sex', false,  ... default true, set this to false to omit pairwise primary study condition separated by sex.
    'stats_main_previous', dirs.stats_main_previous,... required when we move data
    'stats_main_current', dirs.stats_main_current, ... required when we move data
    'additional_complex_figures', dirs.additonal_complex_figures, ... 'A cell of char-array holding folder paths. If we have more complex figure run into an alternate folder, this is how we can find them.
    'complex_pairwise', {'+estimated_power_WN'},... 
    'hide_transfer_log',true ...  default true, set this to false to avoid setting hidden attribute (and dot prefix) on transfer.log
    );

