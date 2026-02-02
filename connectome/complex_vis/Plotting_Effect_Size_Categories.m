function [] = Plotting_Effect_Size_Categories(out_gt_100,out_NOT_gt_100,out_large,out_NOT_large)

saving_path=fullfile("B:\24.chdi.01-PHASE2\stats\Hornburg_Stat_20260115_overall",'Effect_v_MeanConnectome');
mkdir(saving_path);

%% Making a graph illustrating where there are very high and very low
% percent changes occur in terms of counts

%% Figure 2 -- Histogram of LARGE PERCENT
f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
histogram(log10(out_gt_100))
hold on
histogram(log10(out_NOT_gt_100))

ylabel('Count');
xlabel('Log 10 (Edge Strength)');

legend({'|%Change| > 100%','|%Change| < 100%'},Location="northoutside");

print(f, fullfile(saving_path,'Blown-up_PercentagesGraph_atDifferentEdgeStrengths_Histogram.png'),'-dpng','-r600');


%% Figure 2 -- CDF of LARGE PERCENT

[a,b]=ecdf(out_gt_100);
[a2,b2]=ecdf(out_NOT_gt_100);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));

semilogx(b,100*a);
hold on
semilogx(b2,100*a2);

legend({'|%Change| > 100%','|%Change| < 100%'},Location="northoutside");

ylabel('Cumulative Probability');
xlabel('Edge Strength');
set(gca,'FontSize',6,'FontName','Arial'); %6 == 4.5 on mac

print(f, fullfile(saving_path,'Blown-up_PercentagesGraph_atDifferentEdgeStrengths.png'),'-dpng','-r600');

%% Figure 3 -- HISTOGRAM of COHEN D
f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));
histogram(log10(out_large))
hold on
histogram(log10(out_NOT_large))

ylabel('Count');
xlabel('Log 10 (Edge Strength)');

legend({'Large Effect','NOT Large Effect'},Location="northoutside");

print(f, fullfile(saving_path,'LargeEffectSize_atDifferentEdgeStrengths_Histogram.png'),'-dpng','-r600');

%% Figure 4 -- CDF of COHEN D
[a,b]=ecdf(out_large);
[a2,b2]=ecdf(out_NOT_large);

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*(72/96));

semilogx(b,100*a);
hold on
semilogx(b2,100*a2);

legend({'Large Effect','NOT Large Effect'},Location="northoutside");

ylabel('Cumulative Probability');
xlabel('Edge Strength');
set(gca,'FontSize',6,'FontName','Arial'); %6 == 4.5 on mac

print(f, fullfile(saving_path,'LargeEffectSize_atDifferentEdgeStrengths.png'),'-dpng','-r600');

end