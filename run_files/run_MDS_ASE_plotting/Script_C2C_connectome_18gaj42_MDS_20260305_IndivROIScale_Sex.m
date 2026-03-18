
close all;
clear all;

working_folder='Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\MDS_Sex+All';

mkdir(fullfile(working_folder,'REGIONAL'));
mkdir(fullfile(working_folder,'GLOBAL'));

green=[0.4660 0.6740 0.1880];
purple=[0.4940 0.1840 0.5560];

pval_table=civm_read_table(fullfile('Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv'));

[value,first_instance_idx,idx]=unique(pval_table.ROI);
pval_table_reduce=pval_table(first_instance_idx,1:5);

Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Global_MDS_0000.csv");
[output_global_overall,s_global] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('subgroup1'));

Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Regional_MDS_0000.csv");
[output_regional, s_regional] = centroid_2_centroid(Data_regional,list2cell('group1'),list2cell('subgroup1'));

output_regional=innerjoin(output_regional,pval_table_reduce,'Keys',{'ROI'});
output_regional=column_reorder(output_regional,{'vertex','ROI','structure_id','Structure','GN_Symbol','ARA_abbrev'});

values_L=[14, 26, 28, 71, 156,161]; % MOP__MotorCortex Primary, VCP__Visual_cortex_primary, SUB__subiculum, CLT__Central lateral_nucleus, cca__corpus_callosum, fim__fimbria
values_R=values_L+180;
values_T=[values_L,values_R];

%% REGIONAL MDS With Individually defined scale factors: 
idx_group=~cellfun(@isempty,regexpi(output_regional.hold,'All'));
for n=1:numel(values_T)

    idx=output_regional.vertex==values_T(n);
    idx_indiv=Data_regional.vertex==values_T(n);

    temp_out = output_regional(idx & idx_group ,:);

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for m=1:height(temp_out)
        temp_indiv_data = Data_regional(~cellfun(@isempty,regexpi(Data_regional.group1,temp_out.compare{m}))&idx_indiv,:); %& idx_indiv

        if strcmp(temp_out.compare{m},'Old')
            plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
        elseif strcmp(temp_out.compare{m},'Young')
            plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerEdgeColor',purple,'MarkerSize',6);
        end

    end

    legend('off');
    hold off

axis([-6 6 -6 6]);

xticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);
yticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);

    xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
    ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

    set(gca, 'fontsize',8*(72/96),'FontName','Arial');

    if values_T(n)>180
        print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)-180+1000),'.svg')),'-dsvg','-vector');
    else
        print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)),'.svg')),'-dsvg','-vector');
    end
end

%% Regional MDS --- sex separated

idx_group=cellfun(@isempty,regexpi(output_regional.hold,'All'));
temp_group = output_regional(idx_group ,:);

[sex,~,idx]=unique(Data_regional.subgroup1);

for o=1:height(sex)
    idx_sex=~cellfun(@isempty,regexpi(temp_group.hold,sex{o}));
    temp_out_sex=temp_group(idx_sex,:);

    for n=1:numel(values_T)

        idx=temp_out_sex.vertex==values_T(n);
        idx_indiv=Data_regional.vertex==values_T(n);

        temp_out = temp_out_sex(idx ,:);

        f=figure;
        set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
        hold on
        box on

        for m=1:height(temp_out)
		
		    age_idx=~cellfun(@isempty,regexpi(Data_regional.group1,temp_out.compare{m}));
			sex_idx=~cellfun(@isempty,regexpi(Data_regional.subgroup1,sex{o}));

			temp_indiv_data = Data_regional(age_idx&sex_idx&idx_indiv,:); %& idx_indiv
		
            if strcmp(temp_out.compare{m},'Old')
                plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
            elseif strcmp(temp_out.compare{m},'Young')
                plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerEdgeColor',purple,'MarkerSize',6);
            end

        end

        legend('off');
        hold off

        axis([-6 6 -6 6]);

        xticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);
        yticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);

        xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
        ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

        set(gca, 'fontsize',8*(72/96),'FontName','Arial');

        if values_T(n)>180
            print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_',sex{o},'_ROI_',num2str(values_T(n)-180+1000),'.svg')),'-dsvg','-vector');
        else
            print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_',sex{o},'_ROI_',num2str(values_T(n)),'.svg')),'-dsvg','-vector');
        end
    end
end

%% Regional MDS --- sex separated with C2C

idx_group=cellfun(@isempty,regexpi(output_regional.hold,'All'));
temp_group = output_regional(idx_group ,:);

[sex,~,idx]=unique(Data_regional.subgroup1);

