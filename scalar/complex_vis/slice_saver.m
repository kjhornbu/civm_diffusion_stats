function slice_saver(img_slice,filename,mode)
% takes one of our color slice images and saves it. 
% Expects 3-D input where the 3rd dimension has 3 or 4 elements.
% When there are 4 elements the 4th is used as the alpha mask.
assert( size(img_slice,3) <= 4, 'unexpected image size, only 2-D grey or color supported. Alpha-channel allowed');

[p,n,~]=fileparts(filename);
[out]=figure_out_struct(path_convert_platform(fullfile(p,n),'native'));

% The height is tricky, 3.5 is good for normal sized figures...
% Internally the png2svg perl code presumes 96dpi... that may be an issue.
% (That is only a factor for save_sliceAsImage.)
%height=8.5/2;
out_height=3.5;
% warning: mac/(windows+linux) fight over behavior of setting size.
% all appear to use an imaginary (AS IN IT HAS NOTHING TO DO WITH THE REAL
% DISPLAY RESOLUTION) dots-per-inch, with mac stuck at 72, and
% windows+linux stuck at 96 (the story may be more complex for linux).
% IF on mac, out_height may need to be adjusted to match the behavior of 
% other functions.

% this is the 'pixel' size coded into the svgs from the perl png2svg code 
% when using height 3.5cm 
% 0 0 78.740157480315 132.283464566929

% 1.1x1.8 inches
% 1.1*2.54 *(72/96)
% 1.8*2.54 *(72/96)

out_height=3.5*(72/96);
position_matrix = [0 0 0 0];

%Smallest non color Dim of data is 3.3 repeating inches
slice_size=size(img_slice);
[smallDim,smallDim_idx]=min([slice_size(1),slice_size(2)]);
[bigDim,bigDim_idx]=max([slice_size(1),slice_size(2)]);

%row column flip in imagesc so force a flip here by inverting big and small
position_matrix(smallDim_idx+2)=out_height;
position_matrix(bigDim_idx+2)=(bigDim/smallDim)*out_height;

% force largest dimension to be height cm tall
position_matrix=position_matrix/max(position_matrix)*out_height;

% move it of the bottom corner so its not obscured by doc/start bar
position_matrix(1:2)=4;

alpha_mask=[];
if 1 < size(img_slice,3)
    % have alpha chanel(we have EITHER 4 or 2 entries)
    alpha_mask=img_slice(:,:,end);
    img_slice(:,:,end)=[];

end
if size(img_slice,3) == 3 && max(reshape(img_slice(:,:,2:3),1,[]))==0
    % empty slices 2-3 due to forced convention of 4-elements per
    % co-ordinate. But we just want a greyscale.
    % Note, MAY NOT save correctly for all modes, that's on you.
    img_slice(:,:,2:3)=[];
end
img_slice=permute(img_slice,[2 1 3]);
if ~isempty(alpha_mask)
    alpha_mask=permute(alpha_mask,[2 1 3]);
end
if reg_match(mode,'image')
    assert( isa(img_slice,'uint8'), 'Unexpected data type for image mode, expecting color-image compatible 8-bit data.');
    % svg -> png conversion is fraught.
    % IF SVG is NOT specifed, it will NOT have height information;
    save_sliceAsImage(img_slice,out_height,out,alpha_mask);
end
if reg_match(mode,'figure')
    save_sliceAsFigure(img_slice,position_matrix,out,alpha_mask);
end
if reg_match(mode,'plot')
    save_sliceAsPlot(img_slice,position_matrix,out,alpha_mask);
end

end