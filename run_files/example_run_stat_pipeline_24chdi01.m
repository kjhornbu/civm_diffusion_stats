close all;
clear variables;

%% Preliminaries
BD='B:\ProjectSpace\hmm56\Projects\';
HOME_DIR=BD;
studyID='24.chdi.01';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir,'google_sheet_caps', '24.chdi.01 - MRI record for phase II-2025-09-08.tsv');
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_',char(datetime('today')),'.txt'));
dataframe_path=fullfile(project_dir, [studyID '_DataFrame_Windows_20250917.txt']);
% if empty string, script will make you a new setup file
% or, pass it an existing one
setup_file='';

polished_sheets=fullfile(project_dir,'polished_sheets');
% point this to somewhere else
project_research_archive=fullfile('A:/',studyID,'research');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Harrison Mansour ';
save_dir=fullfile(project_dir,'stats_20250917_TestScalarConnectomev2');

%% uncomment to allow which part of pipeline desired to run. 
%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats

optional_suffix=false;
suffix='';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);