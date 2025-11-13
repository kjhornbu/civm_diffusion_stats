
close all;
clear all;

output_strains=table;

%% MDS

Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\Global_MDS_0000.csv");
[output_global_overall] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('group2'));

Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\Regional_MDS_0000.csv");
[output_regional] = centroid_2_centroid(Data_regional,list2cell('group1'),list2cell('group2'));

[values,~,idx]=unique(output_regional.vertex);

for n=1:numel(values)
clear temp
    temp=output_regional(idx==n,:);
    temp=sortrows(temp,"scaled_distance",'descend');
    if ~strcmp(temp.hold(1),'All')
        Top_scaled_Distance{n}=temp.hold{1};
    else
        Top_scaled_Distance{n}=temp.hold{3};
    end

    if ~strcmp(temp.hold(end),'All')
        Bottom_scaled_Distance{n}=temp.hold{end};
    else
        Bottom_scaled_Distance{n}=temp.hold{end-2};
    end

    All_Strains_Scaled_Distance_MDS{n}=temp.hold;

    temp=sortrows(temp,"scaled_cohenDLike_distance",'descend');

    if ~strcmp(temp.hold(1),'All')
        Top_scaled_cohenDLike_Distance{n}=temp.hold{1};
    else
        Top_scaled_cohenDLike_Distance{n}=temp.hold{3};
    end

    if ~strcmp(temp.hold(end),'All')
        Bottom_scaled_cohenDLike_Distance{n}=temp.hold{end};
    else
        Bottom_scaled_cohenDLike_Distance{n}=temp.hold{end-2};
    end

    All_Strains_Scaled_cohenDLike_Distance_MDSE{n}=temp.hold;
end

