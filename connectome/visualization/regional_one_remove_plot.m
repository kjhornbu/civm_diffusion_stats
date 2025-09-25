function [] = regional_one_remove_plot(dataframe,data)

if ispc
     printfactor=(72/96);
 end
 if ismac
     printfactor=1;
 end
 
 temp_data=data;
 data=civm_read_table(temp_data);
 valf=dir(temp_data);
 sov=strsplit(valf.name,'_');

if ~istable(dataframe)
    temp_dataframe=dataframe;
    dataframe=civm_read_table(temp_dataframe);
end

[~,~,c]=unique(data.count_sig_bh_brainscaled);
set_data_size=height(dataframe)+1;
set_data=sum(c==1:set_data_size);

f=figure;
box on;
set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3*printfactor);
bar((1:set_data_size),set_data)
set(gca,'XLim',[-2 set_data_size+2])
set(gca,'YLim',[0 360+20])

for n=1:numel(set_data)
    if set_data(n)>0
        text(n-1,set_data(n)+10,num2str(set_data(n)),'HorizontalAlignment','center','FontSize',3,'FontName','Arial');
    end
end

ylabel('Number of Significant Regions');
xlabel('Number of 1-Remove Tests');

set(gca, 'fontsize',6,'FontName','Arial');

save_figure_file=fullfile(save_path,strcat(sov{1},'_Source_Regional_OneRemove.svg'));
print(f,save_figure_file,'-dsvg','-vector');

end