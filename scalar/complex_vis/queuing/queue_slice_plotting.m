function queue_slice_plotting(plot_queue,slice_paths,slice_levels,slice_level_data,slice_lut_out)
for i_slice=1:numel(slice_levels)
    slice_path=slice_paths{i_slice};

    gen_img = @() uint8( slice_colorer(slice_lut_out,slice_level_data(:,:,i_slice)) *255 );
    gen_and_write_img=@(g_img) slice_saver(g_img(),slice_path.svg,'image');


    queueStruct.command=@() gen_and_write_img(gen_img);
    queueStruct.infiles={slice_lut_out};
    queueStruct.outfiles={slice_path.svg};

    plot_queue(slice_path.svg)=queueStruct;
end
end