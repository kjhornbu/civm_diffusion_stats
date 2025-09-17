function [corrected_source_of_variation] = clean_general_entries_in_source_of_variation(group,subgroup,general_entry_source_of_variation)

%if group or group1 the only criteria for the zscore grouping then just put
%as hemisphere else make the grouping condition and the hemisphere
%do a check on if the groupings contain

%the heading information for hte data should be the real entry name rather
%than "group1" "subgroup1" etc This pulls it back together.

for n=1:numel(general_entry_source_of_variation)
    name_separate=strsplit(general_entry_source_of_variation{n},'group');

    if (regexp(name_separate{1},'sub')==1)&(~isempty(name_separate{end}))
        corrected_source_of_variation{n}=subgroup{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(~isempty(name_separate{end}))
        corrected_source_of_variation{n}=group{str2double(name_separate{end})};
    elseif (isempty(name_separate{1}))&(isempty(name_separate{end}))
        %for group 1 we have the ability to not add the 1 after wards so
        %just pull it directly
        corrected_source_of_variation{n}=group{1};
    elseif reg_match(name_separate{1},'Residuals')
        warning('Manova residuals:\n%s\n%s\n%s\n%s', ...
            'WE DO NOT EXPECT R to return Residuals in our sources of variation.', ...
             'This indicates you have an insufficently sampled input selection.', ...
             '(EVERY group/subgroup must be sampeled sufficiently that a linear fit would be meaningful.)', ...
             'CODE WILL NOW PAUSE SO YOU GET THIS MESSAGE. (R ran, but you gave it data we will not manage to interpret. Please enjoy a useless 5 minute wait.)');
        pause(300);
        fprintf('welcome to infinite debug pause\n');
        keyboard;
        error("just kidding, i'm not letting you ignore this");
    else
        keyboard;
        %groups are being weird you need to double check people are using the
        %correct subgroup[0-9] and group|group[0-9] terms
    end
end


end
