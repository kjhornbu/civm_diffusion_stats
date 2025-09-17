function [] = top10ScalarXAxis(Current_Fig)
%Sets the X axis of the top 10 plots in the scalar plotting cleanup

y_axis_temp=ylim;

axis([0 11 y_axis_temp(1) y_axis_temp(2)]);
xlabel(Current_Fig.CurrentAxes,'Top Rank Ordered ROIs');
set(Current_Fig.CurrentAxes,'XTick',[1 2 3 4 5 6 7 8 9 10],'XTickLabels',{'', '2', '' , '4', '', '6' ,'', '8', '', '10'});

end