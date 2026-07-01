function [slice_paths] = prepare_slice_levels(C_contrast_dir,slice_levels,DVlevels,data_identity)

warning('FUNCTION NOT YET COMPLETED');
keyboard;

figure_type='slice';
slice_dir=fullfile(C_contrast_dir{:});
C_slice_name=[data_identity, figure_type, 'SLICELEVEL'];
slice_name_pos=find(reg_match(C_slice_name,'SLICELEVEL'));

slice_paths=cell(size(slice_levels));

for i_slice=1:numel(slice_levels)
    C_t_sn=C_slice_name;
    C_t_sn{slice_name_pos}=DVlevels{i_slice};

    slice_paths{i_slice}.fig_name=strjoin(C_t_sn,'_');
    slice_paths{i_slice}.base_path=path_convert_platform(fullfile(slice_dir,'svg',slice_paths{i_slice}.fig_name),'native');
    slice_paths{i_slice}.svg=sprintf('%s.svg',slice_paths{i_slice}.base_path);
end

end

% 
%             
%             for i_slice=1:numel(slice_levels)
%                 C_t_sn=C_slice_name;
%                 C_t_sn{slice_name_pos}=DVlevels{i_slice};
%                 slice_out=path_convert_platform(fullfile(slice_dir,'svg',strjoin(C_t_sn,'_')),'native');
%                 slice_paths{i_slice}=sprintf('%s.svg',slice_out);
%                 if exist(slice_out,'file')
%                     continue;
%                 end
% 
%                 %{
%                 slice_data=slice_level_data(:,:,i_slice);
%                 [img_slice] = slice_colorer(slice_lut_out,slice_data);
%                 save_color_slice(img_slice,slice_out);
%                 %}
% 
%                 gen_img = @() uint8( slice_colorer(slice_lut_out,slice_level_data(:,:,i_slice)) *255 );
%                 gen_and_write_img=@(g_img) slice_saver(g_img(),slice_out,'image');
% 
% 
% 
%                 task_map(slice_out)=@() gen_and_write_img(gen_img);
%             end