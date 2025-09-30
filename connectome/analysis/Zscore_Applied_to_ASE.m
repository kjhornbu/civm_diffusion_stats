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

%% Setup Tensor ASE with Zscoring for the Dist calcuations
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

%Make Bilat Regional Dist on Standarized Data
for roi=1:(height(ase_regional)/height(ase_global))/2
    for length_n=1:height(ase_global)
        for length_m=1:height(ase_global)
            Dist_regional_bilat_Zscored(length_n,length_m,roi)=norm(tensor_ase_zscored(:,[roi roi+(height(ase_regional)/height(ase_global))/2 ],length_n)-tensor_ase_zscored(:,[roi roi+(height(ase_regional)/height(ase_global))/2],length_m),'fro');
        end
    end

    try
        [~,temp_eign_bilat_Full]=cmdscale(Dist_regional_bilat_Zscored(:,:,roi));
        [temp_bilat,temp_bilat_eign]=cmdscale(Dist_regional_bilat_Zscored(:,:,roi),2); %updated to remove the focusing on only the first! roi
        if size(temp_bilat,2)>1
            mds_Regional_bilat_Zscored(:,:,roi) = temp_bilat;
            eigen_Zscored_bilat_Regional(:,roi)= temp_bilat_eign./sum(temp_eign_bilat_Full(temp_eign_bilat_Full>0)); %Calcuates the percent of variablity explained by eigen values
        else
            mds_Regional_bilat_Zscored(:,:,roi) = [temp_bilat zeros(size(temp_bilat))];
            eigen_Zscored_bilat_Regional(:,roi) =  [temp_bilat_eign 0]./sum(temp_eign_bilat_Full(temp_eign_bilat_Full>0)); %Calcuates the percent of variablity explained by eigen values
        end
    catch
        mds_Regional_bilat_Zscored(:,:,roi) = zeros(size(Dist_regional_bilat_Zscored,1),2);
        eigen_Zscored_bilat_Regional(:,roi) =  [0 0];
    end

end
%% LOOK THIS UP FOR FURTHER UNDERSTANDING
%Make Global Dist on Standarized Data -- We use the Regional??? but why use
%that?
for length_n=1:height(ase_global)
    for length_m=1:height(ase_global)
        Dist_Global_Zscored(length_n,length_m)=norm(tensor_ase_zscored(:,:,length_n)-tensor_ase_zscored(:,:,length_m),'fro');
    end
end


%Make New Global MDS on Standardized Data
[~,eigen_Global_Zscored_Full] = cmdscale(Dist_Global_Zscored);
[mds_Global_Zscored,eigen_Zscored_Global] = cmdscale(Dist_Global_Zscored,2);%Force 2D embedding This matches JHU

eigen_Zscored_Global=eigen_Zscored_Global./sum(eigen_Global_Zscored_Full(eigen_Global_Zscored_Full>0));


logical_X_idx=~cellfun(@isempty,regexpi(ase_global.Properties.VariableNames,'^X'));
positional_X_idx=find(logical_X_idx==1);

tensor_ase_zscored=table2array(ase_global(:,positional_X_idx));

tensor_ase_zscored=reshape(tensor_ase_zscored,height(ase_global),1,[]);
tensor_ase_zscored=permute(tensor_ase_zscored,[3,2,1]);

nan_mask=isnan(tensor_ase_zscored);
tensor_ase_zscored(nan_mask)=0;

%Make Global Dist From the ASE_Global Response
for length_n=1:height(ase_global)
    for length_m=1:height(ase_global)
        Dist_Global_Zscored_FromGlobalASE(length_n,length_m)=norm(tensor_ase_zscored(:,:,length_n)-tensor_ase_zscored(:,:,length_m),'fro');
    end
end


%Make New Global MDS on Standardized Data
[~,eigen_Global_Zscored_Full_FromGlobalASE] = cmdscale(Dist_Global_Zscored_FromGlobalASE);
[mds_Global_Zscored_FromGlobalASE,eigen_Zscored_Global_FromGlobalASE] = cmdscale(Dist_Global_Zscored_FromGlobalASE,2);%Force 2D embedding This matches JHU

eigen_Zscored_Global_FromGlobalASE=eigen_Zscored_Global_FromGlobalASE./sum(eigen_Global_Zscored_Full_FromGlobalASE(eigen_Global_Zscored_Full_FromGlobalASE>0));

%% SAVING BLOCKS
%% Save Distance
% save regional dist explained
out_name=sprintf('Regional_Dist_Zscore_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_Regional_Zscored','dataframe')
regional_paths.dist_explained=out_file;

%save bilat dist explained
out_name=sprintf('Regional_Bilateral_Dist_Zscore_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_regional_bilat_Zscored','dataframe')
regional_paths.bilat_dist_explained=out_file;