for o=1:height(sex)
    idx_sex=~cellfun(@isempty,regexpi(temp_group.hold,sex{o}));
    temp_out_sex=temp_group(idx_sex,:);

    for n=1:numel(values_T)

        idx=temp_out_sex.vertex==values_T(n);
        idx_indiv=Data_regional.vertex==values_T(n);

        temp_out = temp_out_sex(idx ,:);

        f=figure;
        set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
        hold on
        box on

        for m=1:height(temp_out)
		
		    age_idx=~cellfun(@isempty,regexpi(Data_regional.group1,temp_out.compare{m}));
			sex_idx=~cellfun(@isempty,regexpi(Data_regional.subgroup1,sex{o}));

			temp_indiv_data = Data_regional(age_idx&sex_idx&idx_indiv,:); %& idx_indiv
		
            if strcmp(temp_out.compare{m},'Old')
                plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
            elseif strcmp(temp_out.compare{m},'Young')
                plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerEdgeColor',purple,'MarkerSize',6);
            end

        end

        legend('off');

        plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
        plot(temp_out.scaled_X1_mean(1),temp_out.scaled_X2_mean(1),'*k');
        plot(temp_out.scaled_X1_mean(2),temp_out.scaled_X2_mean(2),'*k');
        hold off

        axis([-6 6 -6 6]);

        xticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);
        yticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);

        xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
        ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

        set(gca, 'fontsize',8*(72/96),'FontName','Arial');

        if values_T(n)>180
            print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_',sex{o},'_ROI_',num2str(values_T(n)-180+1000),'_withCentroid2Centroid.svg')),'-dsvg','-vector');
        else
            print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_',sex{o},'_ROI_',num2str(values_T(n)),'_withCentroid2Centroid.svg')),'-dsvg','-vector');
        end
    end
end

%% REGIONAL MDS With C2C
idx_group=~cellfun(@isempty,regexpi(output_regional.hold,'All'));

for n=1:numel(values_T)

    idx=output_regional.vertex==values_T(n);
    idx_indiv=Data_regional.vertex==values_T(n);

    temp_out = output_regional(idx & idx_group ,:);

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for m=1:height(temp_out)
        temp_indiv_data = Data_regional(~cellfun(@isempty,regexpi(Data_regional.group1,temp_out.compare{m}))&idx_indiv,:); %& idx_indiv

        if strcmp(temp_out.compare{m},'Old')
            plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
        elseif strcmp(temp_out.compare{m},'Young')
            plot(temp_indiv_data.X1/s_regional(1,values_T(n)),temp_indiv_data.X2/s_regional(2,values_T(n)),'o','MarkerEdgeColor',purple,'MarkerSize',6);
        end

    end

    legend('off');

    plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
    plot(temp_out.scaled_X1_mean(1),temp_out.scaled_X2_mean(1),'*k');
    plot(temp_out.scaled_X1_mean(2),temp_out.scaled_X2_mean(2),'*k');
    hold off

 axis([-6 6 -6 6]);

xticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);
yticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);

    xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
    ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

    set(gca, 'fontsize',8*(72/96),'FontName','Arial');

    if values_T(n)>180
        print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)-180+1000),'_withCentroid2Centroid.svg')),'-dsvg','-vector');
    else
        print(f, fullfile(working_folder,'REGIONAL',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)),'_withCentroid2Centroid.svg')),'-dsvg','-vector');
    end
end

%% Global MDS With C2C
idx_group=~cellfun(@isempty,regexpi(output_global_overall.hold,'All'));
temp_out = output_global_overall(idx_group ,:);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
hold on
box on

for m=1:height(temp_out)
    temp_indiv_data = Data_global_overall(~cellfun(@isempty,regexpi(Data_global_overall.group1,temp_out.compare{m})),:); %& idx_indiv

    if strcmp(temp_out.compare{m},'Old')
        plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
    elseif strcmp(temp_out.compare{m},'Young')
        plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerEdgeColor',purple,'MarkerSize',6);
    end
end

legend('off');

plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
plot(temp_out.scaled_X1_mean(1),temp_out.scaled_X2_mean(1),'*k');
plot(temp_out.scaled_X1_mean(2),temp_out.scaled_X2_mean(2),'*k');
hold off

%axis([-12 12 -12 12]);
axis([-3 3 -3 3]);

xticks([-12, -9, -6, -3, -1.5, 0, 1.5, 3, 6, 9, 12]);
yticks([-12, -9, -6, -3, -1.5, 0, 1.5, 3, 6, 9, 12]);

    xtickformat('%.1f');
    ytickformat('%.1f');

xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

set(gca, 'fontsize',8*(72/96),'FontName','Arial');

print(f, fullfile(working_folder,'GLOBAL',strcat('Global_MDS_plot_withCentroid2Centroid.svg')),'-dsvg','-vector');


%% Global MDS
idx_group=~cellfun(@isempty,regexpi(output_global_overall.hold,'All'));
temp_out = output_global_overall(idx_group ,:);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
hold on
box on

