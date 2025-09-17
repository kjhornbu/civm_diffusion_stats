function [zscore_grouping_name] = clean_general_entries_to_study_conditional(group,subgroup,zscore_grouping)

%if group or group1 the only criteria for the zscore grouping then just put
%as hemisphere else make the grouping condition and the hemisphere
%do a check on if the groupings contain

%the heading information for hte data should be the real entry name rather
%than "group1" "subgroup1" etc This pulls it back together.

for n=1:numel(zscore_grouping)
    name_separate=strsplit(zscore_grouping{n},'group');

    if (regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}))
        zscore_grouping_name{n}=subgroup{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        zscore_grouping_name{n}=group{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        zscore_grouping_name{n}=group{1};
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end
end


end