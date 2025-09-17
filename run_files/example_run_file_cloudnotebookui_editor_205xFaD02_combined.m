close all
clear all

%% Preliminaries
BD='Z:/All_Staff';
HOME_DIR=BD;
studyID='20.5xFAD.02';
project_dir=fullfile(HOME_DIR,studyID);
%google_doc=fullfile(project_dir,'google_sheet_caps', '20.5XFAD.01-MRIScanSheet_phase2_2025_08_20.tsv');
%google_doc=fullfile(project_dir, [studyID '_DataFrame_Combined_20250829.txt']);
google_doc="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_combined_',date,'.txt'));
dataframe_path="Z:\All_Staff\20.5xFAD.02\20.5xFAD.02_DataFrame_Combined_20250904_ChangedGenotypeGroups.txt";
setup_file="Z:\All_Staff\20.5xFAD.02\stats_Combined_Phase1Phase2_from205xFAD02_20250908_olddataframe_withoutPhaseScanner_as_Effects\20.5xFAD.02_DataFrame_Combined_20250908_setup.mat";
polished_sheets=fullfile(project_dir,'polished_sheets');
project_research_archive{1}=fullfile('A:/','20.5xFAD.02','research');
project_research_archive{2}=fullfile('A:/','20.5xFAD.01','research');
atlas_ontology_path=fullfile('C:/workstation/','static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg';
save_dir=fullfile(project_dir,'stats_Combined_Phase1Phase2_from205xFAD02_20250908_olddataframe_withoutPhaseScanner_as_Effects');

%Add Path Blocks
addpath('C:/workstation/code/analysis/Scalar_Analysis')
addpath('C:/workstation/code/analysis/Scalar_Analysis_Plotting')
addpath('C:/workstation/code/analysis/Omni_Manova')
addpath('Z:/All_Staff/civm_diffusion_stats')
addpath('C:/workstation/code/shared/civm_matlab_common_utils/file')

%which_tests=list2cell('Scalar'); %does only scalar stats
%which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats
which_tests=list2cell('Connectome'); %does only connectome stats

optional_suffix=true;
suffix='GMDT';

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix)