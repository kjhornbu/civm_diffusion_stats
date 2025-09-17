function [] = makegroupFig(save_location_update,file_name,file_extension,Interesting_Data_Table,source_of_variation,Contrast,name_mean,name_std,name_abb)
%% FIGURE TWO --- Group Wise Mean and STD: With Region Abbrevation

[~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(Interesting_Data_Table,strsplit(source_of_variation,':'));

fig2=figure('PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3);

hold on
box on
grid on

for n=1:numel(group_name) %each group
    Interesting_Data_Table_groupsubset=Interesting_Data_Table(group_name_idx==n,:);
    errorbar(1:size(Interesting_Data_Table_groupsubset,1),Interesting_Data_Table_groupsubset.(name_mean)(:),Interesting_Data_Table_groupsubset.(name_std)(:),'.');
end

hold off

top10ScalarXAxis(fig2);
[low_bound,top_bound] = findDataBounds(Interesting_Data_Table,name_mean,name_std);
top10ScalarYAxis(fig2,Contrast,low_bound,top_bound);

createDataAbbrevLabels(Interesting_Data_Table_groupsubset,name_mean,name_std,name_abb);
setscalarlegend(fig2,group_name);
%file_name=strcat(Contrast,'_Group_Data_Fig');
%file_extension={'png'};
saveMultiOutFigure(fig2,save_location_update,file_name,file_extension);
close(fig2);
end