%save global dist explained
out_name=sprintf('Global_Dist_Zscore_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_Global_Zscored','dataframe')
global_paths.dist_explained=out_file;

%save global dist explained -- from Global ASE
out_name=sprintf('Global_Dist_Zscore_FromGlobalASE_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_Global_Zscored_FromGlobalASE','dataframe')

%% Save Percent Explained
% save regional percent explained
out_name=sprintf('Regional_PercentExplained_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_regional=eigen_Zscored_Regional';
[~] = format_embedded_data_file(dataframe,test_criteria,percexplain_regional,out_file,'regionalnorepeat');
regional_paths.perc_explained=out_file;

%save bilat percent explained
out_name=sprintf('Regional_Bilateral_PercentExplained_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_regional_bilat=eigen_Zscored_bilat_Regional';
format_embedded_data_file(dataframe,test_criteria,percexplain_regional_bilat,out_file,'regional_bilatnorepeat');
regional_paths.perc_explained_bilat=out_file;

%save global percent explained
out_name=sprintf('Global_PercentExplained_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_global_longform=eigen_Zscored_Global';
format_embedded_data_file(dataframe,test_criteria,percexplain_global_longform,out_file,'globalnorepeat');
global_paths.perc_explained=out_file;

%save global percent explained -- From Global Ase
out_name=sprintf('Global_PercentExplained_Zscore_FromGlobalASE_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_global_longform=eigen_Zscored_Global_FromGlobalASE';
format_embedded_data_file(dataframe,test_criteria,percexplain_global_longform,out_file,'globalnorepeat');

%% Save ASE -- Done earlier because already formatted NOTE We don't have a bilateral ASE!!!
% %save regional ase
% out_name=sprintf('ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
% out_file=fullfile(save_dir,out_name);
% regional_paths.ase=out_file;
% format_embedded_data_file(dataframe,test_criteria,ase_regional,out_file,'regional');
% 
% %save global ase
% out_name=sprintf('Global_ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
% out_file=fullfile(save_dir,out_name);
% global_paths.ase=out_file;
% format_embedded_data_file(dataframe,test_criteria,ase_global,out_file,'global');

%% Save MDS
%For each data set convert into correct layout which is Specimen,Vertex x Vector Embedding
%save regional MDS
out_name=sprintf('Regional_MDS_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_regional_longform=reshape( permute(mds_Regional_Zscored,[3 1 2]),[size(mds_Regional_Zscored,1)*size(mds_Regional_Zscored,3),size(mds_Regional_Zscored,2)]);
format_embedded_data_file(dataframe,test_criteria,mds_regional_longform,out_file,'regional');
regional_paths.mds=out_file;

%save bilat MDS
out_name=sprintf('Regional_Bilateral_MDS_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_regional_bilat_longform=reshape( permute(mds_Regional_bilat_Zscored,[3 1 2]),[size(mds_Regional_bilat_Zscored,1)*size(mds_Regional_bilat_Zscored,3),size(mds_Regional_bilat_Zscored,2)]);
format_embedded_data_file(dataframe,test_criteria,mds_regional_bilat_longform,out_file,'regional_bilat');
regional_paths.mds_bilat=out_file;

%save global MDS
out_name=sprintf('Global_MDS_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.mds=out_file;
mds_global_longform=reshape(permute(mds_Global_Zscored,[3 1 2]),[size(mds_Global_Zscored,1)*size(mds_Global_Zscored,3),size(mds_Global_Zscored,2)]);
format_embedded_data_file(dataframe,test_criteria,mds_global_longform,out_file,'global');

%save global MDS Plot
out_name=sprintf('2D_Embedding_Plot_Global_MDS_Zscore_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_fig_prefix=fullfile(save_dir,out_name);
saved_fig_paths=plot_mds(mds_Global_Zscored,test_criteria,out_fig_prefix);
global_paths.mds_fig=saved_fig_paths; %BUT this isn't the same as the ASE that we use with the statsitical testing since we aren't doing the reduced coordinates

%save global MDS -- From Global ASE
out_name=sprintf('Global_MDS_Zscore_FromGlobalASE_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_global_longform=reshape(permute(mds_Global_Zscored_FromGlobalASE,[3 1 2]),[size(mds_Global_Zscored_FromGlobalASE,1)*size(mds_Global_Zscored_FromGlobalASE,3),size(mds_Global_Zscored_FromGlobalASE,2)]);
format_embedded_data_file(dataframe,test_criteria,mds_global_longform,out_file,'global');

%save global MDS Plot-- From Global ASE
out_name=sprintf('2D_Embedding_Plot_Global_MDS_Zscore_FromGlobalASE_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_fig_prefix=fullfile(save_dir,out_name);
saved_fig_paths=plot_mds(mds_Global_Zscored_FromGlobalASE,test_criteria,out_fig_prefix);

end