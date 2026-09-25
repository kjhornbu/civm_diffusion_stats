function processFigures(LUT_jobs,slicer_lookup_jobs,colorbar_jobs,log_inkey,log_outkey)


%% transfer all the colorbars, luts,  and slicer lookups
process_singleton_transfers(LUT_jobs,log_inkey,log_outkey);
process_singleton_transfers(slicer_lookup_jobs,log_inkey,log_outkey);
recreate_colorbars(colorbar_jobs,log_inkey,log_outkey);


end