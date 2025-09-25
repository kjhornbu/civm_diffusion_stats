function [ ] = global_interesting_results(save_path,data,pval_threshold)
if ispc
     printfactor=1;
 end
 if ismac
     printfactor=(72/96);
 end
 

if ~istable(data)
    temp_data=data;
    data=civm_read_table(temp_data);
end

f=figure;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 0.5 (height(data)/6)]*3.3*printfactor);

Pval_Check=data.pval<pval_threshold;
Effect_Check=data.cohenFSquared>0.35;

for n=1:numel(Pval_Check)
    if Pval_Check(n)
        %green
        rectangle('Position',[0 n 1 1],'FaceColor',[0 1 0],'EdgeColor',[1 1 1]);
    else
        %red
        rectangle('Position',[0 n 1 1],'FaceColor',[1 0 0],'EdgeColor',[1 1 1]);
    end
    if Pval_Check(n) && Effect_Check(n)
        %green
        rectangle('Position',[1 n 1 1],'FaceColor',[0 1 0],'EdgeColor',[1 1 1]);
    else
        %red
        rectangle('Position',[1 n 1 1],'FaceColor',[1 0 0],'EdgeColor',[1 1 1]);
    end
end

ytick_positions=(1:numel(Pval_Check))+0.5;
ylabel('Sources of Variation');
yticks(ytick_positions);
yticklabels(strrep(data.source_of_variation,'_',' '));

xtick_positions=[0.5 1.5];
xticks(xtick_positions);
xticklabels({'Significant Pvalue'; 'Signficant Pvalue +\newlineLarge Effect'});


set(gca, 'fontsize',3,'FontName','Arial');
save_figure_file=fullfile(save_path,'Global_SignificantSource_Significant+LargeEffectSource.svg');
print(f,save_figure_file,'-dsvg','-vector');

end