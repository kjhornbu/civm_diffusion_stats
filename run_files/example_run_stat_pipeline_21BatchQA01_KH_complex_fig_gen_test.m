close all;
clear variables;

%% Preliminaries
studyID='21.QA94TAgilent.01';
project_dir='Z:\All_Staff\21.BatchQA.01';
google_doc='Z:\All_Staff\21.BatchQA.01\google_sheet_caps\21.QA94TAgilent.01_2025_11_24_OctNov25.txt';
%cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_',char(datetime('today')),'.txt'));
%cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_RM_250317-6_1_',char(datetime('today')),'.txt'));
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_RM_250317-6_1_24-Nov-2025.txt'));
%if the day has changed since you ran this you want to make sure you set this to the fixed path!!!

%dataframe_path=fullfile(project_dir, [studyID '_DataFrame_Windows_',char(datetime('today')),'.txt']);
dataframe_path=fullfile(project_dir, '21.QA94TAgilent.01_DataFrame_Windows_24-Nov-2025.txt');


% if empty string, script will make you a new setup file
% or, pass it an existing one
setup_file='';

polished_sheets=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved
% point this to somewhere else if you are working from some local drive
% etc... 
project_research_archive=fullfile('A:/',studyID,'research');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'ComplexFigGen_Testing_2025_12_11');

%% uncomment to allow which part of pipeline desired to run. 
which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
%which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats

optional_suffix=true;
suffix='batchQA';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);