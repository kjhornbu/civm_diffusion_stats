function [regional_paths, global_paths, dataframe] = omnibus_embedding_prelim_processing(...
    dataframe_path, save_dir, ...
    group, subgroup, test_criteria, zscore_configuration, ...
    do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale, set_scale)
%
% dataframe_path = DERP
% save_dir = DOORP
% full_test_criteria = a cell containing a 1x2 cell of main effects source of variation
% zscore_configuration = things to Z-score on to remove their effect from
% the system. This can be empty.
% stats_test = matrix config
% b,m,p,a = binary flags
% set_scaling = load volume data and apply to connectome counts
%
% example input
% omnibus_embedding_prelim_processing(dataframe_path, save_dir, ...
%    group, subgroup, full_test_criteria, zscore_configuration, stats_test, ...
%    do_binarize, do_mean_subtract, do_ptr, do_augment, find_scale,
%    set_scale);

%Run_Omni_Manova_Script-- Kathryn Hornburg
% Takes John Hopkins Script for generating Omni Manova and converts it into
% a single Matlab file for analysis.
% Path-- This is the folder for the saving location for all plots, figures, and data sets.
% Filename-- This is the full file name (including path of the file if not in the same folder as this script) for the "sorted
% dataframe" of data. This is a look up table for the You must make a "sorted dataframe" for yourself to pass into the program
% by using excel
% ROI -- these are the ROI's you are most interested in. In most cases you
% will run this script once without knowing this value, then run it again
% once you know the most significant ROIs.

% the "DO" functions are a set of functions to flag (either give a 1 or 0)
% Binarize-- Converts connectome to 0's and 1's if there is not a
% connection on the node or if there is
% Mean Subtract -- Remove average response from connectome (do we want to
% see how the data set deviates from one another)
% PTR-- pass to rank, for a given roi seed, changes nodes so ranked 1:N
% given number of connections in a given vertex.
% Augument-- adjusts the values of the diagonal so the responses are spread
% along that instead of being just 0.

% Import Data
dataframe=civm_read_table(dataframe_path);

% sort based on study groupings
col_names=dataframe.Properties.VariableNames;
col_headings=[group,subgroup];
for h=1:numel(col_headings)
    n=column_find(col_names,col_headings{h});
    col_headings{h}=col_names{n};
end
dataframe=sortrows(dataframe,col_headings);

%% Changes the DF into the group/subgroup way of analysis rather than user friendly method allowed now.
[dataframe] = clean_df_to_general_entries(group,subgroup,dataframe);

%% set up output path structures
regional_paths=struct;
global_paths=struct;

%% using small file recording run time as indicator we've done this
% before and dont need to repeat.
t_start=tic;
ase_runtime_path=fullfile(save_dir,'ASE_run_time.headfile');
region_cols=list2cell('ase mds mds_bilat perc_explained'); %asedist perc_explained_bilat
global_cols=list2cell('ase mds mds_fig perc_explained');
if ~exist(save_dir,'dir')
    mkdir(save_dir);
end
if file_time_check(ase_runtime_path, 'newer', dataframe_path)
    update_needed=0;
    run_data=read_headfile(ase_runtime_path);
    for col_idx=1:numel(region_cols)
        col=region_cols{col_idx};
        regional_paths.(col)=run_data.(sprintf('r_%s',col));
        if ~exist(regional_paths.(col),'file')
            update_needed=update_needed+1;
        end
    end
    for col_idx=1:numel(global_cols)
        col=global_cols{col_idx};
        global_paths.(col)=run_data.(sprintf('g_%s',col));
        f=global_paths.(col);
        % for mds_fig we get two outputs(at least) so this'll check them
        % all for us.
        if ~iscell(f)
           f={f};
        end
        if ~ all(cellfun(@(x) exist(x,'file'),f))
            update_needed=update_needed+1;
        end
    end
    if not( update_needed )
        warning('Assuming complete because %s exists\n',ase_runtime_path);
        return;
    end
end

%% Find the Scale Factor Needed for the Dataframe and saves the df back into the same location
if find_scale==1
    [dataframe] = finding_scale_values(dataframe,dataframe_path);
    % df.scale=df.scale*2; forced scale factor for 2022-10-12 dsi studio
end

%Check the test conditions remove stuff we can't run
number_experimental_setups=size(test_criteria,2);
assert(number_experimental_setups==1,'james broke doing more than one');

%% Load Data: This loads up all the connectome files... Sped up by removing multiple loading of atlas and using the dsi connectivity to create a smart loading with zero offsets.
% Fixed partially because the double loading of data in .mat specification
graphs=load_graph(dataframe);

%% Embedd The Graph Data into a Single N-D Space based on ASE -- Adjacent spectral embedding...
% aka latent variables of the connectome you can do adjustments of properties withe the do functions and/or set scale,...
% Give MDS as space reduction comparision.. (which require distance matrices hence why also giving them on output).
[graphs, ase_regional, ase_global,...
    mds_global, mds_regional, mds_regional_bilat,...
    Dist_global, Dist_regional, Dist_regional_bilat,...
    main_embedding_median_eigen, eigen_Global, eigen_regional, eigen_regional_bilat]...
    = graphs_to_omnibus_embedding(dataframe, graphs, do_binarize, do_mean_subtract, do_ptr, do_augment, set_scale);

