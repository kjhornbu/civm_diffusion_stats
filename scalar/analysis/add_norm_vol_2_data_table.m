function [data_table] = add_norm_vol_2_data_table(data_table,unique_column)
if ~exist('unique_column','var')
    unique_column='specimen';
end
vol_regional_cells=regexpi(data_table.Properties.VariableNames,'^volume_mm3|.*volume_mm3_regional_vol$');
vol_regional_idx=~cellfun(@isempty,vol_regional_cells);
vol_regional_column=data_table.Properties.VariableNames{vol_regional_idx};

%Bilateral Whole Brain Root is the total automated volume in our system
%now we are not removing the

hemifind=regexpi(data_table.Properties.VariableNames,'hemisphere_assignment');

if sum(~cellfun(@isempty,hemifind))==0
    [specimen_name,~,specimen_idx]=unique(data_table.(unique_column),'stable');
    data_total_volume_table=table;

    for n=1:numel(specimen_name)
        data_total_volume_table.specimen{n}=specimen_name{n};
        temp=data_table(specimen_idx==n,:);
        temp=temp(temp.ROI~=0,:);
        
        data_total_volume_table.(vol_regional_column)(n)=sum(temp.(vol_regional_column));
    end
else
    try
        %Rob version of RCCF Atlas Polished
        logical_bilat_brain=and((data_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(data_table.GN_Symbol,'BRN-B'))); %Find whole bilateral brain GN Ready Sheet Method
    catch
        %RCCF Atlas Generally Prior to Rob but after we add in the hemisphere
        %asignment capabilities to easily determine L from R and bilateral
        %together.
        logical_bilat_brain=and((data_table.hemisphere_assignment==0),~cellfun(@isempty,regexp(data_table.acronym,'Brain'))); %Find whole bilateral brain alternative method
    end

    data_total_volume_table=data_table(logical_bilat_brain,:);


end

[specimen_total_vol_name,~,specimen_total_vol_idx]=unique(data_total_volume_table.(unique_column),'stable');
[specimen_name,~,specimen_idx]=unique(data_table.(unique_column),'stable');

for n=1:numel(specimen_name)
    %Double check that specimen match and are unique in identification --
    %if this is broken you probably need to find a better column as a
    %unique identifier of the data. (when defining specimen near the top of scalar
    %processing main)
    check_name_match=regexpi(specimen_name{n},specimen_total_vol_name{specimen_total_vol_idx==n});

    if check_name_match~=1
        error('Somehow your specimen are not matching up here, check why the specimen are now not assigning correctly in norm vol generator');
    end

    data_table.volume_fraction(specimen_idx==n)=data_table.(vol_regional_column)(specimen_idx==n)./data_total_volume_table.(vol_regional_column)(specimen_total_vol_idx==n);
end


end

