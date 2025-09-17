function [regional_paths,global_paths] = run_manova_in_R(save_dir,group, subgroup,test_criteria, stats_test,regional_paths,global_paths,stratification_name)

single_experiment=1;
%% Perform Actual Manova in R

%% DO Regional
filename=dir(regional_paths.ase);

[~,n,~]=fileparts(regional_paths.ase);
temp=strsplit(n,'__');

set_name_Zscore=~isempty(regexpi(filename.name,'Zscore'));
set_name_stratification=~isempty(stratification_name);

if set_name_Zscore && set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s__4_%s.csv',temp{1},stratification_name);
elseif set_name_Zscore && ~set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s.csv',temp{1});
elseif ~set_name_Zscore && set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s__4_%s.csv',temp{1},stratification_name);
else
   out_name=sprintf('Pval_sorted_from_%s.csv',temp{1});
end

out_file=fullfile(save_dir,out_name);
regional_paths.pval=out_file;
switch stats_test.name
    case 'omnimanova_full_interactions'
        [csv_out,defined_formula]=manova_R_call(out_file,regional_paths.ase,test_criteria);
    case 'omnimanova_defined_matrix'
        definition_matrix=stats_test.matrix{single_experiment};
        [csv_out,defined_formula]=manova_defined_matrix_R_call(out_file,regional_paths.ase,test_criteria,definition_matrix,stats_test);
end
Plot_N_Save_Pval_from_Rcode(save_dir,csv_out,group,subgroup,defined_formula,stratification_name);

%% DO global
filename=dir(global_paths.ase);

[~,n,~]=fileparts(global_paths.ase);
temp=strsplit(n,'__');

set_name_Zscore=~isempty(regexpi(filename.name,'Zscore'));
set_name_stratification=~isempty(stratification_name);

if set_name_Zscore && set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s__4_%s.csv',temp{1},stratification_name);
elseif set_name_Zscore && ~set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s.csv',temp{1});
elseif ~set_name_Zscore && set_name_stratification
    out_name=sprintf('Pval_sorted_from_%s__4_%s.csv',temp{1},stratification_name);
else
   out_name=sprintf('Pval_sorted_from_%s.csv',temp{1});
end
out_file=fullfile(save_dir,out_name);
global_paths.pval=out_file;
switch stats_test.name
    case 'omnimanova_full_interactions'
        [global_csv_out,defined_formula]=manova_R_call(out_file,global_paths.ase,test_criteria);
    case 'omnimanova_defined_matrix'
        definition_matrix=stats_test.matrix{single_experiment};
        [global_csv_out,defined_formula]=manova_defined_matrix_R_call(out_file,global_paths.ase,test_criteria,definition_matrix,stats_test);
end
Plot_N_Save_Pval_from_Rcode(save_dir,global_csv_out,group,subgroup,defined_formula,stratification_name);
end