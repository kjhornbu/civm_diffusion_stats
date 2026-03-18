close all;
clear all;

working_folder="Z:\All_Staff\18.gaj.42\FullAnalysis_20260224";

dataframe_path="Z:\All_Staff\18.gaj.42\18.gaj.42_DataFrame_noB6_20260224.txt";
dataframe=civm_read_table(dataframe_path);
data_scaling=1;

% %pull the signficant regions to get the vertices to try for plots here.
% pval_table=civm_read_table(fullfile(working_folder,"Connectomics\omnimanova_100010001\AgeClass_Strain_Sex\BrainScaled_Omni_Manova\Pval_sorted_from_ASE_0000.csv"));
% source_idx=~cellfun(@isempty,regexpi(pval_table.source_of_variation,'Age_Class'));
% pval_idx=pval_table.pval_BH<0.05;
% meaningful_nodes=pval_table.ROI(and(source_idx,pval_idx));

meaningful_nodes=[1:174,176:180,1001:1174,1176:1180];

meaningful_nodes(meaningful_nodes>1000)=meaningful_nodes(meaningful_nodes>1000)-1000;
meaningful_nodes=unique(meaningful_nodes); %only 1 hemisphere

%% Run All Comparision
directory=fullfile(working_folder,'All_EdgeStrengthPlots_EffectPlots');
mkdir(directory);
clear comparison;

comparison(1).grouping.Basis.('Age_Class')='Young';
comparison(1).grouping.UnderTest.('Age_Class')='Old';

[~,~,~] = full_edge_effect_setup(directory,dataframe,data_scaling,comparison,meaningful_nodes);

%% Pick Strains to Use
distance_values=civm_read_table("Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\MDS\MDS_Distances\REGIONAL_MDS_centroid_to_centroid_Distance_All_Strains+All.csv");

idx_onlyStrains=~reg_match(distance_values.hold,'All');
distance_values=distance_values(idx_onlyStrains,:);

pick_1_idx=reg_match(distance_values.compare,'Young');
[vertex_value,~,vertex_idx]=unique(distance_values.vertex);

select_data=table;
for n=1:numel(vertex_value)
    
    full_idx=vertex_idx==n & pick_1_idx;
    strain_values=distance_values.hold(full_idx);

    [a,b]=sort(distance_values.scaled_distance(full_idx),'descend'); 

    if ~isempty(isnan(a))
        position_high=1+sum(isnan(a));
        position_low=numel(a);
    else
        position_high=1;
        position_low=numel(a);
    end

    select_data.vertex(n)=vertex_value(n);

    if vertex_value(n)==175 || vertex_value(n)==175+180
        continue;
    else
        select_data.max_value(n)=a(position_high);
        select_data.max_hold{n}=strain_values{b(position_high)};
        select_data.min_value(n)=a(position_low);
        select_data.min_hold{n}=strain_values{b(position_low)};
    end
end

empty_idx=cellfun(@isempty,select_data.max_hold);
select_data=select_data(~empty_idx,:);

civm_write_table(select_data,'Z:\All_Staff\18.gaj.42\FullAnalysis_20260224\MDS\MDS_Distances\REGIONAL_MDS_Distance_StrainRanking.csv');
output=table;

[a,~,c]=unique(select_data.min_hold);
[~,b]=sort(sum(c==1:numel(a)'));

output.strain=a;
output.count_at_BottomRank=sum(c==1:numel(a)')'; 

STRAIN_set{1}=strain_values{b(end)};
STRAIN_set{2}=strain_values{b(end-1)};
STRAIN_set{3}=strain_values{b(end-2)};

[a,~,c]=unique(select_data.max_hold);
[~,b]=sort(sum(c==1:numel(a)'));
output.count_at_TopRank=sum(c==1:numel(a)')'; 

STRAIN_set{4}=strain_values{b(end-2)};
STRAIN_set{5}=strain_values{b(end-1)};
STRAIN_set{6}=strain_values{b(end)};

%% Run Strain Stratifed Comparision
%prior ordering
%('All BXD24 BXD34 BXD60 BXD101 BXD65b BXD29');

directory=fullfile(working_folder,'All+6Strain_EdgeStrengthPlots_EffectPlots');
mkdir(directory);
clear comparison;

comparison(1).grouping.Basis.('Age_Class')='Young';
comparison(1).grouping.UnderTest.('Age_Class')='Old';

comparison(2).stratification.('Strain')=STRAIN_set{1};
comparison(2).grouping.Basis.('Age_Class')='Young';
comparison(2).grouping.UnderTest.('Age_Class')='Old';

comparison(3).stratification.('Strain')=STRAIN_set{2};
comparison(3).grouping.Basis.('Age_Class')='Young';
comparison(3).grouping.UnderTest.('Age_Class')='Old';

comparison(4).stratification.('Strain')=STRAIN_set{3};
comparison(4).grouping.Basis.('Age_Class')='Young';
comparison(4).grouping.UnderTest.('Age_Class')='Old';

comparison(5).stratification.('Strain')=STRAIN_set{4};
comparison(5).grouping.Basis.('Age_Class')='Young';
comparison(5).grouping.UnderTest.('Age_Class')='Old';

comparison(6).stratification.('Strain')=STRAIN_set{5};
comparison(6).grouping.Basis.('Age_Class')='Young';
comparison(6).grouping.UnderTest.('Age_Class')='Old';

comparison(7).stratification.('Strain')=STRAIN_set{6};
comparison(7).grouping.Basis.('Age_Class')='Young';
comparison(7).grouping.UnderTest.('Age_Class')='Old';

[~,~,~] = full_edge_effect_setup(directory,dataframe,data_scaling,comparison,meaningful_nodes);


%% All + Sex Comparisions

directory=fullfile(working_folder,'All+SexStratified_EdgeStrengthPlots_EffectPlots');
mkdir(directory);

clear comparison;

comparison(1).grouping.Basis.('Age_Class')='Young';
comparison(1).grouping.UnderTest.('Age_Class')='Old';

comparison(2).stratification.('Sex')='M';
comparison(2).grouping.Basis.('Age_Class')='Young';
comparison(2).grouping.UnderTest.('Age_Class')='Old';

comparison(3).stratification.('Sex')='F';
comparison(3).grouping.Basis.('Age_Class')='Young';
comparison(3).grouping.UnderTest.('Age_Class')='Old';

[~,~,~] = full_edge_effect_setup(directory,dataframe,data_scaling,comparison,meaningful_nodes);