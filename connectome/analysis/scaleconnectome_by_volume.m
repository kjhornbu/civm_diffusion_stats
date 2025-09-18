function [ dataframe,col_2_modify,VariableDescriptions] = scaleconnectome_by_volume(dataframe,ventricle)

vcount=unique(dataframe.vcount);

key_cols=~cellfun(@isempty,regexpi(dataframe.Properties.VariableNames,'^(group|group[0-9]+|subgroup|subgroup[0-9]+)$'));
has_description=~cellfun(@isempty,dataframe.Properties.VariableDescriptions);
col_2_modify=and(has_description,key_cols);

VariableDescriptions=dataframe.Properties.VariableDescriptions;
%the conversion in and out of struct is breaking the dataframe so we don't
%have the variable descriptions to reconvert on. take those out of the
%function to add back to the data before saving.

dataframe=table2struct(dataframe);

if sum(and(~has_description,key_cols))>0
    keyboard;
end

brain_vol=zeros(1,height(dataframe));
parfor n=1:numel(dataframe)
    %Get Voxel mm^3 Size
    hdr=load_niigz_hdr(char(dataframe(n).label_path));
    dim_mm_cube=prod(hdr.dime.pixdim(2:4));

    stat_table=civm_read_table(char(dataframe(n).stat_path));

    if size(stat_table,1)>vcount
        %this is the new polished stat sheet RCCF
        %Polished sheets with parentage but after and before rob
        try
            logical_count=and((stat_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(stat_table.GN_Symbol,'BRN-B'))); %Find whole bilateral brain
            logical_remove=and((stat_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(stat_table.GN_Symbol,'Vnt-B'))); %find bilateral ventrical systems
        catch
           logical_count=and((stat_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(stat_table.acronym,'Brain'))); %Find whole bilateral brain
           logical_remove=and((stat_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(stat_table.acronym,'VS'))); %find bilateral ventrical systems
        end

        switch ventricle
            case 0
                voxel_count=stat_table.voxels(logical_count)-stat_table.voxels(logical_remove);
            case 1
                voxel_count=stat_table.voxels(logical_count);
        end

    else
        %This is the old stat table sheets RCCF
        voxel_count=sum(stat_table.voxels(stat_table.ROI>0));
        %before polished sheets have to grab all regions ourselves. 
        switch ventricle
            case 0
                ROI=[176 177 178 179 180 1176 1177 1178 1179 1180]; %all Ventricle/ Trash Brain Rest regions FOR RCCF!!!!!

                Not_Keep_ROI = zeros(size(ROI));
                for m=1:size(ROI,2)
                    Not_Keep_ROI(m)=find(stat_table.ROI==ROI(m));
                end
                voxel_remove=sum(stat_table.voxels(Not_Keep_ROI));
                voxel_count=voxel_count-voxel_remove;
            case 1
                %Keep all regions if the ventricles are kept in (aka 1)
        end
    end

    %Scale Connectome (less volume less connections)
    brain_vol(n)=voxel_count*dim_mm_cube;
    dataframe(n).scale=double((5000000/435)/(dataframe(n).tract_count/brain_vol(n)));
end

dataframe=struct2table(dataframe);

switch ventricle
%Assign the total brain volume to the dataset
    case 0
        dataframe.total_brain_vol_withoutVS=brain_vol';
    case 1
        dataframe.total_brain_vol=brain_vol';
end

%add 'Scale' and 'Total_brain_Vol' Columns to the two bookkeeping columns
col_2_modify(numel(col_2_modify)+[1:2])=false;
original_len=numel(VariableDescriptions);
VariableDescriptions{original_len+1}='';
VariableDescriptions{original_len+2}='';
end