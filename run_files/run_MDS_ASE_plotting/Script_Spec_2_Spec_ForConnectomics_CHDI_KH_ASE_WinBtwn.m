
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

save(fullfile(working_folder,'ASE_plots','Regional','REGIONAL_ASE_specimen_to_specimen_Distance_All+AgeGroup.csv'),'output_regional');
save(fullfile(working_folder,'ASE_plots','Global','GLOBAL_ASE_specimen_to_specimen_Distance_All+AgeGroup.csv'),'output_global_overall');


% Global ASE plot
output=struct;


    [G1_value,~,G1_idx]=unique(output_global_overall.group{:}(:,1));
    [G2_value,~,G2_idx]=unique(output_global_overall.group{:}(:,2));
    [SG1_value,~,SG2_idx]=unique(output_global_overall.subgroup{:}(:,1));

    for n=1:numel(G2_value)
       idx=G2_idx==n & G1_idx==1:numel(G1_value);
        
       temp=tril(output_global_overall.scaled_distance{:}(idx(:,1),idx(:,1)));
       output.(strcat(G2_value{n},'within_',G1_value{1}))=temp(temp~=0);
       temp=tril(output_global_overall.scaled_distance{:}(idx(:,2),idx(:,2)));
       output.(strcat(G2_value{n},'within_',G1_value{2}))=temp(temp~=0);
       output.(strcat(G2_value{n},'between_',G1_value{1},'_',G1_value{2}))=reshape(output_global_overall.scaled_distance{:}(idx(:,1),idx(:,2)),[],1);
    end


    G2_value_v2={'Two';'Six';'Ten';'Twelve';'Fifteen'};
    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for n=1:numel(G2_value_v2)
        plot((n-1)+(1*ones(numel(output.(strcat(G2_value_v2{n},'within_',G1_value{1}))),1)),output.(strcat(G2_value_v2{n},'within_',G1_value{1})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_','within_',G1_value{1});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    axis([0 6 0 6])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Scaled_Distances_Within',G1_value{1},'Graph.svg')),'-dsvg','-vector');


    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on
    
    for n=1:numel(G2_value_v2)
        plot((n-1)+(ones(numel(output.(strcat(G2_value_v2{n},'within_',G1_value{2}))),1)),output.(strcat(G2_value_v2{n},'within_',G1_value{2})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_','within_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');
    
    axis([0 6 0 6])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Scaled_Distances_Within',G1_value{2},'Graph.svg')),'-dsvg','-vector');

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on
    
    for n=1:numel(G2_value_v2)
        plot((n-1)+(ones(numel(output.(strcat(G2_value_v2{n},'between_',G1_value{1},'_',G1_value{2}))),1)),output.(strcat(G2_value_v2{n},'between_',G1_value{1},'_',G1_value{2})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_between_',G1_value{1},'_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    axis([0 6 0 6])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Scaled_Distances_BetweenGraph.svg')),'-dsvg','-vector');

% Global ASE plot

output=struct;

    [G1_value,~,G1_idx]=unique(output_global_overall.group{:}(:,1));
    [G2_value,~,G2_idx]=unique(output_global_overall.group{:}(:,2));
    [SG1_value,~,SG2_idx]=unique(output_global_overall.subgroup{:}(:,1));

    for n=1:numel(G2_value)
       idx=G2_idx==n & G1_idx==1:numel(G1_value);
        
       temp=tril(output_global_overall.raw_distance{:}(idx(:,1),idx(:,1)));
       output.(strcat(G2_value{n},'within_',G1_value{1}))=temp(temp~=0);
       temp=tril(output_global_overall.raw_distance{:}(idx(:,2),idx(:,2)));
       output.(strcat(G2_value{n},'within_',G1_value{2}))=temp(temp~=0);
       output.(strcat(G2_value{n},'between_',G1_value{1},'_',G1_value{2}))=reshape(output_global_overall.raw_distance{:}(idx(:,1),idx(:,2)),[],1);
    end


    G2_value_v2={'Two';'Six';'Ten';'Twelve';'Fifteen'};
    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    for n=1:numel(G2_value_v2)
        plot((n-1)+(1*ones(numel(output.(strcat(G2_value_v2{n},'within_',G1_value{1}))),1)),output.(strcat(G2_value_v2{n},'within_',G1_value{1})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_','within_',G1_value{1});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    axis([0 6 0 12])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Raw_Distances_Within',G1_value{1},'Graph.svg')),'-dsvg','-vector');


    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on
    
    for n=1:numel(G2_value_v2)
        plot((n-1)+(ones(numel(output.(strcat(G2_value_v2{n},'within_',G1_value{2}))),1)),output.(strcat(G2_value_v2{n},'within_',G1_value{2})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_','within_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    axis([0 6 0 12])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Raw_Distances_Within',G1_value{2},'Graph.svg')),'-dsvg','-vector');

    f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on
    
    for n=1:numel(G2_value_v2)
        plot((n-1)+(ones(numel(output.(strcat(G2_value_v2{n},'between_',G1_value{1},'_',G1_value{2}))),1)),output.(strcat(G2_value_v2{n},'between_',G1_value{1},'_',G1_value{2})),'.')
        full_x{(n-1)+1}=strcat(G2_value_v2{n},'_between_',G1_value{1},'_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    axis([0 6 0 12])
    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Raw_Distances_BetweenGraph.svg')),'-dsvg','-vector');
