close all
clear all

%% Preliminaries
BD='Z:\All_Staff\';
HOME_DIR=BD;
studyID='24.niehs.01';
project_dir=fullfile(HOME_DIR,studyID);
google_doc=fullfile(project_dir,'google_sheet_caps', '24.niehs.01 - Phase I_2025-05-23.tsv');
cleaned_google_doc_path=fullfile(project_dir,'google_sheet_caps',strcat('Edited_GoogleSheet_',date,'.txt'));
dataframe_path=fullfile(project_dir, [studyID '_DataFrame_Windows_20250916.txt']);
setup_file='Z:\All_Staff\24.niehs.01\stats_20250917_TestScalarConnectome\24.niehs.01_DataFrame_Windows_20250916_setup.mat';

polished_sheets=fullfile(project_dir,'polished_sheets');
%project_research_archive=fullfile('/Volumes','dusom_civm-atlas','24.niehs.01','research');
project_research_archive=fullfile('A:/',studyID,'research');
%atlas_ontology_path=fullfile('/Volumes','workstation','static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 
atlas_ontology_path=fullfile('C:/workstation/','static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

pval_threshold=0.05;
pval_cols=list2cell('pval_BH pval');
user='Kathryn Hornburg ';
save_dir=fullfile(project_dir,'stats_20250917_TestScalarConnectome');

% %Add Path Block
% addpath('/Volumes/workstation/code/analysis/Scalar_Analysis')
% addpath('/Volumes/workstation/code/analysis/Scalar_Analysis_Plotting')
% addpath('/Volumes/workstation/code/analysis/Omni_Manova')
% addpath('/Volumes/dusom_civm-kjh60/All_Staff/civm_diffusion_stats')
% addpath('/Users/Shared/workstation/code/shared/civm_matlab_common_utils/file')



%which_tests=list2cell('Scalar'); %does only scalar stats
which_tests=list2cell('Scalar Connectome'); %does both scalar and connectome stats
%which_tests=list2cell('Connectome'); %does only connectome stats

optional_suffix=false;
suffix='';

 A=genpath("Z:\All_Staff\civm_diffusion_stats\");
 addpath(A);

civm_diffusion_stats(user,studyID,google_doc,cleaned_google_doc_path,dataframe_path,setup_file, polished_sheets,project_research_archive,atlas_ontology_path,pval_cols,pval_threshold,save_dir,which_tests,optional_suffix,suffix);
