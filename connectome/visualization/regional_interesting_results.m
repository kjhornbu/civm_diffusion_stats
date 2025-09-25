function [ ] = regional_interesting_results(save_path,data,pval_threshold)
if ispc
     printfactor=(72/96);
 end
 if ismac
     printfactor=1;
 end
 

if ~istable(data)
    temp_data=data;
    data=civm_read_table(temp_data);
end

Pval_Check=data.pval_BH<pval_threshold;
Effect_Check=data.cohenFSquared>0.35;

%% Significant
[all_sources,~,all_sources_idx]=unique(data.source_of_variation(:));

remaining_source_idx=(all_sources_idx(Pval_Check));
count_regions=sum(remaining_source_idx==1:numel(all_sources),1);

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(strrep(all_sources,'_',' ')),count_regions);
set(gca,'YLim',[0 358+10])
set(gca, 'fontsize',6,'FontName','Arial');

for n=1:numel(categorical(all_sources))
    if count_regions(n)>0
        text(categorical(all_sources(n)),count_regions(n)+10,num2str(count_regions(n)),'HorizontalAlignment','center','FontSize',6,'FontName','Arial');
    end
end

ylabel('Significantly Changed Nodes');
save_figure_file=fullfile(save_path,'Regional_SignificantSource.svg');
print(f,save_figure_file,'-dsvg','-vector');

%% Significant + Effect
remaining_source_idx=(all_sources_idx(Pval_Check&Effect_Check));
count_regions=sum(remaining_source_idx==1:numel(all_sources),1);

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(strrep(all_sources,'_',' ')),count_regions);
set(gca,'YLim',[0 358+10])
set(gca, 'fontsize',6,'FontName','Arial');

for n=1:numel(categorical(all_sources))
    if count_regions(n)>0
        text(categorical(all_sources(n)),count_regions(n)+10,num2str(count_regions(n)),'HorizontalAlignment','center','FontSize',6,'FontName','Arial');
    end
end


ylabel('Significantly Changed Nodes With Large Effects');
save_figure_file=fullfile(save_path,'Regional_Significant+LargeEffectSource.svg');
print(f,save_figure_file,'-dsvg','-vector');

end