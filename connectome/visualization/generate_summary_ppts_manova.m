function [] = generate_summary_ppts_manova(Path_table,project_id,user,connectome_type,pval_threshold,study_model)
import mlreportgen.ppt.*;


connectome_list=list2cell('Unscaled_Omni_Manova BrainScaled_Omni_Manova');


%just have Figures for general....
fig_dir_name='figures';

if strcmp(pvalue_type,'pval_BH')
    fig_dir_name='figures';
elseif strcmp(pvalue_type,'pval')
    fig_dir_name='figures_withoutFDR';
else
    keyboard;
end

if ~istable(Path_table)
    Path_table=civm_read_table(Path_table);
end

if strcmp(Path_table.stratification{n},'-')
    ppt_identity={project_id,scallng(),study_model};
else
    ppt_identity={project_id,scallng(),study_model,Path_table.stratification{n}};
end


%% Start Powerpoint
f_info=dir(interesting_data_path);
if ~isempty(f_info)
    summary_date=datetime(f_info.date);
else
    summary_date=now;
end

ppt_name_components={project_id,'Summary_MANOVA',datestr(summary_date,'yyyy-mm-dd')};
omni_analysis_ppt_summary_file=fullfile(summary_dir,[strjoin(ppt_name_components,'_'), '.pptx']);

if file_time_check(omni_analysis_ppt_summary_file,'newer',interesting_data_path)
    %if exist(scalar_analysis_ppt_summary_file,'file')
    warning('Previously complete, not updating %s',omni_analysis_ppt_summary_file);
    return;
end

code_dir=fileparts(mfilename('fullpath'));
template_file=fullfile(code_dir,'mlreportgen_scalar_analysis.pptx');
if exist(template_file,'file')
    ppt = Presentation(omni_analysis_ppt_summary_file,template_file);
else
    warning('Missing template %s, using default',template_file);
    ppt = Presentation(omni_analysis_ppt_summary_file);
end
open(ppt);


%% Add Title Slide
[slidepointer] = title_slide_setup(ppt,ppt_identity,user);

%% Global
%% Add in Global Results -- Pval -> Make an MANOVA Table?
%open the global pval stats
global_pval_table=civm_read_table(--Grab the global pvalues);
[slidepointer]=make_global_pval_suummary_table(ppt,global_pval_table);

%% Add in Global Results -- MDS plot -- needs to be prettier?


%% Regional
regional_pval_table=civm_read_table(--Grab the regional pvalues);
threshold_type = 'pval_BH';
[slidedata] = make_regional_pval_summary(ppt,global_pval_table,regional_pval_table,threshold_type,pval_threshold);
for sov=1:n
    %% Add in Regional Results -- 1 remove?

    %% list off regions that have 1 remove at highest level?
end
end