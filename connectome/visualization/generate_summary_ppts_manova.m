function [] = generate_summary_ppts_manova(summary_dir,Paths_Pval,studyID,user,connectome_outputs,pval_threshold,studymodel,configuration_struct)
%% Preliminareies
import mlreportgen.ppt.*;
fig_dir_name='summary';
pvalue_type='pval_BH';

%how does stratification work in omni-manova saving land???
if strcmp(Paths_Pval.stratification{n},'-')
    ppt_identity={studyID,scallng(),studymodel};
else
    ppt_identity={studyID,scallng(),studymodel,Paths_Pval.stratification{n}};
end

folder_path=fullfile(summary_dir,fig_dir_name);
 if ~exist(folder_path,'dir')
     mkdir(folder_path);
 end

 % Get the figures we need to compile for (only group effects) -- in the
 % real name of the data
 all_main_in_model=configuration_struct.model_table.Properties.VariableNames;
 key_effect_idx=~cellfun(@isempty,configuration_struct.test_criteria.GROUP);
 key_effect_name=configuration_struct.test_criteria.Column_Names(key_effect_idx);

%get the GroupN index for each key_effect_name
for n=1:sum(key_effect_idx)
    idx=strcmp(configuration_struct.test_criteria.GROUP,num2str(n));
    key_effect_group_idx=~cellfun(@isempty,regexpi(key_effect_name,configuration_struct.test_criteria.Column_Names(idx)));
    key_effect_group(n)=find(key_effect_group_idx);
end

%find all instances where those effects were used (main or interaction)
for n=1:numel(key_effect_name)
    select_idx(:,n)=~cellfun(@isempty,regexpi(all_main_in_model,key_effect_name(n)));
    effect_in_model_idx(:,n)=configuration_struct.model_table.(key_effect_name{n});
end

% Find the instances of non-Group effects (so you know what you don't want)
not_group_effects=sum(select_idx,2)==0;
pos_idx=find(not_group_effects);

for n=1:numel(pos_idx)
    not_effect_name=all_main_in_model(pos_idx(n));
    not_effect_in_model_idx(:,n)=configuration_struct.model_table.(not_effect_name{n});
end

%select only sources that have group effects in them
sources_to_pick_idx=sum(effect_in_model_idx,2)>0 & sum(not_effect_in_model_idx,2)==0;
sources_to_pick_pos_idx=find(sources_to_pick_idx);

for n=1:numel(sources_to_pick_pos_idx)
    pick_idx=table2array(configuration_struct.model_table(sources_to_pick_pos_idx(n),:))==1; 
    pick_name{n}=strjoin(all_main_in_model(pick_idx),'x');

    pick_name_as_Group
end


%% Start Powerpoint
f_info=dir(folder_path);
if ~isempty(f_info)
    summary_date=datetime(f_info.date);
else
    summary_date=now;
end

ppt_name_components={studyID,'Summary_MANOVA',datestr(summary_date,'yyyy-mm-dd')};
omni_analysis_ppt_summary_file=fullfile(folder_path,[strjoin(ppt_name_components,'_'), '.pptx']);

code_dir=fileparts(mfilename('fullpath'));
template_file=fullfile(code_dir,'mlreportgen_scalar_analysis.pptx');

if exist(template_file,'file')
    ppt = Presentation(omni_analysis_ppt_summary_file,template_file);
else
    warning('Missing template %s, using default',template_file);
    ppt = Presentation(omni_analysis_ppt_summary_file);
end

    open(ppt);

for n=1:numel(connectome_outputs)

    %% Add Title Slide

    [slidepointer] = title_slide_setup(ppt,ppt_identity,user);

    %Find data index
    idx=~cellfun(@isempty,regexpi(Paths_Pval.(connectome_outputs{n}).name,'[Aa]ll'));
    pos_idx=find(idx);

    %% Global
    %% Add in Global Results -- Pval -> Make an MANOVA Table?

    %open the global pval stats
    global_pval_table=civm_read_table(Paths_Pval.(connectome_outputs{n}).global{pos_idx});
    [slidepointer]=make_global_pval_suummary_table(ppt,global_pval_table);

    %% Add in Global Results -- MDS plot -- needs to be prettier?

    global_mds=civm_read_table(fullfile(summary_dir,connectome_outputs{n},'Global_MDS_0000.csv'))
    for pick=1:numel(pick_name)

    end
    
    %% Regional
    regional_pval_table=civm_read_table(Paths_Pval.(connectome_outputs{n}).regional{pos_idx});
    [slidepointer] = make_regional_pval_summary(ppt,studymodel,regional_pval_table,pvalue_type,pval_threshold);

    for sov=1:n
        %% Add in Regional Results -- 1 remove?

        %% list off regions that have 1 remove at highest level?
    end
end
end