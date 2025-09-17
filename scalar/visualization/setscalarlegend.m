function [] = setscalarlegend(Current_Fig,Legend_Information)
%setting figure legend

if size(Legend_Information,1)>4
    legend(Current_Fig.CurrentAxes,Legend_Information,'Location','northoutside','NumColumns',4,'FontSize',3);
else
    legend(Current_Fig.CurrentAxes,Legend_Information,'Location','northoutside','Orientation','horizontal','FontSize',3);
end


end