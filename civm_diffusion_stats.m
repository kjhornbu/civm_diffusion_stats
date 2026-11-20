function [ opts ] = civm_diffusion_stats(varargin)
%% CIVM_DIFFUSION_STATS
% Runs statistical analysis for connectomes and scalar creating summmary
% documents for both
%
%
% Current Input Parameters:
%
% Required: Order Matters must be first in the parameter block
%
% studyID - The CIVM Project code for the Study, such as 20.5xFAD.01
% statSaveDir - Path to where the analysis will be saved, ie folder in B drive
%
% Optional: Order Doesn't Matter in calling these, Blocked by Generally
% Working on Similar Things.
%
% configFile - Path to what configuration will be used. The configuration
%    in the case is primarily the statistical model parameters not this input
%    parameters. Default = ''. 
% findmedianspecimen - Indicates if you want to find the most median
%    specimen during scalar analysis which can be helpful for choosing
%    specimen for doing lightsheet. Default = false.
%
% Expected that google_doc is a file which civm_read_table will load
% will save updated copy to cleaned_google_doc_path
% from cleaned googledoc, will build and save dataframe sheet to dataframe.
% scans which are accepted into datframe are polished into polished_sheets
%
% dataframePath - A path to a dataframe file. Default =[]. You must have at
%    least 1 existing file path between dataframePath, cleanedGoogleDocPath,
%    and googleDocPath for the analysis to run.
% cleanedGoogleDocPath - A path to a cleaned google file - this removes some of
%    the name missspelling etc. Default =[]. You must have at  least 1 existing 
%    file path between dataframePath, cleanedGoogleDocPath, and googleDocPath 
%    for the analysis to run.
% googleDocPath - A path to the raw google doc pulled off of google drive 
%    (aka the cloud notebooks). Typically works best as a txt rather than a tsv.
%    Default =[]. You must have at  least 1 existing file path between dataframePath,
%    cleanedGoogleDocPath, and googleDocPath for the analysis to run.
%
% polishedSheetPath - the scalar statistics sheets are stored in the oracle
%    archive for each specimen in the study. as part of the stat setup
%    process, we polish the stats by creating parent structures and removing
%    regions that have little meaning. This is the path where those saved
%    files are placed. Default = []. 
% researchArchivePath - The path to the oracle archive folder for the
%    data. You can indicate more than 1 if you assign it with {1}, {2}.
%    project_research_archive{1}=fullfile('A:/',studyID,'research');
%    project_research_archive{2}=fullfile('A:/',studyID_2,'research'); 
%
% overrideLabelLUT- path to what label look up should be used. Default is [].
%    But, typically we use:
%    fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt');
% pvalThreshold - Threshold for "significance" in pvalue analysis. Default = 0.05.
% pvalType - What types of pvalue to look at. Default = list2cell('pval_BH pval'). 
% analysisPipelineType - If this run is Scalar/Connectome or both. Default
%    = list2cell('Scalar Connectome') which runs both scalar and connectome.
%    If you want just one type {'Scalar'} or {'Connectome'} here for that option.
% isSuffixOptional - If you don't have that suffix is it okay? (ie just do
%    best for matching). Default = false
% suffix - The suffix we are matching with. Default = []. 
% allowMissing - Is it okay to keep running if some specimen are missing in
%    the study. Default = false.
% assumeNLSAM - If you aren't remaking a dataframe and this is Default = false. 
% alternative_statsheet_dir - instead of pulling all the scalar data from
%    the archive you might pull just the scalar sheets from a flat directory.
%    This is when you do that. It has a differnet loading mechanism. 
%
% Scalar_Sheet_Path_csv - These are not populated currently. suspect it
%    will be where the sheets are saved? 
% Connectome_Sheet_Path_csv - These are not populated currently. suspect it
%    will be where the sheets are saved?
%
% user - The name of the user. It is written on the summary documents so we
%    have a written record about who did what run. If you don't provide your
%    name it will pull a name indication from your computer's username.
%
% extendedStudyColumns - other columns that NEED to be in the dataframe and
% the data will check for. For example if you HAVE to have age or something
% like that.
%
% scalarContrastMetrics - the metrics we are actually studying in the
%    scalar data set and how to work with them. The default is the non-eroded
%    data, which is input as so.
%     default_scalarContrast=struct;
%     default_scalarContrast(1).Name={'Non_Erode'}; 
%     default_scalarContrast(1).Column={'stat_path'};
%     default_scalarContrast(1).erode={'0'};
%     default_scalarContrast(1).level={'0'};
%     default_scalarContrast(1).bilateral=false;
%     default_scalarContrast(1).nickname={'leaf'};
%     default_scalarContrast(1).stat_extension={strcat('_e',default_scalarContrast(1).erode,'_L',default_scalarContrast(1).level,'_',default_scalarContrast(1).nickname,'.txt')};
%     default_scalarContrast(1).List=list2cell("volume_mm3 volume_fraction
%     fa_mean ad_mean md_mean rd_mean tdi_mean"); % If it exists as a
%     contrast in the subject_data_table you can use it as a
%     scalarContrast.
%
%     Examples for how to do other types
%
%     [1] Eroded stats
%      default_scalarContrast(2).Name={'Erode'}; 
%      default_scalarContrast(2).Column={'stat_path_erode'};
%      default_scalarContrast(2).erode={'1'};
%      default_scalarContrast(2).level={'0'};
%      default_scalarContrast(2).bilateral=false;
%      default_scalarContrast(2).nickname={'leaf'};
%      default_scalarContrast(2).stat_extension={strcat('_e',default_scalarContrast(2).erode,'_L',default_scalarContrast(2).level,'_',default_scalarContrast(2).nickname,'.txt')};
%      default_scalarContrast(2).List=list2cell("fa_mean ad_mean md_mean rd_mean");
%
%    [2]The former QSDR that Harrison used.
%     default_scalarContrast(3).Name={'lightsheet'}; 
%     default_scalarContrast(3).Column={'stat_path'}; 
%     default_scalarContrast(3).erode={'0'};
%     default_scalarContrast(3).level={'0'};
%     default_scalarContrast(3).bilateral=false;
%     default_scalarContrast(3).nickname={'leaf'};
%     default_scalarContrast(3).stat_extension={strcat('_e',default_scalarContrast(3).erode,'_L',default_scalarContrast(3).level,'_',default_scalarContrast(3).nickname,'.txt')};
%     default_scalarContrast(3).List=strcatlist2cell(strrep('dti_fa,ad,md,rd,iso,qa,rdi,t-inc-ad,t-inc-md,t-inc-rd,t-inc-gfa,t-inc-dti-fa,t-inc-iso,t-inc-qa,t-dec-ad,t-dec-md,t-dec-rd,t-dec-gfa,t-dec-dti-fa,t-dec-iso,t-dec-qa','-','_')),'_mean');
%
% plotting_sheet_types - which one of the scalarContrastMetrics to actually
%    plot in the summary graphics/ppt
% plotting_hemispheres - What hemisphere we want plotted in the summary graphics/ppt 

