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

[~,~,c]=unique(data.count_sig_raw_brainscaled);
set_data_size=height(dataframe)+1;
set_source_size=height(data)+1;
set_data=sum(c==1:set_source_size);

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar(categorical(data.sources),set_data)
set(gca,'XLim',[-2 set_source_size+2])
set(gca,'YLim',[0 set_data_size+5])

for n=1:numel(set_data)
    if set_data(n)>0
        text(n-1,set_data(n)+10,num2str(set_data(n)),'HorizontalAlignment','center','FontSize',3,'FontName','Arial');
    end
end

xlabel('Sources of Variation');
ylabel('Number of 1-Remove Tests');

set(gca, 'fontsize',6,'FontName','Arial');

save_figure_file=fullfile(save_path,'Global_OneRemove.svg');
print(f,save_figure_file,'-dsvg','-vector');

end