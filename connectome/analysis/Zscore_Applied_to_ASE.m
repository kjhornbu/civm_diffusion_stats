function [regional_paths, global_paths] = Zscore_Applied_to_ASE( ...
    save_dir,dataframe, test_criteria, test_remove_criteria, ...
    do_binarize, do_mean_subtract, do_ptr, do_augment,...
    regional_paths, global_paths,...
    ase_regional, ase_global)

%% Remove Any effects from ASE
% Find the mean and standard deviation values and compare to the
% values... both regional and global.

[ase_regional] = zscoring_finder_connectome(ase_regional, test_criteria, test_remove_criteria{:});
[ase_global] = zscoring_finder_connectome(ase_global, test_criteria, test_remove_criteria{:});

%% Save ASE
%save regional ase
out_name=sprintf('ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
regional_paths.ase=out_file;
writetable(ase_regional, out_file); %No need to reformat because already done -- save directly

%save global ase
out_name=sprintf('Global_ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.ase=out_file;
writetable(ase_global, out_file); %No need to reformat because already done -- save directly

% Setup Tensor ASE with Zscoring for the Dist calcuations
logical_X_idx=~cellfun(@isempty,regexpi(ase_regional.Properties.VariableNames,'^X'));
positional_X_idx=find(logical_X_idx==1);

tensor_ase_zscored=table2array(ase_regional(:,positional_X_idx));

tensor_ase_zscored=reshape(tensor_ase_zscored,height(ase_global),height(ase_regional)/height(ase_global),[]);
tensor_ase_zscored=permute(tensor_ase_zscored,[3,2,1]);

nan_mask=isnan(tensor_ase_zscored);
tensor_ase_zscored(nan_mask)=0;

%Make Regional Dist on Standarized Data
for roi=1:(height(ase_regional)/height(ase_global))
    for length_n=1:height(ase_global)
        for length_m=1:height(ase_global)
            Dist_Regional_Zscored(length_n,length_m,roi)=norm(tensor_ase_zscored(:,roi,length_n)-tensor_ase_zscored(:,roi,length_m),'fro');
        end
    end

    try
        [~,temp_eign_Full]=cmdscale(Dist_Regional_Zscored(:,:,roi));
        [temp,temp_eign]=cmdscale(Dist_Regional_Zscored(:,:,roi),2); %updated to remove the focusing on only the first! roi
        if size(temp,2)>1
            mds_Regional_Zscored(:,:,roi) = temp;
            eigen_Zscored_Regional(:,roi)= temp_eign./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
        else
            mds_Regional_Zscored(:,:,roi) = [temp zeros(size(temp))];
            eigen_Zscored_Regional(:,roi) =  [temp_eign 0]./sum(temp_eign_Full(temp_eign_Full>0)); %Calcuates the percent of variablity explained by eigen values
        end
    catch
        mds_Regional_Zscored(:,:,roi) = zeros(size(Dist_Regional_Zscored,1),2);
        eigen_Zscored_Regional(:,roi) =  [0 0];
    end
end


%% Save Percent Explained
% save regional percent explained
out_name=sprintf('Regional_PercentExplained_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_regional=eigen_Zscored_Regional';
format_embedded_data_file(dataframe,test_criteria,percexplain_regional,out_file,'regionalnorepeat');
regional_paths.perc_explained=out_file;

regional_paths.perc_explained_bilat=[]; %No bilat file because didn't want to think hard.

%             %save regional dist after zscoring
%             out_name=sprintf('Regional_Semipar_Image_Zscore_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
%             out_file=fullfile(save_dir,out_name);
%             format_distance_file_figure(dataframe,Dist_Regional_Zscored,eigen_Zscored_Regional,test_criteria,out_file,'plot');

%james dist files bullshet here

%save regional MDS After Zscoring
out_name=sprintf('Regional_MDS_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
regional_paths.mdsZscore=out_file;
mds_Regional_Zscore_longform=reshape( permute( mds_Regional_Zscored,[3 1 2]),[size( mds_Regional_Zscored,1)*size( mds_Regional_Zscored,3),size( mds_Regional_Zscored,2)]);
[mds_Regional_Zscore] = format_embedded_data_file(dataframe,test_criteria,mds_Regional_Zscore_longform,out_file,'regional');
%Make these save with real names? more like repair at end for ASE because the issue with ASE needing gorup/subgroup

%Make Global Dist on Standarized Data
for length_n=1:height(ase_global)
    for length_m=1:height(ase_global)
        Dist_Global_Zscored(length_n,length_m)=norm(tensor_ase_zscored(:,:,length_n)-tensor_ase_zscored(:,:,length_m),'fro');
    end
end

%Make New Global MDS on Standardized Data
[~,eigen_Global_Zscored_Full] = cmdscale(Dist_Global_Zscored);
[mds_Global_Zscored,eigen_Zscored_Global] = cmdscale(Dist_Global_Zscored,2);%Force 2D embedding This matches JHU

eigen_Zscored_Global=eigen_Zscored_Global./sum(eigen_Global_Zscored_Full(eigen_Global_Zscored_Full>0));

%save global percent explained
out_name=sprintf('Global_PercentExplained_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_global_longform=eigen_Zscored_Global';
format_embedded_data_file(dataframe,test_criteria,percexplain_global_longform,out_file,'globalnorepeat');
global_paths.perc_explained=out_file;

%             %save global dist after zscoring
%             out_name=sprintf('Global_Semipar_Image_Zscore_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
%             out_file=fullfile(save_dir,out_name);
%             format_distance_file_figure(dataframe,Dist_Global_Zscored,eigen_Zscored_Global,test_criteria,out_file,'plot');

%james dist files bullshet here???

%save global MDS After Zscoring
out_name=sprintf('Global_MDS_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.mdsZscore=out_file;
mds_global_Zscore_longform=reshape( permute( mds_Global_Zscored,[3 1 2]),[size( mds_Global_Zscored,1)*size( mds_Global_Zscored,3),size( mds_Global_Zscored,2)]);
[mds_global_Zscore] = format_embedded_data_file(dataframe,test_criteria,mds_global_Zscore_longform,out_file,'global');
%Make these save with real names? more like repair at end for ASE because the issue with ASE needing gorup/subgroup

%save global MDS Plot After Zscoring
out_name=sprintf('2D_Embedding_Plot_Global_MDS_Zscore_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
plot_mds(mds_global_Zscore,test_criteria,out_file);

end