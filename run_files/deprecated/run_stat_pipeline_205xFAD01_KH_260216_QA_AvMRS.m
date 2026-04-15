close all;
clear variables;

StudyProperties={ "google_doc" "cleaned_google_doc" "dataframe"} "at least one of these is required" "if missing lower level thats fine if have higher"
    
ModelProperties={"config_file"} 

CleanedStats={"project_research_archive" "polished sheet path" }

OutputLocation= save_dir;

OptionalOptions=("studyID" "required",'Override_LabelLUT" PATH, "PvalThreshold", "Pvalcols", "AnalysisPipeline" "isSuffixOptional" "suffix" "Allow Missing" default false}_



%% Preliminaries
studyID='21.QA94TAgilent.01';
project_dir='B:\20.5xfad.02\QA_Studies_Scalar_Stats\Agilent_v_MRS'; %where generally working from

google_doc=fullfile(project_dir,'google_sheet_caps','21QA94TAgilent_20260216_WithWyattNotes_AvM.txt'); % path to specific google doc to use 

cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_From21QA94TAgilent_20260227_WithWyattNotes_AvM.txt'));

%if the day has changed since you ran this you want to make sure you set this to the fixed path!!!
dataframe_path=fullfile(project_dir, ['DataFrame_Windows',char(datetime('today')),'.txt']);

% if empty string, script will make you a new setup file
% or, pass it an existing one
config_file='';

polished_sheet_path=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved
% point this to somewhere else if you are working from some local drive
% etc... 
project_research_archive{1}=fullfile('A:/',studyID,'research'); % Main Agilent QA Folder

%%
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 
%override_lut option

%%
pval_threshold=0.05;
%%
pval_cols=list2cell('pval_BH pval');

user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'Stat_Analysis');

%%

%% uncomment to allow which part of pipeline desired to run. 
%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Connectome'); %does only connectome stats
which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats


%%
optional_suffix=true;
%%
suffix='batchQA';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,config_file, polished_sheet_path,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);