for m=1:height(temp_out)
    temp_indiv_data = Data_global_overall(~cellfun(@isempty,regexpi(Data_global_overall.group1,temp_out.compare{m})),:); %& idx_indiv

    if strcmp(temp_out.compare{m},'Old')
        plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
    elseif strcmp(temp_out.compare{m},'Young')
        plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerEdgeColor',purple,'MarkerSize',6);
    end
end

legend('off');
hold off

%axis([-12 12 -12 12]);
axis([-3 3 -3 3]);

    xticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);
    yticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);

    xtickformat('%.1f');
    ytickformat('%.1f');

xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

set(gca, 'fontsize',8*(72/96),'FontName','Arial');

print(f, fullfile(working_folder,'GLOBAL',strcat('Global_MDS_plot.svg')),'-dsvg','-vector');


%% Global MDS -- sexs
idx_group=cellfun(@isempty,regexpi(output_global_overall.hold,'All'));
temp_group = output_global_overall(idx_group ,:);

[sex,~,idx]=unique(Data_global_overall.subgroup1);

for n=1:height(sex)

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    idx_sex=~cellfun(@isempty,regexpi(temp_group.hold,sex{n}));
    temp_out=temp_group(idx_sex,:);
 

    for m=1:height(temp_out)
        age_idx=~cellfun(@isempty,regexpi(Data_global_overall.group1,temp_out.compare{m}));
        sex_idx=~cellfun(@isempty,regexpi(Data_global_overall.subgroup1,sex{n}));

        temp_indiv_data = Data_global_overall(age_idx&sex_idx,:); %& idx_indiv
        if strcmp(temp_out.compare{m},'Old')
            plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
        elseif strcmp(temp_out.compare{m},'Young')
            plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerEdgeColor',purple,'MarkerSize',6);
        end

    end
    legend('off');
    hold off

    %axis([-12 12 -12 12]);
    axis([-3 3 -3 3]);

    xticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);
    yticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);
    xtickformat('%.1f');
    ytickformat('%.1f');

    xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
    ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

    set(gca, 'fontsize',8*(72/96),'FontName','Arial');

    print(f, fullfile(working_folder,'GLOBAL',strcat('Global_MDS_plot',sex{n},'.svg')),'-dsvg','-vector');
end

%% Global MDS -- sexs wC2C
idx_group=cellfun(@isempty,regexpi(output_global_overall.hold,'All'));
temp_group = output_global_overall(idx_group ,:);

[sex,~,idx]=unique(Data_global_overall.subgroup1);

for n=1:height(sex)

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    idx_sex=~cellfun(@isempty,regexpi(temp_group.hold,sex{n}));
    temp_out=temp_group(idx_sex,:);
 

    for m=1:height(temp_out)
        age_idx=~cellfun(@isempty,regexpi(Data_global_overall.group1,temp_out.compare{m}));
        sex_idx=~cellfun(@isempty,regexpi(Data_global_overall.subgroup1,sex{n}));

        temp_indiv_data = Data_global_overall(age_idx&sex_idx,:); %& idx_indiv
        if strcmp(temp_out.compare{m},'Old')
            plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerFaceColor', green,'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
        elseif strcmp(temp_out.compare{m},'Young')
            plot(temp_indiv_data.X1/s_global(1),temp_indiv_data.X2/s_global(2),'o','MarkerEdgeColor',purple,'MarkerSize',6);
        end

    end
    legend('off');

    plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
    plot(temp_out.scaled_X1_mean(1),temp_out.scaled_X2_mean(1),'*k');
    plot(temp_out.scaled_X1_mean(2),temp_out.scaled_X2_mean(2),'*k');

    hold off

    %axis([-12 12 -12 12]);
    axis([-3 3 -3 3]);

    xticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);
    yticks([-12, -9, -6, -3.0, -1.5, 0, 1.5, 3.0, 6, 9, 12]);

    xtickformat('%.1f');
    ytickformat('%.1f');
    xlabel('Dimension 1','FontSize',8*(72/96),'FontName','Arial')
    ylabel('Dimension 2','FontSize',8*(72/96),'FontName','Arial')

    set(gca, 'fontsize',8*(72/96),'FontName','Arial');

    print(f, fullfile(working_folder,'GLOBAL',strcat('Global_MDS_plot',sex{n},'_withCentroid2Centroid.svg')),'-dsvg','-vector');
end

civm_write_table(output_regional,fullfile(working_folder,'REGIONAL_MDS_centroid_to_centroid_Distance_All_Sex+All.csv'));
civm_write_table(output_global_overall,fullfile(working_folder,'GLOBAL_MDS_centroid_to_centroid_Distance_All_Sex+All.csv'));