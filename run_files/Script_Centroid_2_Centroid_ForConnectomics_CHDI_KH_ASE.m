
close all;
clear all;

%% ASE
working_folder="B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall";

mkdir(fullfile(working_folder,'ASE_plots'));
mkdir(fullfile(working_folder,'ASE_plots','Regional'));
mkdir(fullfile(working_folder,'ASE_plots','Global'));

green=[0.4660 0.6740 0.1880];
purple=[0.4940 0.1840 0.5560];

Data_global_overall=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\Genotype_AgeofTerminationmonths_Sex\BrainScaled_Omni_Manova\Global_ASE_0000.csv"));
[output_global_overall,s_global] = specimen_2_specimen(Data_global_overall);

Data_regional=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\Genotype_AgeofTerminationmonths_Sex\BrainScaled_Omni_Manova\ASE_0000.csv"));
[output_regional, s_regional] = specimen_2_specimen(Data_regional);

pval_table=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\Genotype_AgeofTerminationmonths_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv"));
source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Genotype'));
pval_idx=pval_table.pval_BH<0.05;
all_sig_pvalues=pval_table.ROI(and(source_idx,pval_idx));

values_T=sort(all_sig_pvalues,'ascend');

idx_group=~cellfun(@isempty,regexpi(output_regional.hold,'All'));

for n=1:numel(values_T)
    if values_T(n)>180
        values_T(n)=values_T(n)-1000+180;
    end
    idx=output_regional.vertex==values_T(n);
    idx_indiv=Data_regional.vertex==values_T(n);

    temp_out = output_regional(idx & idx_group ,:);

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for m=1:height(temp_out)
        temp_indiv_data = Data_regional(~cellfun(@isempty,regexpi(Data_regional.group1,temp_out.compare{m}))&idx_indiv,:); %& idx_indiv
        if strcmp(temp_out.compare{m},'HET')
            plot(temp_indiv_data.X1/s_regional(1),temp_indiv_data.X2/s_regional(2),'o','MarkerFaceColor', [0.4660 0.6740 0.1880],'MarkerEdgeColor',[1 1 1],'MarkerSize',4);%green
        elseif strcmp(temp_out.compare{m},'WILD')
            plot(temp_indiv_data.X1/s_regional(1),temp_indiv_data.X2/s_regional(2),'o','MarkerEdgeColor',[0.4940 0.1840 0.5560],'MarkerSize',4); %purple
        end
    end

    legend('off');

    plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);

    hold off

    axis([-9 9 -9 9]);

    xticks([-9, -6, -3, 0, 3, 6, 9]);
    yticks([-9, -6, -3, 0, 3, 6, 9]);

    xlabel('Dimension 1','FontSize',4.5,'FontName','Arial')
    ylabel('Dimension 2','FontSize',4.5,'FontName','Arial')

    set(gca, 'fontsize',4.5,'FontName','Arial');
    
    if values_T(n)>180
        print(f, fullfile(working_folder,'MDS_plots','Regional',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)-180+1000),'.svg')),'-dsvg','-vector');
    else
        print(f, fullfile(working_folder,'MDS_plots','Regional',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)),'.svg')),'-dsvg','-vector');
    end
    close all
end

civm_write_table(output_regional,fullfile(working_folder,'MDS_plots','Regional','REGIONAL_ASE_centroid_to_centroid_Distance_All+AgeGroup.csv'));
civm_write_table(output_global_overall,fullfile(working_folder,'MDS_plots','Global','GLOBAL_ASE_centroid_to_centroid_Distance_All+AgeGroup.csv'));


% Global MDS plot

f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for n=1:height(Data_global_overall)

        if strcmp(Data_global_overall.group1{n},'HET')
            plot(Data_global_overall.X1(n)/s_global(1),Data_global_overall.X2(n)/s_global(2),'o','MarkerFaceColor', [0.4660 0.6740 0.1880],'MarkerEdgeColor',[1 1 1],'MarkerSize',4); %green
        elseif strcmp(Data_global_overall.group1{n},'WILD')
            plot(Data_global_overall.X1(n)/s_global(1),Data_global_overall.X2(n)/s_global(2),'o','MarkerEdgeColor',[0.4940 0.1840 0.5560],'MarkerSize',4); %purple
        end
    end

    
    idx=~cellfun(@isempty,regexpi(output_global_overall.hold,'All'));
    temp_out=output_global_overall(idx,:);

    plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
    hold off

    axis([-3 3 -3 3]);
    xticks([-3, -1.5, 0, 1.5, 3]);
    yticks([-3, -1.5, 0, 1.5, 3]);

    xlabel('Dimension 1','FontSize',4.5,'FontName','Arial')
    ylabel('Dimension 2','FontSize',4.5,'FontName','Arial')

    set(gca, 'fontsize',4.5,'FontName','Arial');

    print(f, fullfile(working_folder,'MDS_plots','Global','Global_All.svg'),'-dsvg','-vector');


    % Select each time point
    [value,~,value_idx]=unique(Data_global_overall.group2);

    for m=1:numel(value)
        temp_global=Data_global_overall(value_idx==m,:);
        f=figure;
        set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
        hold on
        box on

        for n=1:height(temp_global)

            if strcmp(temp_global.group1{n},'HET')
                plot(temp_global.X1(n)/s_global(1),temp_global.X2(n)/s_global(2),'o','MarkerFaceColor', [0.4660 0.6740 0.1880],'MarkerEdgeColor',[1 1 1],'MarkerSize',4);%green
            elseif strcmp(temp_global.group1{n},'WILD')
                plot(temp_global.X1(n)/s_global(1),temp_global.X2(n)/s_global(2),'o','MarkerEdgeColor',[0.4940 0.1840 0.5560],'MarkerSize',4);%purple
            end
        end

        idx=~cellfun(@isempty,regexpi(output_global_overall.hold,value{m}));
        temp_out=output_global_overall(idx,:);
        
        plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);

        hold off

        axis([-3 3 -3 3]);
        xticks([-3, -1.5, 0, 1.5, 3]);
        yticks([-3, -1.5, 0, 1.5, 3]);

        xlabel('Dimension 1','FontSize',4.5,'FontName','Arial')
        ylabel('Dimension 2','FontSize',4.5,'FontName','Arial')

        set(gca, 'fontsize',4.5,'FontName','Arial');

        print(f, fullfile(working_folder,'MDS_plots','Global',strcat('Global_AgeGroup_',value{m},'.svg')),'-dsvg','-vector');
    end

    close all;
    