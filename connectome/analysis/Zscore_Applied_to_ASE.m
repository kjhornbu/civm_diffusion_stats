function [regional_paths, global_paths] = Zscore_Applied_to_ASE( ...
    save_dir,dataframe, test_criteria, test_remove_criteria, ...
    do_binarize, do_mean_subtract, do_ptr, do_augment,...
    regional_paths, global_paths,...
    ase_regional, ase_global)

%% Remove Any effects from ASE
% Find the mean and standard deviation values and compare to the
% values... both regional and global.

[ase_regional_zscore] = zscoring_finder_connectome(ase_regional, test_criteria, test_remove_criteria{:});
[ase_global_zscore] = zscoring_finder_connectome(ase_global, test_criteria, test_remove_criteria{:});

%% Save ASE
%save regional ase
out_name=sprintf('ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
regional_paths.ase=out_file;
writetable(ase_regional_zscore, out_file); %No need to reformat because already done -- save directly

%save global ase
out_name=sprintf('Global_ASE_Zscore_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.ase=out_file;
writetable(ase_global_zscore, out_file); %No need to reformat because already done -- save directly

tensor_ase_zscored = select_data_in_EmbeddingFile(ase_regional_zscore,height(ase_global_zscore),height(ase_regional_zscore)/height(ase_global_zscore));

%% Make Regional (Regular and Bilat) Dist from Standarized ASE Regional Data
for roi=1:(height(ase_regional_zscore)/height(ase_global_zscore))
    for length_n=1:height(ase_global_zscore)
        for length_m=1:height(ase_global_zscore)
            Dist_Regional_Zscored(length_n,length_m,roi)=norm(tensor_ase_zscored(:,roi,length_n)-tensor_ase_zscored(:,roi,length_m),'fro');
            if roi <= (height(ase_regional_zscore)/height(ase_global_zscore))/2
                %% Make Bilat Regional Dist on Standarized ASE Regional Data
                Dist_regional_bilat_Zscored(length_n,length_m,roi)=norm(tensor_ase_zscored(:,[roi roi+(height(ase_regional_zscore)/height(ase_global_zscore))/2 ],length_n)-tensor_ase_zscored(:,[roi roi+(height(ase_regional_zscore)/height(ase_global_zscore))/2],length_m),'fro');
            end
        end
    end
    [mds_Regional_Zscored(:,:,roi),eigen_Zscored_Regional(:,roi)] = find_MDS(Dist_Regional_Zscored(:,:,roi));
    if roi <= (height(ase_regional_zscore)/height(ase_global_zscore))/2
        [mds_Regional_bilat_Zscored(:,:,roi),eigen_Zscored_bilat_Regional(:,roi)] = find_MDS(Dist_regional_bilat_Zscored(:,:,roi));
    end
end

%% Make Global Dist from Standarized ASE Regional Data
for length_n=1:height(ase_global_zscore)
    for length_m=1:height(ase_global_zscore)
        Dist_Global_FromRegionalZscored(length_n,length_m)=norm(tensor_ase_zscored(:,:,length_n)-tensor_ase_zscored(:,:,length_m),'fro');
    end
end

[mds_Global_Zscored,eigen_Zscored_Global] = find_MDS(Dist_Global_FromRegionalZscored);
% 
% %re=embedding Global from Regional Zscored ASE
% V=sort(eig(sqrt(Dist_Global_FromRegionalZscored*transpose(Dist_Global_FromRegionalZscored))),'descend');
% elb=getElbows(V,3); %-- this doesn't have as much of the analysis
% 
% [U,D,~]=svds(Dist_Global_FromRegionalZscored,elb(2)); 
% ase_GlobalReembed_FromRegionalZscore=U*sqrt(D);
% ase_GlobalReembed_FromRegionalZscore=(fliplr(ase_GlobalReembed_FromRegionalZscore));
% 
% ase_GlobalReembed_FromRegionalZscore_table=ase_global_zscore;
% ase_GlobalReembed_FromRegionalZscore_table.X1=ase_GlobalReembed_FromRegionalZscore(:,1);
% ase_GlobalReembed_FromRegionalZscore_table.X2=ase_GlobalReembed_FromRegionalZscore(:,2);
% %ase_GlobalReembed_FromRegionalZscore_table.X3=ase_GlobalReembed_FromRegionalZscore(:,3);
% 
% tensor_ase_GlobalReembed_FromRegionalZscore = select_data_in_EmbeddingFile(ase_GlobalReembed_FromRegionalZscore_table,height(ase_GlobalReembed_FromRegionalZscore_table),1);
% 
% %Make Global Dist From the ASE_Global Response
% for length_n=1:height(ase_global_zscore)
%     for length_m=1:height(ase_global_zscore)
%         Dist_GlobalReembed_FromRegionalZscored(length_n,length_m)=norm(tensor_ase_GlobalReembed_FromRegionalZscore(:,:,length_n)-tensor_ase_GlobalReembed_FromRegionalZscore(:,:,length_m),'fro');
%     end
% end
% 
% [mds_GlobalReembed_FromRegionalZscored,eigen_GlobalReembed_FromRegionalZscored] = find_MDS(Dist_GlobalReembed_FromRegionalZscored);
% 
% 
% [ase_Zscore_GlobalReembed_FromRegionalZscore_table] = zscoring_finder_connectome(ase_GlobalReembed_FromRegionalZscore_table, test_criteria, test_remove_criteria{:});
% tensor_ase_Zscore_GlobalReembed_FromRegionalZscore = select_data_in_EmbeddingFile(ase_Zscore_GlobalReembed_FromRegionalZscore_table,height(ase_Zscore_GlobalReembed_FromRegionalZscore_table),1);
% 
% %Make Global Dist From the ASE_Global Response
% for length_n=1:height(ase_global_zscore)
%     for length_m=1:height(ase_global_zscore)
%         Dist_Global_Zscore_GlobalReembed_FromRegionalZscore(length_n,length_m)=norm(tensor_ase_Zscore_GlobalReembed_FromRegionalZscore(:,:,length_n)-tensor_ase_Zscore_GlobalReembed_FromRegionalZscore(:,:,length_m),'fro');
%     end
% end
% 
% [mds_Global_Zscore_GlobalReembed_FromRegionalZscore,eigen_Global_Zscore_GlobalReembed_FromRegionalZscore] = find_MDS(Dist_Global_Zscore_GlobalReembed_FromRegionalZscore);

tensor_ase_global = select_data_in_EmbeddingFile(ase_global_zscore,height(ase_global_zscore),1);
%Make Global Dist From the ASE_Global Response
for length_n=1:height(ase_global_zscore)
    for length_m=1:height(ase_global_zscore)
        Dist_Global_FromGlobalZscored(length_n,length_m)=norm(tensor_ase_global(:,:,length_n)-tensor_ase_global(:,:,length_m),'fro');
    end
end

[mds_Global_FromGlobalZscored,eigen_Global_FromGlobalZscored] = find_MDS(Dist_Global_FromGlobalZscored);

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
save(out_file,'Dist_Global_FromRegionalZscored','dataframe')
global_paths.dist_explained=out_file;

%save global dist explained -- from Global ASE
out_name=sprintf('Global_Dist_Zscore_FromGlobalASE_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_Global_FromGlobalZscored','dataframe')

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
percexplain_global_longform=eigen_Global_FromGlobalZscored';
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
[mds_Global_Zscored] = format_embedded_data_file(dataframe,test_criteria,mds_global_longform,out_file,'global');
%save global MDS Plot
out_name=sprintf('2D_Embedding_Plot_Global_MDS_Zscore_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_fig_prefix=fullfile(save_dir,out_name);
saved_fig_paths=plot_mds(mds_Global_Zscored,test_criteria,out_fig_prefix);
 %BUT this isn't the same as the ASE that we use with the statsitical testing since we aren't doing the reduced coordinates

%save global MDS -- From Global ASE
out_name=sprintf('Global_MDS_Zscore_FromGlobalASE_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_global_longform=reshape(permute(mds_Global_FromGlobalZscored,[3 1 2]),[size(mds_Global_FromGlobalZscored,1)*size(mds_Global_FromGlobalZscored,3),size(mds_Global_FromGlobalZscored,2)]);
[mds_Global_Zscored_FromGlobalASE] = format_embedded_data_file(dataframe,test_criteria,mds_global_longform,out_file,'global');
%save global MDS Plot-- From Global ASE
out_name=sprintf('2D_Embedding_Plot_Global_MDS_Zscore_FromGlobalASE_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_fig_prefix=fullfile(save_dir,out_name);
saved_fig_paths=plot_mds(mds_Global_Zscored_FromGlobalASE,test_criteria,out_fig_prefix);
global_paths.mds_fig=saved_fig_paths;
end