close all
clear variables;

%% Preliminaries
BD='Z:/All_Staff';
HOME_DIR=BD;
studyID='24.niehs.01';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir, [studyID '_DataFrame_20250903_WindowsPaths.txt']);
cleaned_google_doc_path=fullfile(project_dir, [studyID '_DataFrame_20250903_WindowsPaths.txt']);
dataframe_path=fullfile(project_dir, [studyID '_DataFrame_20250903_WindowsPaths.txt']);
setup_file='Z:/All_Staff/24.niehs.01/stats_20250903_WindowsVersionTest/24.niehs.01_DataFrame_20250829_setup.mat';
polished_sheets=fullfile(project_dir,'polished_sheets');
project_research_archive=fullfile('A:/','24.niehs.01','research');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'stats_20250903_WindowsVersionTest');


%% uncomment to allow which part of pipeline desired to run. 
%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats

optional_suffix=false;
suffix='';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);
