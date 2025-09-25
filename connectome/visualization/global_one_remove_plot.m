function [] = global_one_remove_plot(save_path,dataframe,data)

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
if ~istable(dataframe)
    temp_dataframe=dataframe;
    dataframe=civm_read_table(temp_dataframe);
end

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(strrep(data.source_of_variation,'_',' ')),data.BrainScaled_Omni_Manova)
set(gca,'YLim',[0 (height(dataframe)+1)+5])

for n=1:numel(data.BrainScaled_Omni_Manova)
    if data.BrainScaled_Omni_Manova(n)>0
        text(n-1,data.BrainScaled_Omni_Manova(n)+10,num2str(data.BrainScaled_Omni_Manova(n)),'HorizontalAlignment','center','FontSize',3,'FontName','Arial');
    end
end

xlabel('Sources of Variation');
ylabel('# of Significant 1-Remove Tests');

set(gca, 'fontsize',6,'FontName','Arial');

save_figure_file=fullfile(save_path,'Global_OneRemove.svg');
print(f,save_figure_file,'-dsvg','-vector');

end