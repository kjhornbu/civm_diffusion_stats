function [] = makeCohenFFig_MultiThresColors(save_location,file_name,file_extension,Group_Statistical_Result_Contrast_SoV,row_idx,row_idx_G1,row_idx_G2,row_idx_G3)

%this could be adapted to turn into a standard rank ordering plot by adding
%a criteria to rank on and other options besides CohenF. 

positional_idx_cohen_f=column_find(Group_Statistical_Result_Contrast_SoV,'cohenF$');

%Just How many results are in the data.
length_roi=ceil(numel(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f}))*10^-2)/10^-2; % round up to nearest 100's place

%The maximum of the cohen F for the set which will set the boundaries of the plot
set_top=max(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})); 

fig1=figure('PaperUnits', 'inches','PaperPosition',[0 0 1 1]*3.3);

hold on
box on

% Data of Cohen F for whole data set
plot(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f}),'.','Color',[0.9 0.9 0.9]) 

plot(row_idx_G3,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx_G3),'.','Color',[0.75 0.75 0.75]) 
plot(row_idx_G2,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx_G2),'.','Color',[0.5 0.5 0.5]) 
plot(row_idx_G1,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx_G1),'.','Color', [0.25 0.25 0.25]) 
% to do: investigate doing this as a continous color from min to max. maybe
% log scale maybe really 0-0.75?

% plot(row_idx_G3,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx_G3),'.','Color',[0.5 0.5 0.25]) 
% plot(row_idx_G2,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx_G2),'.','Color',[0.75 0.75 0.25 ]) 
% plot(row_idx_G1,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Proåperties.VariableNames{positional_idx_cohen_f})(row_idx_G1),'.','Color', [0.875 0.875 0.25 ]) 

% Data of Cohen F for interesting features
plot(row_idx,Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})(row_idx),'.r','MarkerSize',12) 

%AS DEFINED BY COHEN~ Effect Size Lines of Cohen F criteria for ANOVA.
plot([0,length_roi],[0.4,0.4],'--','color',[0.5 0.5 0.5]); %Large Effect size
text(length(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})),0.4+0.01, 'Large Effect Size','fontsize',4);
plot([0,length_roi],[0.25,0.25],'--','color',[0.5 0.5 0.5]); %Medium Effect Size
text(length(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})),0.25+0.01, 'Medium Effect Size','fontsize',4);
plot([0,length_roi],[0.1, 0.1],'--','color',[0.5 0.5 0.5]); % Small Effect Size
text(length(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})),0.1+0.01, 'Small Effect Size','fontsize',4);
text(length(Group_Statistical_Result_Contrast_SoV.(Group_Statistical_Result_Contrast_SoV.Properties.VariableNames{positional_idx_cohen_f})),0.01, 'No Effect','fontsize',4);

hold off
if set_top ~= 0
    try
        axis(fig1.CurrentAxes,[0 length_roi 0 round(set_top*1.1,1)]);
    catch
        axis(fig1.CurrentAxes,[0 length_roi 0 round(set_top*1.1,2)]);
    end
else
    axis(fig1.CurrentAxes,[0 length_roi 0 0.5]);
end

set(fig1.CurrentAxes,'fontsize',8,'fontname','Arial');

ylabel(fig1.CurrentAxes,'Cohen''s F');
xlabel(fig1.CurrentAxes,'Rank Ordered ROIs');

saveMultiOutFigure(fig1,save_location,file_name,file_extension); 
close(fig1);
end

