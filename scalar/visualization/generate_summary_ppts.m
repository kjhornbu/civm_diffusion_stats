function [] = generate_summary_ppts(Path_table,project_id,user,pvalue_type,pval_threshold,study_model,test_cases)

assert(isstruct(test_cases),'You need to update your helper code. I require test_cases as a struct now');
import mlreportgen.ppt.*;

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

%% %each hemisphere, each erode condition make a ppt
% last_table_loaded=cell(1,3);
for n=1:height(Path_table)
    % Figure out which stratifications are in play here and convert to
    % words (each hemisphere, each erode condition)
    try
        hemisphere=uncell(Path_table.hemisphere(n));
    catch merr
        warning(merr.identifier,'trouble grabing hemisphere: %s',merr.message);
        hemisphere=Path_table.hemisphere(n);
    end

    %each hemisphere, each erode condition
    %This was useful with the old form of building processed_stats_dir
    voxel_wise=Path_table.voxel_wise{n};
    if hemisphere==0
        hemisphere_set='Bilateral';
    elseif hemisphere==1
        hemisphere_set='Right';
    elseif hemisphere==-1
        hemisphere_set='Left';
    else
        keyboard;
    end
    
    processed_stats_dir=fileparts(Path_table.StatsResults{n});
    figure_dir=fullfile(processed_stats_dir,fig_dir_name);
    %out_file=fullfile(processed_stats_dir,strcat('Group_Statistical_Results_',strjoin(Key_Grouping_Columns{1},'_'),'.csv'));

    summary_dir=fullfile(figure_dir,'Summary');
    interesting_data_path=fullfile(summary_dir,'Significant_Statistical_Results.csv');

    if strcmp(Path_table.stratification{n},'-')
        ppt_identity={project_id,voxel_wise,hemisphere_set,study_model};
    else
        ppt_identity={project_id,voxel_wise,hemisphere_set,study_model,Path_table.stratification{n}};
    end

    %% Start Powerpoint
    f_info=dir(interesting_data_path);
    if ~isempty(f_info)
        summary_date=datetime(f_info.date);
    else 
        summary_date=now;
    end
    ppt_name_components={project_id,voxel_wise,hemisphere_set,'Summary',datestr(summary_date,'yyyy-mm-dd')};
    scalar_analysis_ppt_summary_file=fullfile(summary_dir,[strjoin(ppt_name_components,'_'), '.pptx']);

    if file_time_check(scalar_analysis_ppt_summary_file,'newer',interesting_data_path)
    %if exist(scalar_analysis_ppt_summary_file,'file')
        warning('Previously complete, not updating %s',scalar_analysis_ppt_summary_file);
        continue;
    end

    code_dir=fileparts(mfilename('fullpath'));
    template_file=fullfile(code_dir,'mlreportgen_scalar_analysis.pptx');
    if exist(template_file,'file')
        ppt = Presentation(scalar_analysis_ppt_summary_file,template_file);
    else
        warning('Missing template %s, using default',template_file);
        ppt = Presentation(scalar_analysis_ppt_summary_file);
    end
    open(ppt);

    %% Add Title Slide
    [slidepointer] = title_slide_setup(ppt,ppt_identity,user);

    %% Bar Chart Slide
    graph_figure=fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'.png'));
    
    if strcmp(pvalue_type,'pval_BH')
        name=['Significant at ',num2str(pval_threshold),' via BH Corrected Pvalue'];
    elseif strcmp(pvalue_type,'pval')
        name=['Significant at ',num2str(pval_threshold),' via Pvalue'];
    end

    if ~exist(graph_figure,'file')
        compare_image={fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'_Contrast.png')),fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'_SourceOfVariation.png'))};
    else
        compare_image={fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'.png'))};
    end

    [slidepointer] = summary_slide_setup(ppt,name,compare_image);

%     %% CohenF Plot Slides
% 
%     % Volume slides
%     name = "source of variation Volume Metrics Cohen F Plots";
%     compare_image={fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'.png'))};
%     [slidepointer] = summary_slide_setup(ppt,name,compare_image);
% 
%     
%     %Diffusion Slides
%     name = "source of variation Diffusion Metrics Cohen F Plots";
%     compare_image={fullfile(summary_dir,'png',strcat('Scalar_Summary_Sig_',pvalue_type,'.png'))};
%     [slidedata] = summary_slide_4item_setup(ppt,name,compare_image);

    %% Summary Slides for Each "Interesting" Contrast Per SOV
    check_interesting_data=readtable(interesting_data_path,'Delimiter','\t');
   
    %because the way that the data is saved it opens poorly in civm read
    %table we are using this to check if the file is empty before doing
    %real work

    try
        %If blank totally typically this shows up
        comment_index=~cellfun(@isempty,regexpi(check_interesting_data.x_ROI,'^#'));
    catch
        %otherwise it could be a nan
        comment_index=isnan(check_interesting_data.x_ROI);
    end

    try
    %If we don't have anything interesting it skips this.
    if (height(check_interesting_data)-sum(comment_index))>0  
        Interesting_Data=civm_read_table(interesting_data_path);
        Group_Table=civm_read_table(Path_table.GroupTable{n});

        try
            [slidepointer] = scalar_summary_slide_setup(ppt,figure_dir,Interesting_Data,Group_Table,test_cases.control,test_cases.treatment);
        catch exception
            warning(exception.identifier,'error in summary setup slide creation: %s',exception.message);
            keyboard;
        end
     else
        %Make "Blank Filler Slide"
        slidepointer = add(ppt,'Title Slide');
        replace(slidepointer,'Title','No Significant Results');
    end
    catch exception
        keyboard;
    end
    close(ppt);
end
end