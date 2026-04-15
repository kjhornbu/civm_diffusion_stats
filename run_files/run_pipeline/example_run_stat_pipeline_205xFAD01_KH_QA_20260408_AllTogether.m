close all;
clear variables;

%% Preliminaries
studyID='21.QA94TAgilent.01';
project_dir='B:\20.5xfad.02\QA_Studies_Scalar_Stats\';
google_doc="B:\20.5xfad.02\21QA94TAgilent_20260215_WithWyattNotes.txt";
% googledata=civm_read_table(google_doc);
% 
% %removing broken bo_value
% idx=googledata.bo_value==737280;
% 
% for n=1:height(googledata)
%     if idx(n)
%         googledata.BVALUE{n}='BVALUE_4000';
%     else
%         googledata.BVALUE{n}='BVALUE_3000';
%     end
% end
% 
% googledata.bo_value=[];
% civm_write_table(googledata,google_doc)


% % For breaking up parameters more fully.
% for n=1:height(googledata)
%     temp=strsplit(googledata.console_amplifer{n},'-');
%     googledata.console{n}=temp{1};
%     googledata.amplifer{n}=temp{2};
% 
%     temp=strsplit(googledata.pulse_sequence{n},'-');
% 
%     googledata.sequence_type{n}=temp{2};
%     googledata.resolution{n}=temp{3};
%     googledata.compression_ratio{n}=temp{4};
%     googledata.number_angles{n}=temp{5};
%     googledata.bo_value{n}=temp{6};
% end
% 
% googledata.pulse_sequence=[];
% googledata.console_amplifer=[];
% 
% civm_write_table(googledata,google_doc)

% % For adding Age and STrain
% googledata.Age=repmat(90,height(googledata),1);
% googledata.Strain=repmat('B6',height(googledata),1);
% civm_write_table(googledata,google_doc)

cleaned_google_doc_path='B:\20.5xfad.02\Edited_21QA94TAgilent_20260215_WithWyattNotes.txt';
statSaveDir=fullfile(project_dir,'AllTogether/');

dataframe_path=fullfile(statSaveDir, '21QA94TAgilent_20260215_WithWyattNotes.txt');
config_file='';
polished_sheets=fullfile(project_dir,'polished_sheets'); %where the polished sheets will be saved 
project_research_archive{1}=fullfile('A:/',studyID,'research');
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 

studyParams={
  studyID,...
  statSaveDir,...
  'configFile',config_file,...
  'googleDocPath',google_doc,...
  'cleanedGoogleDocPath',cleaned_google_doc_path,...
  'dataframePath',dataframe_path,...
  'overrideLabelLUT',atlas_ontology_path,...
  'researchArchivePath',project_research_archive,...
  'polishedSheetPath',polished_sheets,...
  'suffix','batchQA',...
  'allowMissing',true,...
  'analysisPipelineType', list2cell('Scalar')};

civm_diffusion_stats(studyParams{:});