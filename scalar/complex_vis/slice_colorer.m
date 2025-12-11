function [img_slice] = slice_colorer(LUT_path,slice_data)
% assigns colors to a slice of label data using a desired LUT. 
% The dimensions of slice are X/Y spatial data, Z color channels... the 4th entry in Z is alpha! 

LUT_data=civm_read_table(LUT_path);
%Remove NAN entries just for ease
remove_nan_entry_idx=~isnan(LUT_data.ROI);
LUT_data=LUT_data(remove_nan_entry_idx,:);

%Find unique ROI in slice
[ROI_entries,~,ROI_entries_idx]=unique(slice_data);
ROI_entries_idx_inDataShape=reshape(ROI_entries_idx,size(slice_data)); %This is equivalent to slice Data

%Full image
img_slice=zeros([size(slice_data),4],'single');

%Each Channel
blank=zeros([size(slice_data)]);
img_slice_r=blank;
img_slice_g=blank;
img_slice_b=blank;
img_slice_a=blank;

for n=1:numel(ROI_entries)
    % Where in our slice do we want to set the color
    label_logical_idx = ROI_entries_idx_inDataShape == n;

    if ROI_entries(n)~=0
        % which color entry in the color table are we using.
        ROI_logical_idx=LUT_data.ROI==ROI_entries(n);

        img_slice_r(label_logical_idx)=LUT_data.c_r(ROI_logical_idx) / 255;
        img_slice_g(label_logical_idx)=LUT_data.c_g(ROI_logical_idx) / 255;
        img_slice_b(label_logical_idx)=LUT_data.c_b(ROI_logical_idx) / 255;
        img_slice_a(label_logical_idx)=LUT_data.c_a(ROI_logical_idx) / 255;
    else
        img_slice_r(label_logical_idx) = 1;
        img_slice_g(label_logical_idx) = 1;
        img_slice_b(label_logical_idx) = 1;
        img_slice_a(label_logical_idx) = 1;
    end
end

%Assigning Channels back to Full Image
img_slice(:,:,1)=img_slice_r;
img_slice(:,:,2)=img_slice_g;
img_slice(:,:,3)=img_slice_b;
img_slice(:,:,4)=img_slice_a;
end