
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


save(fullfile(working_folder,'ASE_plots','Regional','REGIONAL_ASE_specimen_to_specimen_Distance_All+AgeGroup.csv'),'output_regional');
save(fullfile(working_folder,'ASE_plots','Global','GLOBAL_ASE_specimen_to_specimen_Distance_All+AgeGroup.csv'),'output_global_overall');


% Global ASE plot
output=struct;
f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    [G1_value,~,G1_idx]=unique(output_global_overall.group{:}(:,1));
    [G2_value,~,G2_idx]=unique(output_global_overall.group{:}(:,2));
    [SG1_value,~,SG2_idx]=unique(output_global_overall.subgroup{:}(:,1));

    for n=1:numel(G2_value)
       idx=G2_idx==n & G1_idx==1:numel(G1_value);
        
       temp=tril(output_global_overall.scaled_distance{:}(idx(:,1),idx(:,1)));
       output.(strcat('within_',G1_value{1}))=temp(temp~=0);
       temp=tril(output_global_overall.scaled_distance{:}(idx(:,2),idx(:,2)));
       output.(strcat('within_',G1_value{2}))=temp(temp~=0);
       output.(strcat('between_',G1_value{1},'_',G1_value{2}))=reshape(output_global_overall.scaled_distance{:}(idx(:,1),idx(:,2)),[],1);

       disp(G2_value{n})
       temp=output.(strcat('within_',G1_value{1}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.scaled_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

       temp=output.(strcat('within_',G1_value{2}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.scaled_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

       temp=output.(strcat('between_',G1_value{1},'_',G1_value{2}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.scaled_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

%       scaled_out_range(1,n)=range(output.(strcat('within_',G1_value{1})));
%       scaled_out_max(1,n)=max(output.(strcat('within_',G1_value{1})));
%       scaled_out_range(2,n)=range(output.(strcat('within_',G1_value{2})));
%       scaled_out_max(2,n)=max(output.(strcat('within_',G1_value{2})));
%       scaled_out_range(3,n)=range(output.(strcat('between_',G1_value{1},'_',G1_value{2})));
%       scaled_out_max(3,n)=max(output.(strcat('between_',G1_value{1},'_',G1_value{2})));

       plot(3*(n-1)+(1*ones(numel(output.(strcat('within_',G1_value{1}))),1)),output.(strcat('within_',G1_value{1})),'.')
       plot(3*(n-1)+(2*ones(numel(output.(strcat('within_',G1_value{2}))),1)),output.(strcat('within_',G1_value{2})),'.')
       plot(3*(n-1)+(3*ones(numel(output.(strcat('between_',G1_value{1},'_',G1_value{2}))),1)),output.(strcat('between_',G1_value{1},'_',G1_value{2})),'.')

       full_x{3*(n-1)+1}=strcat(G2_value{n},'_','within_',G1_value{1});
       full_x{3*(n-1)+2}=strcat(G2_value{n},'_','within_',G1_value{2});
       full_x{3*(n-1)+3}=strcat(G2_value{n},'_between_',G1_value{1},'_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
%     temp_xa=temp_x;
%     temp_x{1}=temp_x{13};
%     temp_x{2}=temp_x{14};
%     temp_x{3}=temp_x{15};
%     temp_x{13}=temp_xa{1};
%     temp_x{14}=temp_xa{2};
%     temp_x{15}=temp_xa{3};

    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Scaled_Distances.svg')),'-dsvg','-vector');

% Global ASE plot
output=struct;

f=figure;
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
    hold on
    box on

    [G1_value,~,G1_idx]=unique(output_global_overall.group{:}(:,1));
    [G2_value,~,G2_idx]=unique(output_global_overall.group{:}(:,2));
    [SG1_value,~,SG2_idx]=unique(output_global_overall.subgroup{:}(:,1));

    for n=1:numel(G2_value)
        idx=G2_idx==n & G1_idx==1:numel(G1_value);
        
       temp=tril(output_global_overall.raw_distance{:}(idx(:,1),idx(:,1)));
       output.(strcat('within_',G1_value{1}))=temp(temp~=0);
       temp=tril(output_global_overall.raw_distance{:}(idx(:,2),idx(:,2)));
       output.(strcat('within_',G1_value{2}))=temp(temp~=0);
       output.(strcat('between_',G1_value{1},'_',G1_value{2}))=reshape(output_global_overall.raw_distance{:}(idx(:,1),idx(:,2)),[],1);

       disp(G2_value{n})
       temp=output.(strcat('within_',G1_value{1}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.raw_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

       temp=output.(strcat('within_',G1_value{2}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.raw_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

       temp=output.(strcat('between_',G1_value{1},'_',G1_value{2}));
       temp=temp(temp~=0);
       check=isoutlier(temp);
       disp(sum(check));
       positional_check=find(check);
      for m=1:numel(positional_check)
          [a,b]=find(output_global_overall.raw_distance{:}==temp(positional_check(m)));
          output_global_overall.specimen{1}(a,:)
      end

% 
%       raw_out_range(1,n)=range(output.(strcat('within_',G1_value{1})));
%       raw_out_max(1,n)=max(output.(strcat('within_',G1_value{1})));
%       raw_out_range(2,n)=range(output.(strcat('within_',G1_value{2})));
%       raw_out_max(2,n)=max(output.(strcat('within_',G1_value{2})));
%       raw_out_range(3,n)=range(output.(strcat('between_',G1_value{1},'_',G1_value{2})));
%       raw_out_max(3,n)=max(output.(strcat('between_',G1_value{1},'_',G1_value{2})));

       plot(3*(n-1)+(1*ones(numel(output.(strcat('within_',G1_value{1}))),1)),output.(strcat('within_',G1_value{1})),'.')
       plot(3*(n-1)+(2*ones(numel(output.(strcat('within_',G1_value{2}))),1)),output.(strcat('within_',G1_value{2})),'.')
       plot(3*(n-1)+(3*ones(numel(output.(strcat('between_',G1_value{1},'_',G1_value{2}))),1)),output.(strcat('between_',G1_value{1},'_',G1_value{2})),'.')

       full_x{3*(n-1)+1}=strcat(G2_value{n},'_','within_',G1_value{1});
       full_x{3*(n-1)+2}=strcat(G2_value{n},'_','within_',G1_value{2});
       full_x{3*(n-1)+3}=strcat(G2_value{n},'_between_',G1_value{1},'_',G1_value{2});
    end
    temp_x=strrep(full_x,'_',' ');
%     temp_xa=temp_x;
%     temp_x{1}=temp_x{13};
%     temp_x{2}=temp_x{14};
%     temp_x{3}=temp_x{15};
%     temp_x{13}=temp_xa{1};
%     temp_x{14}=temp_xa{2};
%     temp_x{15}=temp_xa{3};

    xticks(1:numel(full_x));
    xticklabels(temp_x);
    set(gca, 'fontsize',4.5,'FontName','Arial');

    print(f, fullfile(working_folder,'ASE_plots','Global',strcat('Global_Specimen_to_Specimen_Raw_Distances.svg')),'-dsvg','-vector');