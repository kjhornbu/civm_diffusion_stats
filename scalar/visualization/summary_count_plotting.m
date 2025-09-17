function [] = summary_count_plotting(save_dir,file_name,file_extension,Data_Table,source_of_variation_types,contrast_types)
%hard_limit=100; %Hard limit for maximal count to show in summary graphic
%% Setup data for plots

[contrasts_inlist,~,contrasts_inlist_idx]=unique(Data_Table.contrast);
[sov_inlist,~,sov_inlist_idx]=unique(Data_Table.source_of_variation);

contrast_logical_matrix=contrasts_inlist_idx==1:numel(contrasts_inlist);
sov_logical_matrix=sov_inlist_idx==1:numel(sov_inlist);

contrastrow_sovcolumn_counts=contrast_logical_matrix'*sov_logical_matrix;

contrastrow_sovcolumn_counts_cleaned=zeros(numel(contrast_types),numel(source_of_variation_types));

 [~,contrastinsert_idx]=intersect(contrast_types,contrasts_inlist);
 [~,sovinsert_idx]=intersect(source_of_variation_types,sov_inlist);

contrastrow_sovcolumn_counts_cleaned(contrastinsert_idx,sovinsert_idx)=contrastrow_sovcolumn_counts;
contrastrow_sovcolumn_counts=contrastrow_sovcolumn_counts_cleaned;

contrast_counts=sum(contrastrow_sovcolumn_counts,2)';
sov_counts=sum(contrastrow_sovcolumn_counts,1);

plotting_name_contrast_types=strrep(contrast_types,'_','-');

max_count_value=max([max(sov_counts) max(contrast_counts)]);
max_count_sov_value= max(sov_counts);
max_count_con_value=max(contrast_counts);

hard_limit=ceil((max_count_value+25)/50)*50; %Give the axis limit a little bit of space but still keep close to the data
hard_limit_sov=ceil((max_count_sov_value+25)/50)*50; %Give the axis limit a little bit of space but still keep close to the data
hard_limit_con=ceil((max_count_con_value+25)/50)*50; %Give the axis limit a little bit of space but still keep close to the data

%clean sov types
source_of_variation_types=strrep(source_of_variation_types,'_',' ');

%% Summary Plotting
fig1=figure;
box on
hold on

if numel(source_of_variation_types)==1 && numel(plotting_name_contrast_types)~=1
    %1 Source of variation, multiple contrasts (1 Way Modeling)
    rectangle('Position',[0.5 0 numel(plotting_name_contrast_types) sum(contrast_counts)],'FaceColor',[0.75 0.75 0.75])
    bar(contrast_counts);

    hold off

    xticks(1:numel(plotting_name_contrast_types))
    xticklabels(plotting_name_contrast_types)
    xlabel('Contrasts')
    ylabel('Counts')
    axis([0,numel(plotting_name_contrast_types)+1, 0 hard_limit]) %rare will the number of counts be close to the max possible of counts so cut down for comparision

    location_text=ceil(sum(contrast_counts)+25);

    if hard_limit>location_text
        text(1,ceil(sum(contrast_counts)+25),'Summed Total Counts','FontSize',6);
    else
        text(1,hard_limit-10,'Summed Total Counts','FontSize',6);
    end

    saveMultiOutFigure(fig1,save_dir,file_name,file_extension);

elseif numel(source_of_variation_types)~=1 && numel(plotting_name_contrast_types)==1
    % 1 Contrast, Multiple sources of variation (MANOVAN -- MANOVA 1 Way does not work through here... anyway that is one bar do you really want summary plots)

    rectangle('Position',[0.5 0 numel(source_of_variation_types) sum(sov_counts)],'FaceColor',[0.75 0.75 0.75])
    bar(sov_counts);

    hold off

    xticks(1:numel(source_of_variation_types))
    xticklabels(source_of_variation_types)
    xlabel('Source of Variation')
    ylabel('Counts')

    axis([0,numel(source_of_variation_types)+1, 0 hard_limit]) %rare will the number of counts be close to the max possible of counts so cut down for comparision

    location_text=ceil(sum(sov_counts)+25);

    if hard_limit>location_text
        text(1,ceil(sum(sov_counts)+25),'Summed Total Counts','FontSize',6);
    else
        text(1,hard_limit-10,'Summed Total Counts','FontSize',6);
    end

    saveMultiOutFigure(fig1,save_dir,file_name,file_extension);

elseif numel(source_of_variation_types)==1 && numel(plotting_name_contrast_types)==1
    keyboard;
     % 1 Contrast, 1sources of variation (MANOVA 1 Way) Just have one of the
     % grey bars because there are not multiple things to look at??? Think
     % about more

     bar(sov_counts);

    hold off

    xticks(1:numel(source_of_variation_types))
    xticklabels(source_of_variation_types)
    xlabel('Source of Variation')
    ylabel('Counts')

    axis([0,numel(source_of_variation_types)+1, 0 hard_limt]) %rare will the number of counts be close to the max possible of counts so cut down for comparision

    saveMultiOutFigure(fig1,save_dir,file_name,file_extension);

elseif numel(source_of_variation_types)~=1 && numel(plotting_name_contrast_types)~=1
    %Multiple contrasts, Multiple sources of variation (any other model)

    bar(sov_counts,'FaceColor',[0.75 0.75 0.75]);
    bar(contrastrow_sovcolumn_counts');

    hold off

    xticks(1:numel(source_of_variation_types))
    xticklabels(source_of_variation_types)
    xlabel('Source of Variation')
    ylabel('Counts')
    axis([0.5,numel(source_of_variation_types)+0.5, 0 hard_limit_sov]) %rare will the number of counts be close to the max possible of counts so cut down for comparision
    legend(vertcat({'Summed Total Counts'},plotting_name_contrast_types),'location','best')


    saveMultiOutFigure(fig1,save_dir,strcat(file_name,'_SourceOfVariation'),file_extension);

    fig2=figure;
    box on
    hold on
    bar(contrast_counts,'FaceColor',[0.75 0.75 0.75]);
    bar(contrastrow_sovcolumn_counts);

    hold off
    xticks(1:numel(plotting_name_contrast_types))
    xticklabels(plotting_name_contrast_types)
    xlabel('Contrasts')
    ylabel('Counts')

    axis([0.5,numel(plotting_name_contrast_types)+0.5, 0 hard_limit_con]) %rare will the number of counts be close to the max possible of counts so cut down for comparision

    legend(vertcat({'Summed Total Counts'},source_of_variation_types),'location','best')

    saveMultiOutFigure(fig2,save_dir,strcat(file_name,'_Contrast'),file_extension);
end

end