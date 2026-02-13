function [] = makeindivFig(save_location_update,file_name,file_extension,Interesting_Data_Table,Interesting_Data_Table_Group,source_of_variation,Contrast,name_mean,name_std,name_abb)
%% FIGURE THREE --- INDIV SPECIMEN DATA : With Region Abbrevation
[~,group_indiv_name,group_indiv_name_idx] = find_group_information_from_groupingcriteria(Interesting_Data_Table,strsplit(source_of_variation,':'));
[~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(Interesting_Data_Table_Group,strsplit(source_of_variation,':'));

fig3=figure('PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3);

hold on
box on
grid on

for n=1:numel(group_indiv_name) %each group
    Interesting_Data_Table_groupsubset=Interesting_Data_Table(group_indiv_name_idx==n,:);

    [~,~,Interesting_Data_Table_groupsubset.idx]=unique(Interesting_Data_Table_groupsubset.ROI,'stable');

    offset=(rand(size(Interesting_Data_Table_groupsubset,1),1)-0.5)/5;

    plot(Interesting_Data_Table_groupsubset.idx+offset,Interesting_Data_Table_groupsubset.(Contrast)','o','Markersize',3)
    %plot(Interesting_Data_Table_groupsubset.idx+offset,Interesting_Data_Table_groupsubset.(Contrast)','o','Markersize',4)
    %plot(Interesting_Data_Table_groupsubset.idx+offset,Interesting_Data_Table_groupsubset.(Contrast)','o','Markersize',1)
    %prior tiny dots == MarkerSize 1
end

hold off

top10ScalarXAxis(fig3);
[low_bound,top_bound] = findDataBounds(Interesting_Data_Table_Group,name_mean,name_std); %Use Group data to get bounds
top10ScalarYAxis(fig3,Contrast,low_bound,top_bound);

createDataAbbrevLabels(Interesting_Data_Table_Group(group_name_idx==1,:),name_mean,name_std,name_abb);%Use Group data to place information

setscalarlegend(fig3,group_indiv_name);
saveMultiOutFigure(fig3,save_location_update,file_name,file_extension);
close(fig3);
end