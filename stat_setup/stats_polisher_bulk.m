function [ ] = stats_polisher_bulk(df_stat_path,df_connectome_obj,fullAtlasOntology)
%This does both polished and erode at the same time... are we okay with
%that or is that going to cause problems because of changing the types of
%things to whatever name you want for stats? we could have it better look
%at the data and do a input output thing... unsure which is the best
%approach here I suspect multiple parfor is slower than one massive parfor.

for o=1:height(df_stat_path)
    df_single_stat_path=df_stat_path{o,:};
    parfor n=1:numel(df_connectome_obj)
        temp_atlas_data=fullAtlasOntology;
        temp_connectome_data=df_connectome_obj{n};
        if isempty(temp_atlas_data)
            temp_atlas_data=temp_connectome_data.lookup;
        end

        polished_stats=df_single_stat_path{n};

        if isempty(temp_connectome_data) || ~exist(temp_connectome_data.stats,'file')
            % if no input file, cannot polish. This can happen on if we do not have an archived connectome dir, OR re-run if
            % archive were disconnected. Someplace else we should address re-run.
            continue;
        end
        % have to use the new check because if the file does not exist we
        % return false.
        if ~file_time_check(polished_stats, 'newer', temp_connectome_data.stats)
            stats_polisher(temp_connectome_data.stats{o},temp_atlas_data,polished_stats); %this assumes method 1 will need to update for other methods.
        end
    end
end

end
