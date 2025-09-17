close all
clear variables;

%% Preliminaries
BD='Z:/All_Staff';
HOME_DIR=BD;
studyID='20.5xFAD.02';
project_dir=fullfile(HOME_DIR,studyID);
%google_doc=fullfile(project_dir,'google_sheet_caps', '20.5XFAD.01-MRIScanSheet_phase2_2025_08_20.tsv');
%google_doc=fullfile(project_dir, [studyID
%'_DataFrame_Combined_20250829.txt']);  -- First neeed to get phase1 and
%phase 2 as parts to then combine the dataframes together given 2 different
%project codes
google_doc="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_combined_',char(datetime('today')),'.txt'));
dataframe_path="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
setup_file="Z:\All_Staff\20.5xFAD.02\stats_Combined_P1P2_from205xFAD02_20250908_strainstraified_zscore\20.5xFAD.02_DataFrame_Combined_20250908_setup.mat";
polished_sheets=fullfile(project_dir,'polished_sheets');

%For polishing this looks in these two possible locations to pull the data
%first starting on the {1} then moving to the {2}
project_research_archive{1}=fullfile('A:/','20.5xFAD.02','research');
project_research_archive{2}=fullfile('A:/','20.5xFAD.01','research');

atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg';
save_dir=fullfile(project_dir,'test_0910');

%% uncomment to allow which part of pipeline desired to run. 
%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats
which_tests=list2cell('Connectome'); %does only connectome stats

%These suffixes specify which version of stat files to load from the
%archive both at polishing and later on.
optional_suffix=true;
suffix='GMDT';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix)