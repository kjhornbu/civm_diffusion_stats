function [df_label_data] = label_selecting_bulk(df_connectome_obj,default_scalarContrast)
df_label_data=cell(height(df_connectome_obj), 1);

parfor n=1:numel(df_connectome_obj)
    scalar_Info=struct2table(default_scalarContrast);
    temp_connectome_data=df_connectome_obj{n};

    if ~isempty(temp_connectome_data)
        runno_region_data=struct2table(temp_connectome_data.regionaldata,'AsArray',true);

        for o=1:height(scalar_Info)

            erode_idx=row_find(runno_region_data,'erode', scalar_Info.erode(o));
            level_idx=row_find(runno_region_data,'level',scalar_Info.level(o));
            bilateral_idx=runno_region_data.('bilateral')==scalar_Info.bilateral(o);
            nickname_idx=row_find(runno_region_data,'nickname',scalar_Info.nickname(o));

            total_idx=erode_idx&level_idx&bilateral_idx&nickname_idx;

            if exist(runno_region_data.labels{total_idx},'file')
                df_label_data{n,1}=runno_region_data.labels{total_idx};
            end
        end
    end
end
end