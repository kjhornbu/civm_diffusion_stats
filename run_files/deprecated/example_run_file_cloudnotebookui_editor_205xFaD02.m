close all
clear all

%% Preliminaries
BD='/Volumes/dusom_civm-kjh60/All_Staff';
HOME_DIR=BD;
studyID='20.5xFAD.02';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir,'google_sheet_caps', '20.5XFAD.01-MRIScanSheet_phase2_2025_08_20.tsv');
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_Phase2_',date,'.txt'));
dataframe_path=fullfile(project_dir, [studyID '_DataFrame_Phase2.txt']);
polished_sheets=fullfile(project_dir,'polished_sheets');
project_research_archive{1}=fullfile('/Volumes','dusom_civm-atlas','20.5xFAD.02','research');
project_research_archive{2}=fullfile('/Volumes','dusom_civm-atlas','20.5xFAD.01','research');
atlas_ontology_path=fullfile('/Volumes','workstation','static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg';
% save_dir=fullfile(project_dir,'stats');
save_dir=fullfile(project_dir,'stats_Phase1_from205xFAD02');

%Add Path Block
addpath('/Volumes/workstation/code/analysis/Scalar_Analysis')
addpath('/Volumes/workstation/code/analysis/Scalar_Analysis_Plotting')
addpath('/Volumes/workstation/code/analysis/Omni_Manova')
addpath('/Volumes/dusom_civm-kjh60/All_Staff/civm_diffusion_stats')
addpath('/Users/Shared/workstation/code/shared/civm_matlab_common_utils/file')

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir)

