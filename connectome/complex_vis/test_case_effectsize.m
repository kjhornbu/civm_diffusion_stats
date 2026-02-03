function [out_large,out_NOT_large,out_gt_100,out_NOT_gt_100] = test_case_effectsize(output_connectome,matrix_2_print_blue,matrix_2_print_cohenD,matrix_2_print_percent,selection_pull,ROI,top_15_vertex_idx)
%This selects large effects (big percent changes, large cohenD) and
%compares it visually with what you have captured as "key vertices" it also
%filter the connectomic data for large effect and not large effect for percent change
%and cohenD so we can see what values of edge strengths are providing
%either.

saving_path=fullfile("B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall",'Effect_v_MeanConnectome_EffectAdded_Feb02');
mkdir(saving_path);

mkdir(fullfile(saving_path,'CohenD'));
mkdir(fullfile(saving_path,'Percent'));
mkdir(fullfile(saving_path,'Percent_Tight'));

%% Making test figures for illustrating effect size issues -- For specific case of project--CHDI
blue_All_idx=reshape([reg_match(selection_pull,'All'),reg_match(selection_pull,'All')]',[],1);
N_entries=output_connectome.N(reg_match(output_connectome.selection_group,'All') & (output_connectome.ROI==ROI));
sum_N_entries=sum(N_entries);
blue_mean_data=mean((N_entries/sum_N_entries).*matrix_2_print_blue(blue_All_idx,:));
%These aren't in ontology order until they are in the matrix_2_print --
%don't use the output_difference here!!
cohenD_All_data=matrix_2_print_cohenD(reg_match(selection_pull,'All'),:);
percent_All_data=matrix_2_print_percent(reg_match(selection_pull,'All'),:);

green=[0.4660 0.6740 0.1880];
purple=[0.4940 0.1840 0.5560];

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 2]*3.3*(72/96));

semilogy(cohenD_All_data,blue_mean_data,'.');
xlabel('All - CohenD Effect')
ylabel('Log 10 of Mean Connectome Value')
hold on
semilogy(cohenD_All_data(top_15_vertex_idx),blue_mean_data(top_15_vertex_idx),'r.')
idx_large_effect=abs(cohenD_All_data)>0.8;
semilogy(cohenD_All_data(idx_large_effect),blue_mean_data(idx_large_effect),'o','Color',green);

ax=gca;

semilogy([0.8 0.8],[ax.YLim(1) ax.YLim(2)],'k--')
semilogy([0.5 0.5],[ax.YLim(1) ax.YLim(2)],'k--')
semilogy([0.2 0.2],[ax.YLim(1) ax.YLim(2)],'k--')

semilogy([-0.8 -0.8],[ax.YLim(1) ax.YLim(2)],'k--')
semilogy([-0.5 -0.5],[ax.YLim(1) ax.YLim(2)],'k--')
semilogy([-0.2 -0.2],[ax.YLim(1) ax.YLim(2)],'k--')

print(f, fullfile(saving_path,'CohenD',strcat('CohenD_v_MeanConnectome_vertex_',num2str(ROI),'.png')),'-dpng','-r600');

    out_large=blue_mean_data(idx_large_effect);
    out_NOT_large=blue_mean_data(~idx_large_effect);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 2]*3.3*(72/96));

semilogy(100*percent_All_data,blue_mean_data,'.');
xlabel('All - Percent Change')
ylabel('Log 10 of Mean Connectome Values')
hold on
semilogy(100*percent_All_data(top_15_vertex_idx),blue_mean_data(top_15_vertex_idx),'r.')
idx_gt_100=abs(percent_All_data)>1;
semilogy(100*percent_All_data(idx_gt_100),blue_mean_data(idx_gt_100),'o','Color',green);
print(f, fullfile(saving_path,'Percent',strcat('Percent_v_MeanConnectome_vertex_',num2str(ROI),'.png')),'-dpng','-r600');

ax=gca;
axis([-100 100 ax.YLim(1) ax.YLim(2)])
print(f, fullfile(saving_path,'Percent_Tight',strcat('Percent_v_MeanConnectome_vertex_',num2str(ROI),'.png')),'-dpng','-r600');

close all;

    out_gt_100=blue_mean_data(idx_gt_100);
    out_NOT_gt_100=blue_mean_data(~idx_gt_100);

end