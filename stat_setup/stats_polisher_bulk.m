function [ ] = stats_polisher_bulk(df_stat_path,df_connectome_obj,fullAtlasOntology,default_scalarContrast)
%This does both polished and erode at the same time... are we okay with
%that or is that going to cause problems because of changing the types of
%things to whatever name you want for stats? we could have it better look
%at the data and do a input output thing... unsure which is the best
%approach here I suspect multiple parfor is slower than one massive parfor.

parfor n=1:numel(df_connectome_obj)
    scalar_Info=struct2table(default_scalarContrast);
    temp_atlas_data=fullAtlasOntology;
    temp_connectome_data=df_connectome_obj{n};

    runno_region_data=struct2table(temp_connectome_data.regionaldata,'AsArray',true);

    for o=1:height(df_stat_path)
        polished_stats=df_stat_path{o}{n};

        erode_idx=row_find(runno_region_data,'erode', scalar_Info.erode(o));
        level_idx=row_find(runno_region_data,'level',scalar_Info.level(o));
        bilateral_idx=runno_region_data.('bilateral')==scalar_Info.bilateral(o);
        nickname_idx=row_find(runno_region_data,'nickname',scalar_Info.nickname(o));

        total_idx=erode_idx&level_idx&bilateral_idx&nickname_idx;

        if isempty(temp_atlas_data)
            temp_atlas_data=temp_connectome_data.lookup;
        end

        if isempty(temp_connectome_data)||isempty(total_idx)|| ~exist(runno_region_data.stats{total_idx},'file')
            % if no input file, cannot polish. This can happen on if we do not have an archived connectome dir, OR re-run if
            % archive were disconnected. Someplace else we should address
            % re-run. also don't polish stuff that we aren't pulling in
            continue;
        end
        % have to use the new check because if the file does not exist we
        % return false.
        if  ~file_time_check(polished_stats, 'newer', runno_region_data.stats{total_idx})
            stats_polisher(runno_region_data.stats{total_idx},temp_atlas_data,polished_stats);
        end
    end
end

end
