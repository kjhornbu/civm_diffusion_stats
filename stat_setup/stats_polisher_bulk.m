function [ ] = stats_polisher_bulk(df_stat_path,df_stat_path_erode,df_connectome_obj,fullAtlasOntology)
%This does both polished and erode at the same time... are we okay with
%that or is that going to cause problems because of changing the types of
%things to whatever name you want for stats? we could have it better look
%at the data and do a input output thing... unsure which is the best
%approach here I suspect multiple parfor is slower than one massive parfor.

parfor n=1:numel(df_connectome_obj)
    temp_atlas_data=fullAtlasOntology;
    temp_connectome_data=df_connectome_obj{n};
    if isempty(temp_atlas_data)
        temp_atlas_data=temp_connectome_data.lookup;
    end

    polished_stats=df_stat_path{n};
    polished_e1stats=df_stat_path_erode{n};

    if isempty(temp_connectome_data) || ~exist(temp_connectome_data.stats,'file')
        % if no input file, cannot polish. This can happen on if we do not have an archived connectome dir, OR re-run if
        % archive were disconnected. Someplace else we should address re-run.
        continue;
    end

    % have to use the new check because if the file does not exist we
    % return false.
    if ~file_time_check(polished_stats, 'newer', temp_connectome_data.stats)
        stats_polisher(temp_connectome_data.stats,temp_atlas_data,polished_stats); %,project_research_archive
    end
    if ~isempty(temp_connectome_data.e1_stats)
        if ~file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats)
            stats_polisher(temp_connectome_data.e1_stats,temp_atlas_data,polished_e1stats);
        end
    end
end
end
