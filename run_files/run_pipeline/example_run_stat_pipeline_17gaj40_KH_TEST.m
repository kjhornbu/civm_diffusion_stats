close all;
clear variables;

%% Preliminaries
studyID='17.gaj.40';
project_dir='B:\17.gaj.40';
%google_doc="Z:\All_Staff\17.gaj.40\google_sheet_captures\17.gaj.40_20260327.tsv";
google_doc="Z:\All_Staff\17.gaj.40\google_sheet_captures\17.gaj.40-20260327.txt";
cleaned_google_doc_path=fullfile('Z:\All_Staff\17.gaj.40','google_sheet_captures','Edited_B6_D2_Mice_Sheet30-Mar-2026.txt');
%if the day has changed since you ran this you want to make sure you set this to the fixed path!!!

dataframe_path=fullfile(project_dir, ['17gaj40_DataFrame_Windows_ProtocolSheet_',char(datetime('today')),'.txt']);

% if empty string, script will make you a new setup file
% or, pass it an existing one
config_file='';

polished_sheets=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved
% point this to somewhere else if you are working from some local drive
% etc... 

project_research_archive{1}=fullfile('A:/',studyID,'research');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 
statSaveDir=fullfile(project_dir,'TESTv2_D2_v_B6');

studyParams={
  studyID,...
  statSaveDir,...
  'configFile',config_file,...
  'dataframePath',dataframe_path,...
  'googleDocPath',google_doc,...
  'cleanedGoogleDocPath',cleaned_google_doc_path,...
  'researchArchivePath',project_research_archive,...
  'polishedSheetPath',polished_sheets,...
  'suffix','RCCF',...
};

%civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,config_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);

civm_diffusion_stats(studyParams{:});