%% PRELIMINARIES
% Input Options Parser
p = inputParser;

% === Positional arguments ===
addRequired(p, 'studyID', @(x) ischar(x) || isstring(x)); %what the study will be called
addRequired(p, 'statSaveDir', @(x) ischar(x) || isstring(x)); %where the data is going to be saved

% === Other Key Inputs ===
% Add parameters -- Kinda optional but depends -- The checker at the end ...
% will provide notice of this! (not positionally dependant, chunked by
% general type of thing that is getting set)

addParameter(p, 'configFile','', @(x) ischar(x) || isstring(x));
addParameter(p,'findmedianspecimen',false,  @(x) isscalar(x) && ismember(x, [false, true]));
addParameter(p, 'dataframePath',[], @(x) ischar(x) || isstring(x));
addParameter(p, 'cleanedGoogleDocPath',[], @(x) ischar(x) || isstring(x));
addParameter(p, 'googleDocPath',[], @(x) ischar(x) || isstring(x));

addParameter(p, 'polishedSheetPath',[], @(x) ischar(x) || isstring(x));
addParameter(p, 'researchArchivePath',[], @(x) ischar(x) || isstring(x)|| iscell(x));

addParameter(p, 'overrideLabelLUT', [], @(x) ischar(x) || isstring(x));
addParameter(p, 'pvalThreshold', 0.05, @(x) isnumeric(x) && numel(x) == 1 && x>=0 && x <=1);
addParameter(p, 'pvalType', list2cell('pval_BH pval'), @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'analysisPipelineType', list2cell('Scalar Connectome'), @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'isSuffixOptional', false,  @(x) isscalar(x) && ismember(x, [false, true]));
addParameter(p, 'suffix',[], @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p, 'allowMissing', false,  @(x) isscalar(x) && ismember(x, [false, true])); %If you are missing stuff you are caring about change option to true
addParameter(p, 'assumeNLSAM', false,  @(x) isscalar(x) && ismember(x, [false, true])); %hey if you are missing all your data you need to look for NLSAM (change to true)
addParameter(p, 'alternative_statsheet_dir',[], @(x) ischar(x) || isstring(x) || iscell(x)); % if you have stats that are in a flat file (like out of a samba run here is how to grab them all together and use them)-- Either put the same path in teh project research path or leave empty

