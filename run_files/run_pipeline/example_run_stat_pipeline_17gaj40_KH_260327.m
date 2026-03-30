close all;
clear variables;

%% Preliminaries
studyID='17.gaj.40';
project_dir='B:\17.gaj.40';
google_doc="Z:\All_Staff\17.gaj.40\google_sheet_captures\17.gaj.40_20260327.tsv";
cleaned_google_doc_path=fullfile('Z:\All_Staff\17.gaj.40','google_sheet_captures',strcat('Edited_B6_D2_Mice_Sheet',char(datetime('today')),'.txt'));
%if the day has changed since you ran this you want to make sure you set this to the fixed path!!!

dataframe_path=fullfile(project_dir, ['17gaj40_DataFrame_Windows_ProtocolSheet_',char(datetime('today')),'.txt']);

% if empty string, script will make you a new setup file
% or, pass it an existing one
setup_file='';

polished_sheets=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved
% point this to somewhere else if you are working from some local drive
% etc... 
project_research_archive{1}=fullfile('A:/',studyID,'research');

atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'D2_v_B6');

%% uncomment to allow which part of pipeline desired to run. 
%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats

optional_suffix=true;
suffix='RCCF';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);