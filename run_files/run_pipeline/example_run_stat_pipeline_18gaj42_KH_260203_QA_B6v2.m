close all;
clear variables;

%% Preliminaries
studyID='18.gaj.42';
project_dir='Z:\All_Staff\18.gaj.42';
google_doc="Z:\All_Staff\18.gaj.42\google_sheet_captures\YoungB6_From_18gaj42_17gaj40_21QA94TAgilent01_021026.txt";
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_captures',strcat('Edited_GoogleSheet_YoungB6_ProtocolSheet.txt'));
%if the day has changed since you ran this you want to make sure you set this to the fixed path!!!

dataframe_path=fullfile(project_dir, ['YoungB6_From_18gaj42_17gaj40_DataFrame_Windows_ProtocolSheet_',char(datetime('today')),'.txt']);

% if empty string, script will make you a new setup file
% or, pass it an existing one
setup_file='';

polished_sheets=fullfile(project_dir,'polished_sheets_MixedB6s'); %where the polished sheets will be saved
% point this to somewhere else if you are working from some local drive
% etc... 
project_research_archive{1}=fullfile('A:/',studyID,'research');
project_research_archive{2}=fullfile('A:/','17.gaj.40','research'); %Heritability
project_research_archive{3}=fullfile('A:/','21.QA94TAgilent.01','research'); %General QA study

atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'OnlyYoungB6s_Hertability_AgingBXD');

%% uncomment to allow which part of pipeline desired to run. 
which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
%which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats

optional_suffix=true;
suffix='RCCF';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);