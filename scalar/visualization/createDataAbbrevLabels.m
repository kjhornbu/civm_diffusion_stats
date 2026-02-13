function [] = createDataAbbrevLabels(Descriptive_Data_Reduce,name_mean,name_std,name_abb)

data_length=1:height(Descriptive_Data_Reduce);

Mean_Data=Descriptive_Data_Reduce.(name_mean);
STD_Data=Descriptive_Data_Reduce.(name_std);

y_position=Mean_Data(data_length)-STD_Data(data_length);

for n=data_length
    temp=strsplit(Descriptive_Data_Reduce.(name_abb){n},'__');
    abb{n}=temp{1};
end

text_set=abb(:);

text((data_length)+0.25,y_position, text_set,'fontsize',4,'FontName','Arial','HorizontalAlignment','left'); %4

end