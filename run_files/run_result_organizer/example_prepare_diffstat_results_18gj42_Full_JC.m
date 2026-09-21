% helper clutter reduction structs
dirs=struct;
files=struct;
names=struct;
%%
studyID='18.gaj.42';

% these are special inputs to prepare_diffstat_results to help with path
% adjustments. base_path_old is the start of paths encoded in the config file, base_path_new is how
% you want that replaced. In both cases simple string replacement is used.
dirs.stats_main_previous='Z:\';
dirs.stats_main_current='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60';

% stat stratification dir of interest
% somehow should only transfer this one.
% also, do not want sex pair-wise as we'll re-handle those later with pvalues.
dirs.strat='Z:\All_Staff\18.gaj.42\FullAnalysis_20260505\Scalar_and_Volume\anovan_10000100001000011010\AgeClass_Strain_Sex_Perfusionat\Non_Erode\Bilateral';
dirs.strat=file_basepath_swap(dirs.strat,dirs.stats_main_previous,dirs.stats_main_current);

% this will be used as the stratification_output_name.
% This is set for ONE part of stratification! If there will be more than
% one (eg for Female/Male stratifcations) this must include an appropriate
% place holder. Eg, for Female/Male %s should be included 'something_%s'
% would give "something_Female", "something_Male". 
% 
% This is NOT perfect.
names.experiment='BxD_3mo-vs-14mo';
names.study_column='Age_Class';
% Where is the stat directory for our input config file. Not used directly.
% Study models: 
% Main only:  dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260505';
% Two Limited interaction models available.  
% First Age by Sex:  dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260505';
% Second Age By Strain:  dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260514';
% Choosing the main effects & age by sex.
dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260505';
%dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260514';
%dirs.stat_out='Z:\All_Staff\18.gaj.42\FullAnalysis_20260514_Stratified';
dirs.stat_out=file_basepath_swap(dirs.stat_out,dirs.stats_main_previous,dirs.stats_main_current);

%% Look through the configs available.
% What am I looking for? 
% I guess, i want to add study model to the directory info and show that to myself. 
stat_out_items=dir(dirs.stat_out);
time_reg='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{4}';
setup_reg=sprintf('.*_setup(_%s)?[.]mat$',time_reg);
setup_opts_reg=sprintf('.*_setup_opts(_%s)?[.]mat$',time_reg);
setup_idx=false(1,height(stat_out_items));
for item_idx=1:numel(stat_out_items)

    item=stat_out_items(item_idx);
    if reg_match(item.name,setup_reg)
        setup_idx(item_idx)=true;
        mf=matfile( fullfile(item.folder,item.name) );

        mf_conf=mf.configuration_struct;
        mf_pair=mf.pairwise_criteria;
                
        % heading is model parameters.
        model_params=mf_conf.model_table.Properties.VariableNames;
        Sources=cell(1,height(mf_conf.model_table));
        for idx_t=1:height(mf_conf.model_table)
            interaction_idx=table2array(mf_conf.model_table(idx_t,:));
            SoV=model_params(interaction_idx);
            Sources{idx_t}=strjoin(SoV,':');
        end
        study_model=strjoin(Sources,'+');

        stat_out_items(item_idx).study_model=study_model;
        
    elseif reg_match(item.name,setup_opts_reg)
        % ... not useful
        mf=matfile( fullfile(item.folder,item.name) );
        mf_opts=mf.opts;
    end
end
available_configs=column_reorder(struct2table(stat_out_items(setup_idx)), list2cell('study_model date name'));
clear stat_out_items time_reg setup_reg setup_opts_reg setup_idx item_idx item mf mf_conf mf_pair mf_opts model_params Sources idx_t interaction_idx SoV study_model;
disp(available_configs);
%%
%%%
% This config is main-effects only. Model = 'Age_Class+Strain+Perfusion_at+Sex'
names.config='18.gaj.42_DataFrame_noB6_20260224_setup_2026-05-05T0938.mat';
%
% This config has main-effects & age:sex interaction. Model = 'Age_Class+Strain+Sex+Perfusion_at+Age_Class:Sex'
%names.config='18.gaj.42_DataFrame_noB6_20260224_setup_2026-05-05T1208.mat';
%
% This config main-effects age+sex only. Model = 'Age_Class+Sex'
%names.config='18.gaj.42_DataFrame_noB6_20260224_setup.mat';
%%%

% this is the input we require.
files.config=fullfile(dirs.stat_out,names.config);
% Adding bonus complex figures.
%dirs.additonal_complex_figures={'\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\18.gaj.42\FullAnalysis_20260514_Stratified\Scalar_and_Volume\anovan_100010001\AgeClass_Strain_Sex_Perfusionat\Non_Erode\Bilateral_BXD51\complex_figures_TEST_EstimatedPower-260707'};
% dirs.additonal_complex_figures={'STRATIFICATION_DIR\complex_figures_TEST_EstimatedPower-260707'};
dirs.additonal_complex_figures={'STRATIFICATION_DIR\complex_figures_EstimatedPower-260709_FromCohenF'};
dirs.statistical_view=fullfile('B:',studyID,'statistical_view');

%files.dataframe='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\18.gaj.42\18.gaj.42_DataFrame_noB6_20260224v2_2026-04-01T1605.txt';
files.override_scalar_paths='\\duhsnas-pri.dhe.duke.edu\dusom_civm-kjh60\All_Staff\18.gaj.42\FullAnalysis_20260505\18.gaj.42_DataFrame_noB6_20260224_setup_Scalar_Sheet_Paths.csv';

%%
%dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',studyID,'statistical_view_TESTVERSION6a'));
dirs.statistical_view_test=uncell(fullfile(getenv('BIGGUS_DISKUS'),'test',studyID,'statistical_view_TESTVERSION7'));
if ~exist(dirs.statistical_view_test,'dir')
    mkdir(dirs.statistical_view_test);
end

%{
%}
prepare_diffstat_results(dirs.statistical_view_test, files.config, ...
    'stratification_output_name', names.experiment, ... what is the name pattern for our stratifications
    'primary_study_column',names.study_column, ... If there is more than one group column (indicating primary study element), which one will we be organizing? We only support one at a time! This column name SHOULD be in reference to the name of this experiement!
    'include_pairwise_sex', false,  ... default true, set this to false to omit pairwise primary study condition separated by sex.
    'include_subject_table', true, ... default true, set this to false to prevent copying full subject table. Useful when we re-run stratifications from same subject table.
    'stats_main_previous', dirs.stats_main_previous,... required when we move data
    'stats_main_current', dirs.stats_main_current, ... required when we move data
    'additional_complex_figures', dirs.additonal_complex_figures, ... 'A cell of char-array holding folder paths. If we have more complex figure run into an alternate folder, this is how we can find them.
    'complex_pairwise', {'+estimated_power_WN'},... 
    'guess_scalar_paths', true, ... default false, if scalar paths sheet has been lost, this will not use it, and will instead use hard-coded formula to get info.
    'hide_transfer_log',true ...  default true, set this to false to avoid setting hidden attribute (and dot prefix) on transfer.log
    );

