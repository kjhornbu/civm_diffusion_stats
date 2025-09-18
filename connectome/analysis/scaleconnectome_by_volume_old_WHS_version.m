function [ df ] = scaleconnectome_by_volume_old_WHS_version(df,ventricle)


    for n=1:size(df,1)
        %Get Voxel mm^3 Size
        hdr=load_niigz_hdr(char(df.label_path(n)));
        dim_mm_cube=prod(hdr.dime.pixdim(2:4));

        stat_table=readtable(char(df.stat_path(n)),'Delimiter','tab');
        
        if size(stat_table,2)==1
            stat_table=readtable(char(df.stat_path(n)),'Delimiter',',');
        end
        

        switch ventricle

            case 0

                voxel_count=sum(stat_table.voxels(2:end));

                ROI=[148,152,161,1148,1152,1161]; %all Ventricle regions

%Problem with this being fixed and it not actually removing what we
%want???Used Historically prior to 210628 --- Does not work with RCCF Works
%from WHS3-5
                for m=1:size(ROI,2)
                    Not_Keep_ROI(m)=find(stat_table.ROI==ROI(m));
                end

                voxel_remove=sum(stat_table.voxels(Not_Keep_ROI));

                voxel_count=voxel_count-voxel_remove;

            case 1
                if numel(stat_table.voxels)>332 
                %This is fixed again which is not useful for our calculation, but as  we fixed the case at 0 in Omni script this was never hit.
                    voxel_count=sum(stat_table.voxels(2:end));  
                else
                    voxel_count=sum(stat_table.voxels);  
                end
                    
        end

        %Scale Connectome (less volume less connections)
        brain_vol= voxel_count*dim_mm_cube;

        df.scale(n)=double((5000000/435)/(df.tract_count(n)/brain_vol));
    end
end