function [group,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,grouping)
% group: is the full listing specification of the column(s) in the same order it came in as
% group name: is the unique entries in the group
% group name_idx: is the indexing of group name to rebuild group 
%grouping can be multiple entries!!!

%find what column is the grouping
grouping_idx=regexpi(data_table.Properties.VariableNames,strcat('^(',strjoin(grouping,'|'),')$'));
grouping_positional_idx=find(~cellfun(@isempty,grouping_idx)==1);
grouping_name=data_table.Properties.VariableNames(grouping_positional_idx);

for n=1:numel(grouping_name)
    cell_or_num=iscell(data_table.(grouping_name{n}));
    if cell_or_num==0
         data_table.(grouping_name{n})=list2cell(sprintf('%i ',data_table.(grouping_name{n})))';
    end
end

if size(grouping_name,2)>1
    for n=1:size(data_table,1)
        group{n,1}=strjoin(table2array(data_table(n,grouping_positional_idx)));
    end
else
    try
        group=data_table.(grouping_name{:});
    catch merr
        warning(merr.identifier,'failure in grouping selection: %s',merr.message);
        keyboard;
    end
end

[group_name,~,group_name_idx]=unique(group,'stable');

end