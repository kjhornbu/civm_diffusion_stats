close all;
clear variables;

%% Preliminaries
studyID='24.chdi.01-PHASE2';
project_dir='B:\24.chdi.01-PHASE2\prototype_lightsheet_scalar_stats\';
% full phase 2 record
%google_doc="B:\ProjectSpace\hmm56\Projects\24.chdi.01\google_sheet_caps\24.chdi.01 - MRI record for Phase II-2026-04-14-OnlyOneAge.tsv";
% clean google sheet is what ends up after filrtering for relevant columns and specimens
%cleaned_google_doc_path=fullfile(project_dir,'Edited_24chdi01Phase2_lightsheet_20260415_KH.txt');

statSaveDir=fullfile(project_dir,'All_Together/');
%statSaveDir=fullfile(project_dir,'Test_KH/');

connectomeSuffix="";

%dataframe_path=fullfile(statSaveDir, '24chdi01Phase2_20260414_lightsheet-KH.txt'); % You can have multiple dataframes that are differnent than the edited cloud notebook its a new version
dataframe_path=fullfile(statSaveDir, '24chdi01Phase2_20260414_lightsheet.txt');
config_file='';
polished_sheets=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved
project_research_archive{1}=fullfile('B:/',studyID,'prototype_lightsheet_scalar_stats','raw_stats');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt');

scalarContrast=struct;
scalarContrast(1).Name={'Non_Erode'}; 
scalarContrast(1).Column={'stat_path'};
scalarContrast(1).List=list2cell("NeuN_30um_mean PDE10A_30um_mean MOG_30um_mean");

scalarContrast(2).Name={'Erode'}; 
scalarContrast(2).Column={'stat_path_erode'};
scalarContrast(2).List=list2cell("NeuN_30um_mean PDE10A_30um_mean MOG_30um_mean");

studyParams={
  studyID,...
  statSaveDir,...
  'configFile',config_file,...
  'dataframePath',dataframe_path,... %Just need one file associated as input if you are happy with the dataframe then just use that. 
  'overrideLabelLUT',atlas_ontology_path,...
  'researchArchivePath',project_research_archive,...
  'polishedSheetPath',polished_sheets,...
  'suffix',connectomeSuffix,...
  'allowMissing',true,...
  'scalarContrastMetrics', scalarContrast,...
  'analysisPipelineType', list2cell('Scalar')};

civm_diffusion_stats(studyParams{:});