addParameter(p,'Scalar_Sheet_Path_csv',[], @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p,'Connectome_Sheet_Path_csv',[], @(x) ischar(x) || isstring(x) || iscell(x));

if isempty(getenv('USER')), user_name=getenv('USERNAME'); end
addParameter(p, 'user', user_name, @(x) ischar(x) || isstring(x) || iscell(x)); 

addParameter(p,'extendedStudyColumns',{}, @(x) ischar(x) || isstring(x) || iscell(x));

default_scalarContrast=struct;
default_scalarContrast(1).Name={'Non_Erode'}; 
default_scalarContrast(1).Column={'stat_path'};
default_scalarContrast(1).erode={'0'};
default_scalarContrast(1).level={'0'};
default_scalarContrast(1).bilateral=false;
default_scalarContrast(1).nickname={'leaf'};
default_scalarContrast(1).stat_extension={strcat('_e',default_scalarContrast(1).erode,'_L',default_scalarContrast(1).level,'_',default_scalarContrast(1).nickname,'.txt')};
default_scalarContrast(1).List=list2cell("volume_mm3 volume_fraction fa_mean ad_mean md_mean rd_mean tdi_mean");

addParameter(p,'scalarContrastMetrics',default_scalarContrast, @(x) isstruct(x));

addParameter(p,'plotting_sheet_types',{'Non_Erode'}, @(x) ischar(x) || isstring(x) || iscell(x));
addParameter(p,'plotting_hemispheres',[0], @(x) isnumeric(x) && (x==-1||x==0||x==1));

addParameter(p,'connectome_set_do_binarize', false, @validate_bool);
addParameter(p,'connectome_set_do_mean_subtract', false, @validate_bool);
addParameter(p,'connectome_set_do_ptr', false, @validate_bool);
addParameter(p,'connectome_set_do_augment', false, @validate_bool);
addParameter(p,'connectome_outputs',list2cell('Unscaled_Omni_Manova BrainScaled_Omni_Manova'),@validate_text);

%check to make sure that the connectome_outputs are at least one of the two
%valid options - connectome_outputs=list2cell('Unscaled_Omni_Manova BrainScaled_Omni_Manova');

% Parse input
parse(p, varargin{:});
opts=p.Results; 
opts = optsErrorChecking(opts);

clear p user_name default_scalarContrast varargin

%% Get the Statistical Model Inputs (that is edits to the dataframe and to the statistical model itself) put into a configuration file itself for long term use. 
opts=setStatisticalModelInputs(opts); 

%% This organizes the input into reasonable useable chunks and resaves the configuration file.
opts = clean_up_stats_setup(opts);

%% Do THE SCALAR ANALYSIS
opts = do_scalar(opts);

%% Do THE CONNECTOME ANALYSIS
opts = do_connectome(opts);

%% save final opts to make sure everything is there that we have gathered. 
save(opts.configFile,'opts','-mat');
end

