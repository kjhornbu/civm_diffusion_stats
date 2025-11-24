function [] = global_one_remove_plot(save_path,dataframe,data)
file_extension={'png','svg'};

if ispc
    printfactor=(72/96);
end
if ismac
    printfactor=1;
end

if ~istable(data)
    temp_data=data;
    try
        data=civm_read_table(temp_data);
    catch
        data=readtable(temp_data);
        data(:,2)=data(:,1);
        data=data(2:end,:);
    end
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
        text(n,data.BrainScaled_Omni_Manova(n)+10,num2str(data.BrainScaled_Omni_Manova(n)),'HorizontalAlignment','center','FontSize',3*printfactor,'FontName','Arial');
    end
end

ylim([0,round(max(data.BrainScaled_Omni_Manova+10)*1.1)]);

xlabel('Sources of Variation');
ylabel('# of Significant 1-Remove Tests');

set(gca, 'fontsize',6*printfactor,'FontName','Arial');

file_name='Global_OneRemove-BrainScaled';
saveMultiOutFigure(f,fullfile(save_path,'OneRemove'),file_name,file_extension)

end