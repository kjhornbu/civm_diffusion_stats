function save_sliceAsFigure(image_matrix,position_matrix,out,alpha_mask)
% for our text labels of label images we have to save as a figure.
% This function exists to allow us to have a matching image for that
% behavior.
% 
% Ideally we'd figure out the margin problem and fix the text containing
% svg file instead.
% Ultimately, james may put the svg creation into a literal script instead
% of using matlab.
%
figN=124;
% force close this figure to reset it.
figure_close(figN);
fig_h=figure(figN);
% fancy run at function end to close the figure
C___={};C___{end+1}=onCleanup(@() figure_close(figN) );

fig_h.PaperUnits='centimeters';
% THIS IS PROBABLY causing a scale issue on output.
% fig_h.PaperPosition=position_matrix;

%%% FIXED SEE CHANGE
%%% eeep, "image_matrix==255" is a bad assumption, this is only true for our first image matrix... 
%%% eventually, should force this code to allow an alpha mask, then for
%%% only those points which are part of the alpha mask, plot a point using
%%% that color(or greyscale intensity) of the data.
%%%
%%% that all sounds like a functon with a name like
%%% "save_figure_point_slice" --- Right now this function is better named
%%% by something like save_rasterLine_figure_slice

% cannot simply skip image matrix, it is a critical trick in getting the
% proper plot size. Need a replacement trick!(OMG... it may also force an
% unexpected flip on tall dimension)
im_h=imshow(image_matrix);
if exist('alpha_mask','var') && ~isempty(alpha_mask)
    im_h.AlphaData=alpha_mask;%set alpha channel to zero in the background image
end
fig_h.Units='centimeters';
fig_h.InnerPosition=position_matrix;
box on;
xticks(0);
xticklabels("");
yticks(0);
yticklabels("");
%figure(figN);% pulls figure in front on purpose, only useful when debugging.

print(fig_h,out.svg,'-vector','-dsvg'); %Wait svg don't have resolution? --- the data within is making a png which has crappy resolution
close(figN);



