function [output] = calculate_cohenD_percentChange_RawDifference(A,B,name_mean,name_std)
%% Data Pulling Preliminaries
Bookkeeping_group_summary_list={'ROI','Structure','hemisphere_assignment','acronym','name','id64','id32','id64_fSABI','id32_fSABI','structure_id'};
Bookkeeping_grouping_idx=regexpi(A.Properties.VariableNames,strcat('^(',strjoin(Bookkeeping_group_summary_list,'|'),')$'));
Bookkeeping_grouping_logical_idx=~cellfun(@isempty,Bookkeeping_grouping_idx);
Bookkeeping_grouping_names=A.Properties.VariableNames(Bookkeeping_grouping_logical_idx);

% %All "Control" pulling components : A  
% %All "Treated" pulling components : B

A=sortrows(A,Bookkeeping_grouping_names);
B=sortrows(B,Bookkeeping_grouping_names);

[~,A_ROI_positional_first_idx,~]=unique(A.ROI,'stable');
[~,B_ROI_positional_first_idx,~]=unique(B.ROI,'stable');

assert( height(A) == numel(A_ROI_positional_first_idx),'Your Control Input has too many ROI Entries');
assert( height(B) == numel(B_ROI_positional_first_idx),'Your Treated Input has too many ROI Entries');

output=A(A_ROI_positional_first_idx,Bookkeeping_grouping_logical_idx);

if (~isempty(A))&&(~isempty(B))
    %% Calculate Pooled STD

    %The Pooled STandard Deviation formula for 2 Groups is:
    % STD_POOLED_SQUARED =(GroupMembers_1-1)*SD_1^2 +(GroupMembers_2-1)*SD_2^2 
    %                     ----------------------------------------------------
    %                    (GroupMembers_1+GroupMembers_2-2)
    % STD_POOLED = sqrt(STD_POOLED_SQUARED);
    

    GroupMembers_A=A.GroupCount;
    GroupMembers_B=B.GroupCount;

    STD_A=A.(name_std);
    STD_B=B.(name_std);

    try
    numerator=(GroupMembers_A-1).*STD_A.^2 +(GroupMembers_B-1).*STD_B.^2;
    catch exception
        keyboard;
    end
    denominator=GroupMembers_A+GroupMembers_B-2;

    pooled_std=sqrt(numerator./denominator);

    %% Calculate The Cohen D
    %treated--B-control--A
    Mean_A=A.(name_mean);
    Mean_B=B.(name_mean);

    output.cohenD=(Mean_B-Mean_A)./pooled_std;

    %% Calculate Percent change and Absolute Error
    output.percent_change=(Mean_B-Mean_A)./Mean_A;
    output.absolute_error=abs(Mean_B-Mean_A);

else
    output.cohenD=NaN(height(output),1);
    output.percent_change=NaN(height(output),1);
    output.absolute_error=NaN(height(output),1);
end

end