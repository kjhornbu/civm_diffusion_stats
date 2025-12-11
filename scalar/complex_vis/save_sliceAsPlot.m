function save_sliceAsPlot(image_matrix,position_matrix,out,alpha_mask)
% image_matrix is single value scalar, or color on 3rd dim
% position_matrix is matlab figure sizing.
% out is struct of paths with elemetns png,svg OR single file path.
% alpha_mask(optional) is 2-D at same size as image-matrix first two dimensions.
% (I think alpha_mask can be either 8-bit values OR 0-1.)


% for our text labels of label images we have to save as a figure.
% This function exists to allow us to have a matching image for that
% behavior.
% 
% Ideally we'd figure out the margin problem and fix the text containing
% svg file instead.
% Ultimately, james may put the svg creation into a literal script instead
% of using matlab.
%

%% validate we dont have too many points to plot, 
total_entry=numel(image_matrix);
counts_of_entry=nnz(image_matrix);
if exist('alpha_mask','var') && ~isempty(alpha_mask) 
    counts_of_entry=nnz(alpha_mask);
end
pct_of_entry=counts_of_entry/total_entry;
% currently working with a fraction, 
% but it is a literal limit, 
% so this should become hard coded to a number in the future.
% in testing, ~50000 worked. 
assert(pct_of_entry < 0.15, 'TOO MANY DATA points to plot! this save mode is not appropriate');

figN=125;

%% guess missing alpha mask
if ~exist('alpha_mask','var')||  isempty(alpha_mask)
    % IF we were given color data, the max will force 3rd dimension back to 1.
    % Otherwise it has no impact.
    alpha_mask=max(image_matrix>0,[],3);
end

slice_size=size(image_matrix,[1,2]);
%% get image index, and data_for_plot
% img_idx MAY be identical to alpha_mask
img_idx=alpha_mask>0;
if ndims(image_matrix)~=ndims(alpha_mask) ...
        || ~all(size(image_matrix)==size(alpha_mask))
    ii_idx=repmat(img_idx,[1,1,size(image_matrix,3)]);
else 
    ii_idx=img_idx;
end
data_for_plot=image_matrix(ii_idx);
if size(image_matrix,3)==3
    data_for_plot=reshape(data_for_plot,[],3);
end
clear('ii_idx');

min_color=min(data_for_plot);
max_color=max(data_for_plot);
if all(min_color==max_color)
    color=max_color;
    cx=unique(color);
    if numel(cx)==1
        data_val=cx;
    else
    warning('unimplemented');
        keyboard;
    end
    if any(color>1)
        color=double(color)/255;
        color(color==1)=0.99999;
    end
else
    warning('unimplemented');
    keyboard;
end

% WARNING: added flipdim to handle issue introduced by using imshow.
%[y_coord,x_coord]=find(image_matrix==data_val);
[y_coord,x_coord]=find(img_idx);

% force close this figure to reset it.
if ishandle(figN)
    close(figN);
end
fig_h=figure(figN);
fig_h.PaperUnits='centimeters';
% THIS IS PROBABLY causing a scale issue on output.
% fig_h.PaperPosition=position_matrix;

% cannot simply skip image matrix, it is a critical trick in getting the
% proper plot size. Need a replacement trick!(OMG... it may also force an
% unexpected flip on tall dimension)
%imshow(image_matrix');

blank=255*ones(slice_size,'uint8');
im_bkgrd=imshow(blank);
if exist('alpha_mask','var') && ~isempty(alpha_mask)
    % this alpha handling MAY interfere with expected operation.
    im_bkgrd.AlphaData=alpha_mask;%set alpha channel to zero in the background image
else
    im_bkgrd.AlphaData=0;%set alpha channel to zero in the background image
end

hold on;
% before adjusting inputs in slice_saver such that they're uniform, the
% subtraction was necessary.
%p=plot(x_coord,slice_size(2)-y_coord,'.','MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',3/2);%Marker size is in points where 72 points == 1 inch. -- Seemingly doesn't change when <1
p=plot(x_coord,y_coord,'.','MarkerFaceColor',color,'MarkerEdgeColor',color,'MarkerSize',3/2);%Marker size is in points where 72 points == 1 inch. -- Seemingly doesn't change when <1
hold off;

fig_h.Units='centimeters';
fig_h.InnerPosition=position_matrix;
box on;
%axis([0 image_matrix_size(1) 0 image_matrix_size(2)]);
xticks(0);
xticklabels("");
yticks(0);
yticklabels("");
%figure(figN);% pulls figure in front on purpose, only useful when debugging.

print(fig_h,out.svg,'-vector','-dsvg'); %Wait svg don't have resolution? --- the data within is making a png which has crappy resolution
close(figN);

%convert the sizes of the dots in the svg

text_content=extractFileText(out.svg);
text_content=strrep(text_content,'circle r="0.5"','circle r="0.1"');

fileID=fopen(out.svg,"w");
fprintf(fileID,'%s',text_content);
fclose(fileID);

