
close all;
clear all;

output_strains=table;

%% MDS

green=[0.4660 0.6740 0.1880];
purple=[0.4940 0.1840 0.5560];

Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\Global_MDS_0000.csv");
[output_global_overall,s_global] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('group2'));

Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\Regional_MDS_0000.csv");
[output_regional, s_regional] = centroid_2_centroid(Data_regional,list2cell('group1'),list2cell('group2'));

values_L=[9, 24, 26, 161, 156]; % ACC__Anterior_cingulate_cortex, RSC__Retrosplenial_cortex, VCP__Visual_cortex_primary, fim__fimbria, cca__corpus_callosum
values_R=values_L+180;
values_T=[values_L,values_R];

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
            plot(temp_indiv_data.X1/s_regional(1),temp_indiv_data.X2/s_regional(2),'o','MarkerFaceColor', [0.4660 0.6740 0.1880],'MarkerEdgeColor',[1 1 1],'MarkerSize',6);
        elseif strcmp(temp_out.compare{m},'Young')
            plot(temp_indiv_data.X1/s_regional(1),temp_indiv_data.X2/s_regional(2),'o','MarkerEdgeColor',[0.4940 0.1840 0.5560],'MarkerSize',6);
        end

    end

    legend('off');

    %plot([temp_out.scaled_X1_mean(1) temp_out.scaled_X1_mean(2)],[temp_out.scaled_X2_mean(1) temp_out.scaled_X2_mean(2)],'-k','LineWidth',1);
    %plot(temp_out.scaled_X1_mean(1),temp_out.scaled_X2_mean(1),'*k');
    %plot(temp_out.scaled_X1_mean(2),temp_out.scaled_X2_mean(2),'*k');
    hold off

    axis([-12 12 -12 12]);

    xticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);
    yticks([-12, -9, -6, -3, 0, 3, 6, 9, 12]);

    xlabel('Dimension 1','FontSize',4.5,'FontName','Arial')
    ylabel('Dimension 2','FontSize',4.5,'FontName','Arial')

    set(gca, 'fontsize',4.5,'FontName','Arial');

    if values_T(n)>180
        print(f, fullfile('Z:\All_Staff\18.gaj.42\',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)-180+1000),'.svg')),'-dsvg','-vector');
    else
        print(f, fullfile('Z:\All_Staff\18.gaj.42\',strcat('Regional_MDS_plot_ROI_',num2str(values_T(n)),'.svg')),'-dsvg','-vector');
    end
end

civm_write_table(output_regional,'Z:\All_Staff\18.gaj.42\REGIONAL_MDS_centroid_to_centroid_Distance_All_Strains+All.csv');
civm_write_table(output_global_overall,'Z:\All_Staff\18.gaj.42\GLOBAL_MDS_centroid_to_centroid_Distance_All_Strains+All.csv');