[value,~,idx]=unique(Top_scaled_Distance);
instance_of_value_top=sum(idx==1:numel(value));
sorted_instance_of_value_top=sort(instance_of_value_top,'descend');
Top_By_Rank_MDS_ScaledDist=value(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

n=1;
output_strains.type{n}='Top';
output_strains.metric{n}='ScaledDist_MDS';
output_strains.X1(n)=Top_By_Rank_MDS_ScaledDist(1);
output_strains.X2(n)=Top_By_Rank_MDS_ScaledDist(2);
output_strains.X3(n)=Top_By_Rank_MDS_ScaledDist(3);
output_strains.count{n}=instance_of_value_top(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);


[value,~,idx]=unique(Bottom_scaled_Distance);
instance_of_value_bottom=sum(idx==1:numel(value));
sorted_instance_of_value_bottom=sort(instance_of_value_bottom,'descend');
Bottom_By_Rank_MDS_ScaledDist=value(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

n=2;
output_strains.type{n}='Bottom';
output_strains.metric{n}='ScaledDist_MDS';
output_strains.X1(n)=Bottom_By_Rank_MDS_ScaledDist(1);
output_strains.X2(n)=Bottom_By_Rank_MDS_ScaledDist(2);
output_strains.X3(n)=Bottom_By_Rank_MDS_ScaledDist(3);
output_strains.count{n}=instance_of_value_bottom(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

[value,~,idx]=unique(Top_scaled_cohenDLike_Distance);
instance_of_value_top=sum(idx==1:numel(value));
sorted_instance_of_value_top=sort(instance_of_value_top,'descend');
Top_By_Rank_MDS_ScaledcohenDLikeDist=value(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

n=3;
output_strains.type{n}='Top';
output_strains.metric{n}='ScaledCohenDLikeDist_MDS';
output_strains.X1(n)=Top_By_Rank_MDS_ScaledcohenDLikeDist(1);
output_strains.X2(n)=Top_By_Rank_MDS_ScaledcohenDLikeDist(2);
output_strains.X3(n)=Top_By_Rank_MDS_ScaledcohenDLikeDist(3);
output_strains.count{n}=instance_of_value_top(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

[value,~,idx]=unique(Bottom_scaled_cohenDLike_Distance);
instance_of_value_bottom=sum(idx==1:numel(value));
sorted_instance_of_value_bottom=sort(instance_of_value_bottom,'descend');
Bottom_By_Rank_MDS_ScaledcohenDLikeDist=value(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

n=4;
output_strains.type{n}='Bottom';
output_strains.metric{n}='ScaledCohenDLikeDist_MDS';
output_strains.X1(n)=Bottom_By_Rank_MDS_ScaledcohenDLikeDist(1);
output_strains.X2(n)=Bottom_By_Rank_MDS_ScaledcohenDLikeDist(2);
output_strains.X3(n)=Bottom_By_Rank_MDS_ScaledcohenDLikeDist(3);
output_strains.count{n}=instance_of_value_bottom(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

civm_write_table(output_regional,'Z:\All_Staff\18.gaj.42\REGIONAL_MDS_centroid_to_centroid_Distance_All_Strains+All.csv');
civm_write_table(output_global_overall,'Z:\All_Staff\18.gaj.42\GLOBAL_MDS_centroid_to_centroid_Distance_All_Strains+All.csv');

%% ASE

Data_global_overall=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\Global_ASE_0000.csv");
[output_global_overall] = centroid_2_centroid(Data_global_overall,list2cell('group1'),list2cell('group2'));

Data_regional=civm_read_table("Z:\All_Staff\18.gaj.42\OmniManova\Main_Effects_2025_02_03_NoB6\BrainScaled_Omni_Manova\Age_Class_Strain_Sex\ASE_0000_o.csv");
[output_regional] = centroid_2_centroid(Data_regional,list2cell('group1'),list2cell('group2'));

[values,~,idx]=unique(output_regional.vertex);

for n=1:numel(values)
clear temp
    temp=output_regional(idx==n,:);
    temp=sortrows(temp,"scaled_distance",'descend');
    if ~strcmp(temp.hold(1),'All')
        Top_scaled_Distance{n}=temp.hold{1};
    else
        Top_scaled_Distance{n}=temp.hold{3};
    end

    if ~strcmp(temp.hold(end),'All')
        Bottom_scaled_Distance{n}=temp.hold{end};
    else
        Bottom_scaled_Distance{n}=temp.hold{end-2};
    end

    All_Strains_Scaled_Distance_ASE{n}=temp.hold;

    temp=sortrows(temp,"scaled_cohenDLike_distance",'descend');

    if ~strcmp(temp.hold(1),'All')
        Top_scaled_cohenDLike_Distance{n}=temp.hold{1};
    else
        Top_scaled_cohenDLike_Distance{n}=temp.hold{3};
    end

    if ~strcmp(temp.hold(end),'All')
        Bottom_scaled_cohenDLike_Distance{n}=temp.hold{end};
    else
        Bottom_scaled_cohenDLike_Distance{n}=temp.hold{end-2};
    end

    All_Strains_Scaled_cohenDLike_Distance_ASE{n}=temp.hold;
end

[value,~,idx]=unique(Top_scaled_Distance);
instance_of_value_top=sum(idx==1:numel(value));
sorted_instance_of_value_top=sort(instance_of_value_top,'descend');
Top_By_Rank_ASE_ScaledDist=value(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

n=1+4;
output_strains.type{n}='Top';
output_strains.metric{n}='ScaledDist_ASE';
output_strains.X1(n)=Top_By_Rank_ASE_ScaledDist(1);
output_strains.X2(n)=Top_By_Rank_ASE_ScaledDist(2);
output_strains.X3(n)=Top_By_Rank_ASE_ScaledDist(3);
output_strains.count{n}=instance_of_value_top(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

[value,~,idx]=unique(Bottom_scaled_Distance);
instance_of_value_bottom=sum(idx==1:numel(value));
sorted_instance_of_value_bottom=sort(instance_of_value_bottom,'descend');
Bottom_By_Rank_ASE_ScaledDist=value(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

n=2+4;
output_strains.type{n}='Bottom';
output_strains.metric{n}='ScaledDist_ASE';
output_strains.X1(n)=Bottom_By_Rank_ASE_ScaledDist(1);
output_strains.X2(n)=Bottom_By_Rank_ASE_ScaledDist(2);
output_strains.X3(n)=Bottom_By_Rank_ASE_ScaledDist(3);
output_strains.count{n}=instance_of_value_bottom(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

[value,~,idx]=unique(Top_scaled_cohenDLike_Distance);
instance_of_value_top=sum(idx==1:numel(value));
sorted_instance_of_value_top=sort(instance_of_value_top,'descend');
Top_By_Rank_ASE_ScaledcohenDLikeDist=value(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

n=3+4;
output_strains.type{n}='Top';
output_strains.metric{n}='ScaledCohenDLikeDist_ASE';
output_strains.X1(n)=Top_By_Rank_ASE_ScaledcohenDLikeDist(1);
output_strains.X2(n)=Top_By_Rank_ASE_ScaledcohenDLikeDist(2);
output_strains.X3(n)=Top_By_Rank_ASE_ScaledcohenDLikeDist(3);
output_strains.count{n}=instance_of_value_top(sum(instance_of_value_top==sorted_instance_of_value_top(1:3)')>0);

[value,~,idx]=unique(Bottom_scaled_cohenDLike_Distance);
instance_of_value_bottom=sum(idx==1:numel(value));
sorted_instance_of_value_bottom=sort(instance_of_value_bottom,'descend');
Bottom_By_Rank_ASE_ScaledcohenDLikeDist=value(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

n=4+4;
output_strains.type{n}='Bottom';
output_strains.metric{n}='ScaledCohenDLikeDist_ASE';
output_strains.X1(n)=Bottom_By_Rank_ASE_ScaledcohenDLikeDist(1);
output_strains.X2(n)=Bottom_By_Rank_ASE_ScaledcohenDLikeDist(2);
output_strains.X3(n)=Bottom_By_Rank_ASE_ScaledcohenDLikeDist(3);
output_strains.count{n}=instance_of_value_bottom(sum(instance_of_value_bottom==sorted_instance_of_value_bottom(1:3)')>0);

civm_write_table(output_regional,'Z:\All_Staff\18.gaj.42\REGIONAL_ASE_centroid_to_centroid_Distance_All_Strains+All.csv');
civm_write_table(output_global_overall,'Z:\All_Staff\18.gaj.42\GLOBAL_ASE_centroid_to_centroid_Distance_All_Strains+All.csv');


civm_write_table(output_strains,'Z:\All_Staff\18.gaj.42\Top_Bottom_RankStrains.csv');

