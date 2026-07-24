function queue_color_bar_plot(plot_queue,bar_plot_opts,out_lut)

% NOTE: direction == horizontal NOT implemented.
bar_plot_opts=[bar_plot_opts,'direction','vertical'];

t_st=table2struct( civm_read_table(out_lut.tbl));

queueStruct.command=@() lookup_plot(t_st,out_lut,bar_plot_opts{:});
queueStruct.infiles={out_lut.tbl};
queueStruct.outfiles={out_lut.svg,out_lut.png};

plot_queue(out_lut.svg)=queueStruct;

end