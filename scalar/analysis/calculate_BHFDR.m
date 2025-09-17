function [data_table] = calculate_BHFDR(data_table)

%Check the data for the data_table;
temp_contrast=data_table.contrast;
temp_contrast(~cellfun(@isempty,regexpi(temp_contrast,{'normvol'})))={'volume_fraction'};

ideal_contrast_list=list2cell("volume_mm3 volume_fraction fa_mean ad_mean md_mean rd_mean tdi_mean");

for n=1:numel(ideal_contrast_list)
    contrast_idx(:,n)=~cellfun(@isempty,regexpi(temp_contrast,ideal_contrast_list{n}));
end

data_table=data_table(sum(contrast_idx,2)>0,:);

%Adjust slightly differently which way to go
%Getting Data idx bits together
Pval_cells=regexpi(data_table.Properties.VariableNames,'([pP]val)$'); %Grab the Pvalue results from statistical test
Pval_idx=find(~cellfun(@isempty,Pval_cells)==1); %actual idx not in logical array format
Pval_name=data_table.Properties.VariableNames(:,Pval_idx);

% Reminder there are independence issues here : https://projecteuclid.org/journals/annals-of-statistics/volume-29/issue-4/The-control-of-the-false-discovery-rate-in-multiple-testing/10.1214/aos/1013699998.full
% Summary from Wikipedia: The BH procedure is valid when the m tests are independent, and also in various scenarios of dependence, but is not universally valid.[11]
% SO Running this as "generally independent" -- which is that we do a
% hemisphere or whole brain together and don't consider the unique
% contrasts together at the same time (tldr: run BHFDR correction for each contrast across all hemispherical brain data specified).

%You put what you want to consider separately. %Sources of variation,
%contrast, and ROI

% %% ROI Considered
% [~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'source_of_variation','contrast'});
% 
% for n=1:numel(group_name)
%     reshape_group_idx(:,n)=logical(group_name_idx==n);
% end
% 
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
%         temp=mafdr(table2array(data_table(reshape_group_idx(:,m),data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%         %data_table.(strcat(data_name{n},'_BH'))(reshape_group_idx(:,m))=temp;
%         data_table.(strcat(data_name{n},'_BH_considering_ROI'))(reshape_group_idx(:,m))=temp;
%     end
% end

% %% Contrast Considered
% [~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'source_of_variation','Structure'});
% 
% for n=1:numel(group_name)
%     reshape_group_idx(:,n)=logical(group_name_idx==n);
% end
% 
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
%         temp=mafdr(table2array(data_table(reshape_group_idx(:,m),data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%         data_table.(strcat(data_name{n},'_BH_considering_contrast'))(reshape_group_idx(:,m))=temp;
%     end
% end

% %% Source of Variation Considered
% [~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'Structure','contrast'});
% 
% for n=1:numel(group_name)
%     reshape_group_idx(:,n)=logical(group_name_idx==n);
% end
% 
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
%         temp=mafdr(table2array(data_table(reshape_group_idx(:,m),data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%         data_table.(strcat(data_name{n},'_BH_considering_source_of_variation'))(reshape_group_idx(:,m))=temp;
%     end
% end

%% ROI and Contrast Considered
%Changed 2024-06-14 to just using this form of BH correction when doing
%whole brain exploratory analysis. 
[~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'source_of_variation'});

for n=1:numel(group_name)
    reshape_group_idx(:,n)=logical(group_name_idx==n);
end

for n=1:numel(Pval_idx) %for the pvalue column
    for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
        temp=mafdr(table2array(data_table(reshape_group_idx(:,m),Pval_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
        %data_table.(strcat(data_name{n},'_BH_considering_ROIANDcontrast'))(reshape_group_idx(:,m))=temp;
        data_table.(strcat(Pval_name{n},'_BH'))(reshape_group_idx(:,m))=temp;
    end
end

% %% Source of Variation ROI Considered
% [~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'contrast'});
% 
% for n=1:numel(group_name)
%     reshape_group_idx(:,n)=logical(group_name_idx==n);
% end
% 
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
%         temp=mafdr(table2array(data_table(reshape_group_idx(:,m),data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%         data_table.(strcat(data_name{n},'_BH'))(reshape_group_idx(:,m))=temp;
%         data_table.(strcat(data_name{n},'_BH_considering_source_of_variationANDROI'))(reshape_group_idx(:,m))=temp;
%     end
% end

% %% Source of Variation Contrast Considered
% [~,group_name,group_name_idx] = find_group_information_from_groupingcriteria(data_table,{'ROI'});
% 
% for n=1:numel(group_name)
%     reshape_group_idx(:,n)=logical(group_name_idx==n);
% end
% 
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     for m=1:numel(group_name)%setting the data in the correction (this is the non binary indexing to give the segmenting of the data for the column to pull from)
%         temp=mafdr(table2array(data_table(reshape_group_idx(:,m),data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%         data_table.(strcat(data_name{n},'_BH_considering_source_of_variationANDcontrast'))(reshape_group_idx(:,m))=temp;
%     end
% end
% 
% %% Source of Variation ROI Contrast Considered
% for n=1:numel(data_idx) %across each data type we calculated the pvalue
%     temp=mafdr(table2array(data_table(:,data_idx(n))),'BHFDR',true); %the mafdr code BHFDR option is flagged as true so it is using for real the BH form of FDR
%     data_table.(strcat(data_name{n},'_BH_considering_source_of_variationANDROIANDcontrast'))(:)=temp;
% end

end

