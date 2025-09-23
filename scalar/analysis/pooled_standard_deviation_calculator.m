function [pooled_standard_deviation] = pooled_standard_deviation_calculator(group_std,separting_groups)

pooled_standard_deviation=table;

[~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(group_std,separting_groups);

pullgrouping_logical_idx=group_name_idx==1:size(group_name,1);

%Actual data cells finder looking for all the things I want
data_cells=regexpi(group_std.Properties.VariableNames,'(_std)$');
data_idx=find(~cellfun(@isempty,data_cells)==1); %actual idx not in logical array format
data_name=group_std.Properties.VariableNames(data_idx);

%the header information finder (aka not data) listing all the things I
%don't want and looking at the things that don't fit that criteria
data_cells_NOT=regexpi(group_std.Properties.VariableNames,'(_mean)$');
data_idx_NOT=find(~cellfun(@isempty,data_cells_NOT)==1);
if numel(data_idx_NOT)>0
    data_cells = regexpi(group_std.Properties.VariableNames,'^(hold)$');
    not_data_idx=find(~cellfun(@isempty,data_cells)==1);
else
    not_data_idx=find(cellfun(@isempty,data_cells)==1);
end

%Pull key header information for lookup but not the multiple time
%information that was in the table before for each grouping style -- this
%causes us to have issues with double rows etc. 
pooled_standard_deviation=unique(group_std(:,not_data_idx),'rows','stable');

for d_idx=1:numel(data_idx)
    for n=1:size(pullgrouping_logical_idx,2)
        s(:,n)=table2array(group_std(pullgrouping_logical_idx(:,n),data_idx(d_idx)));
        N(:,n)=group_std.GroupCount(pullgrouping_logical_idx(:,n));

        varp_num(:,n)=(N(:,n)-1).*s(:,n).^2;
        varp_denom(:,n)=(N(:,n)-1);
    end
    %The sqrt of standard deviation is the variation the equation I'm use is in the form of variation with groups of unequal N... https://en.wikipedia.org/wiki/Pooled_variance
    pooled_standard_deviation.(data_name{d_idx})=sqrt(sum(varp_num,2)./sum(varp_denom,2)); %This is the wrong direction for combining the groups that I want

end

end