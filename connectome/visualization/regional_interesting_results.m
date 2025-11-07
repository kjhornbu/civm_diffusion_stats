function [ ] = regional_interesting_results(save_path,data,pval_threshold)
file_extension={'png','svg'};
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

all_sources=strrep(all_sources,'_',' ');
f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(all_sources),count_regions);
set(gca,'YLim',[0 (numel(Pval_Check)/numel(all_sources))+10])
set(gca, 'fontsize',6,'FontName','Arial');

for n=1:numel(categorical(all_sources))
    if count_regions(n)>0
        text(categorical(all_sources(n)),count_regions(n)+10,num2str(count_regions(n)),'HorizontalAlignment','center','FontSize',6,'FontName','Arial');
    end
end

ylabel('Significantly Changed Nodes');
file_name='Regional_Significant';
saveMultiOutFigure(f,save_path,file_name,file_extension)

%% Significant + Effect
remaining_source_idx=(all_sources_idx(Pval_Check&Effect_Check));
count_regions=sum(remaining_source_idx==1:numel(all_sources),1);

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(all_sources),count_regions);
set(gca,'YLim',[0 (numel(Pval_Check)/numel(all_sources))+10])
set(gca, 'fontsize',6,'FontName','Arial');

for n=1:numel(categorical(all_sources))
    if count_regions(n)>0
        text(categorical(all_sources(n)),count_regions(n)+10,num2str(count_regions(n)),'HorizontalAlignment','center','FontSize',6,'FontName','Arial');
    end
end
ylabel('Significantly Changed Nodes With Large Effects');

file_name='Regional_Significant+LargeEffectSource';
saveMultiOutFigure(f,save_path,file_name,file_extension)


end