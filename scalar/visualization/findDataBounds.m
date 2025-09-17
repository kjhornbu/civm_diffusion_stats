function [low_bound,top_bound] = findDataBounds(Descriptive_Data_Reduce,name_mean,name_std)
%Finding the nearest order to the max min range of the graph
%adding/subtracting std to add headroom

Mean_Data=Descriptive_Data_Reduce.(name_mean);
STD_Data=Descriptive_Data_Reduce.(name_std);

top_bound=10^(log10(abs(max(Mean_Data+STD_Data)))+0.1);
low_bound=10^(log10(abs(min(Mean_Data-STD_Data)))-0.1);

end