%% SAVING BLOCKS
out_name=sprintf('Median_ASE_Model_Explains_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain=main_embedding_median_eigen';
[percexplain] = format_embedded_data_file(dataframe,test_criteria,percexplain,out_file,'globalnorepeat');
regional_paths.median_ase_model_explains=out_file;

%% Save Distance
% save regional dist explained
out_name=sprintf('Regional_Dist_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_regional','dataframe')
regional_paths.dist_explained=out_file;

%save bilat dist explained
out_name=sprintf('Regional_Bilateral_Dist_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_regional_bilat','dataframe')
regional_paths.bilat_dist_explained=out_file;

%save global dist explained
out_name=sprintf('Global_Dist_%i%i%i%i.mat',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
save(out_file,'Dist_global','dataframe')
global_paths.dist_explained=out_file;

%% Save Percent Explained
% save regional percent explained
out_name=sprintf('Regional_PercentExplained_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_regional=eigen_regional';
[percexplain_regional] = format_embedded_data_file(dataframe,test_criteria,percexplain_regional,out_file,'regionalnorepeat');
regional_paths.perc_explained=out_file;

%save bilat percent explained
out_name=sprintf('Regional_Bilateral_PercentExplained_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_regional_bilat=eigen_regional_bilat';
[percexplain_regional_bilat] = format_embedded_data_file(dataframe,test_criteria,percexplain_regional_bilat,out_file,'regional_bilatnorepeat');
regional_paths.perc_explained_bilat=out_file;

%save global percent explained
out_name=sprintf('Global_PercentExplained_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
percexplain_global_longform=eigen_Global';
[percexplain_global] = format_embedded_data_file(dataframe,test_criteria,percexplain_global_longform,out_file,'globalnorepeat');
global_paths.perc_explained=out_file;

%% Save ASE
%save regional ase
out_name=sprintf('ASE_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
regional_paths.ase=out_file;
[ase_regional] = format_embedded_data_file(dataframe,test_criteria,ase_regional,out_file,'regional');
ase_param_count=numel(column_find(ase_regional,'^X[0-9]+$'));

%save global ase
out_name=sprintf('Global_ASE_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.ase=out_file;
[ase_global] = format_embedded_data_file(dataframe,test_criteria,ase_global,out_file,'global');

%% Save MDS
%For each data set convert into correct layout which is Specimen,Vertex x Vector Embedding
%save regional MDS
out_name=sprintf('Regional_MDS_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_regional_longform=reshape( permute(mds_regional,[3 1 2]),[size(mds_regional,1)*size(mds_regional,3),size(mds_regional,2)]);
[mds_regional] = format_embedded_data_file(dataframe,test_criteria,mds_regional_longform,out_file,'regional');
regional_paths.mds=out_file;

%save bilat MDS
out_name=sprintf('Regional_Bilateral_MDS_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
mds_regional_bilat_longform=reshape( permute(mds_regional_bilat,[3 1 2]),[size(mds_regional_bilat,1)*size(mds_regional_bilat,3),size(mds_regional_bilat,2)]);
[mds_regional_bilat] = format_embedded_data_file(dataframe,test_criteria,mds_regional_bilat_longform,out_file,'regional_bilat');
regional_paths.mds_bilat=out_file;

%save global MDS
out_name=sprintf('Global_MDS_%i%i%i%i.csv',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_file=fullfile(save_dir,out_name);
global_paths.mds=out_file;
mds_global_longform=reshape( permute(mds_global,[3 1 2]),[size(mds_global,1)*size(mds_global,3),size(mds_global,2)]);
[mds_global] = format_embedded_data_file(dataframe,test_criteria,mds_global_longform,out_file,'global');

%save global MDS Plot
out_name=sprintf('2D_Embedding_Plot_Global_MDS_%i%i%i%i',do_binarize,do_mean_subtract,do_ptr,do_augment);
out_fig_prefix=fullfile(save_dir,out_name);
saved_fig_paths=plot_mds(mds_global,test_criteria,out_fig_prefix);
global_paths.mds_fig=saved_fig_paths; %BUT this isn't the same as the ASE that we use with the statsitical testing since we aren't doing the reduced coordinates

%% Save Semipar Distance
% save for jmp(ha)
%warning('save-unwrapped-asedist doesnt work. (yet?)');
% save_unwrapped_asedist()

if ~isempty(zscore_configuration) &&  ~isempty(zscore_configuration{1})
    %updates the global and regional paths to the zscored form if
    %needed. -- search for Zscore in name for later rather than
    %having a flag
    % 
    % Warnings dear programmer, previously zscore configuration would
    % wander into this function with one per test_critera.
    % NOW there is only ONE test critera, that is why this has a cell of 1 going into the zscore applicator
    % 
    % When you finish testing, you should track down and clean that up.
    warning('zscoring function currently is untested');
    [regional_paths, global_paths] = Zscore_Applied_to_ASE(save_dir,dataframe,test_criteria,zscore_configuration{1},do_binarize,do_mean_subtract,do_ptr,do_augment,regional_paths, global_paths,ase_regional,ase_global);
end

%% save run time in seconds to use as flag for completion.
% include paths to output files for reload purpose.
t_run=toc(t_start);
time_out=struct;
time_out.run_time=t_run;
time_out.group=strjoin(cellsimplify(group));
time_out.subgroup=strjoin(cellsimplify(subgroup));
time_out.test_criteria=strjoin(cellsimplify(test_criteria));
time_out.save_dir=save_dir;
time_out.data_frame=dataframe_path;
for col_idx=1:numel(region_cols)
    col=region_cols{col_idx};
    time_out.(sprintf('r_%s',col))=regional_paths.(col);
end
for col_idx=1:numel(global_cols)
    col=global_cols{col_idx};
    time_out.(sprintf('g_%s',col))=global_paths.(col);
end
write_headfile(ase_runtime_path,time_out);

end
