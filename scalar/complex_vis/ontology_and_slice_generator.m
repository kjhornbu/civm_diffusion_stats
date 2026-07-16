function [plot_queue,composite_queue,label_nrrd]=ontology_and_slice_generator(group_stats_file,column_setup,scalar_complex_vis_dir,label_nrrd)

%% load static data (atlas stats and centroids, and combine, also set-up label nrrd)
% use test code to auto-find label ontology, also load centroids.
w_settings=wks_settings();
% atlas_name='symmetric15um';
atlas_name='DMBA';
label_nick='RCCF';
atlas_label_dir=fullfile(path_convert_platform(w_settings.data_directory,'native'),'atlas',atlas_name,'labels',label_nick);

atlas_stats_file=fullfile(atlas_label_dir,sprintf('%s_%s_ontology_with_stats.txt',atlas_name,label_nick));
atlas_centroid_file=fullfile(atlas_label_dir,sprintf('%s_%s_labels_centroids.txt',atlas_name,label_nick));
atlas_lookup_file=fullfile(atlas_label_dir,sprintf('%s_%s_labels_lookup.txt',atlas_name,label_nick));
atlas_label_file=fullfile(atlas_label_dir,sprintf('%s_%s_labels.nhdr',atlas_name,label_nick));

% this is configued to default load ontology
ontology_with_stats=civm_read_table(atlas_stats_file,[],[],true);
% load centroids
atlas_centroids=civm_read_table(atlas_centroid_file,[],[],true);

check_data_in_centroid={'id64_fSABI','centroid_'};
logical_check_data_in_centroid=~cellfun(@isempty,regexpi(atlas_centroids.Properties.VariableNames,strjoin(check_data_in_centroid,'|')));
Label_Ontology_Centroid_cleaned=atlas_centroids(:,logical_check_data_in_centroid);

ontology_with_stats=innerjoin(ontology_with_stats,Label_Ontology_Centroid_cleaned,'Keys',{'id64_fSABI'});
% remove temporaries.
clear atlas_centroid_file check_data_in_centroid logical_check_data_in_centroid atlas_centroids Label_Ontology_Centroid_cleaned

slicer_lookup=civm_read_table(atlas_lookup_file,[],[],true);
% it is NOT good enough to simply load the lookuptable, we have to resolve
% any implied entries to process successfully.
%
% Alternatively, we could load the ontology_with_stats where all the
% implications have been previously resolved. But that is not standard
% distribution data yet.
reset_cols=[{'ROI'},{{'voxel_presence','none'}}];
[success,ontology_lookup,name_to_idx,name_to_onto]=ontology_resolve_implied_rows(slicer_lookup,reset_cols);

if exist('label_nrrd','var') && ~isa(label_nrrd,'nrrd')
    label_nrrd=nrrd(atlas_label_file);
end

%% settings for these figures.
% VARIABLES columns_to_plot and LUT_type MUST HAVE THE SAME NUMBER OF ELEMENTS.
columns_to_plot = column_setup(:,2);
LUT_type = column_setup(:,1);

%{'^(CEN-B|CCX-B)$','DIE-B','^(RVG-B|MID-B|HBR-B|CBN-B|CBX-B)$','wmt-B'};
% to get whole brain ontology use BRN-B; -- this has CBL at the end of the
% HBR which ROB dislikes but we would need a split HBR structure to have it
% work otherwise.
%
% I'm processing the 'decided' 4 partial ontologies, followed by the full.
% This is becuase i've added the parent index to the output name as the
% first part of the name, to group the 4 parts together. maybe that is a
% mistake.
% Careful, while these look like regular expressions(and they are) they are
% ALSO keywords which must match exactly. We'll improve that code when we
% can.

selected_parents = {'^(CEN-B|CCX-B)$','DIE-B','^(RVG-B|MID-B|HBR-B|CBN-B|CBX-B)$','wmt-B','BRN-B'};
% the order the selected parents will be insterted into the specialized
% composite_ontology_w_slice.py code. Change these indicies accordingly.
% that code expects (gray_1,gray_2,gray_3,white)
composite_ontology_order= [1,2,3,4];

change_data_type='percent_change|cohenD|estimated_power'; 
% these are assignable color ranges that you can modify via shifting the white
% center and maximal color bar value -- rather than the other color ranges which are fixed.

% VARIABLES levels and DVlevels MUST HAVE THE SAME NUMBER OF ELEMENTS.
DVlevels={'M4p88','M3p96','M2p96','M1p98'};
% the order the selected parents will be insterted into the specialized
% composite_ontology_w_slice.py code. Change these indicies accordingly.
% that code expects (slice_m488,slice_m396,slice_m198)
composite_slice_order=[1,2,4];
if strcmp(atlas_name,'DMBA')
    slice_levels=[212,273,340,405]; %in DMBA (0:599)*0.015-8.0385
elseif strcmp(atlas_name,'symmetric15um')
    slice_levels=[168,222,276,329]; %in Symmetric 15 RCCF Entry points (0:535)*0.015-4.0125
end

%% run-config checks.
assert(numel(columns_to_plot)==numel(LUT_type),'setup error, must have same number of elements');

%% read stats
Statistical_Results=civm_read_table(group_stats_file,[],[],true);

% check that the requested stats are present
stat_col_numbers=column_find(Statistical_Results,sprintf('^(%s)$',strjoin(columns_to_plot,'|')));
assert(numel(stat_col_numbers)==numel(unique(columns_to_plot)), 'Requested columns not properly resolved, check the requested columns');

% but this isn't finding it twice??? What if I want multiple things plotted
% different color ranges -- don't do it here.

[source_of_variation_names,~,source_of_variation_idx]=unique(Statistical_Results.source_of_variation);
[contrast_names,~,contrast_idx]=unique(Statistical_Results.contrast);
% remove temporaries.
clear stat_col_numbers

%% read label data
if isempty(label_nrrd.data)
    label_nrrd.load_data();
end
if strcmp(label_nrrd.axis_order,'LPS')
    slice_level_data=label_nrrd.data(:,:,slice_levels);
elseif strcmp(label_nrrd.axis_order,'RAS')
    slice_level_data=label_nrrd.data(:,end:-1:1,slice_levels);
end

%% create ontology plots of columns, and colored slices.
% parfor will put the figure creation in the background, making the
% computer still useable while generating figures.
% There may be an alternate method for that using matlab function "openfig"
%
% maps are like hashes/dictionaries, this lets us avoid repeating work.
% keys are the file paths with values being anonymous functions.

plot_queue=containers.Map();
composite_queue=containers.Map();

for i_column=1:numel(columns_to_plot) % Each of the contrast types we are doing
    for i_sov=1:numel(source_of_variation_names)
        source_of_variation_logical_idx=source_of_variation_idx==i_sov;
        for i_contrast=1:numel(contrast_names)

            contrast_logical_idx=contrast_idx==i_contrast;
            plot_idx=and(contrast_logical_idx,source_of_variation_logical_idx);
            segmented_Statistical_Results=Statistical_Results(plot_idx,:);

            %% figure out where to save
            sov=source_of_variation_names(i_sov);
            sov_name_pos=2; % where in contrast_dir is the sov
           % slice_name_pos=5; % where in slice_name is the position text (m1.98 etc.)

            C_metric_dir=[scalar_complex_vis_dir, strrep(sov,':','BY')];

            if ~iscell(LUT_type{i_column})
                LUT_type{i_column}=LUT_type(i_column);
            end
            colorbar_name=LUT_type{i_column}{1};

            if reg_match(LUT_type{i_column}{1},change_data_type)
                sov={};
                %slice_name_pos=slice_name_pos-1;
                %C_contrast_dir{sov_name_pos}='percent_change';
                C_metric_dir{sov_name_pos}=LUT_type{i_column}{1};

                if numel(LUT_type{i_column}) == 1
                    % we have a simple lookup configuration, so we need to
                    % specifiy desired min/max for data.
                    %
                    % This is for when we use constant ranges.
                    % alternatively, those COULD be coded in for the
                    % complex config.
                    if reg_match(LUT_type{i_column}{1},'percent_change')
                        c_mm={'min',-0.1,'max',0.1}; % This is the color range
                        c_neutral={'neutral',[-0.025, 0.025]};%KH Shifted from 0.05 to 0.01 on 202600130 to better represent CHDI-- and 2.5% on 20260327 You should do this within the name of the color itself
                    elseif reg_match(LUT_type{i_column}{1},'estimated_power')
                        c_mm={'min',-0.95,'max',0.95}; % This is the color range
                        c_neutral={'neutral',[-0.7, 0.7]};% Estimated power uses the same color range as CohenD/percent Change but the white center is +/- 70% and color extends to
                    elseif reg_match(LUT_type{i_column}{1},'cohenD')
                        % inital range proposed by yuqi
                        c_mm={'min',-2,'max',2};
                        % this was a first guess a good neutral range.
                        % Seems like it is probably too narrow... but so is
                        % the percent chanage ?
                        c_neutral={'neutral',[-0.2, 0.2]};
                    end
                    LUT_type{i_column}=[LUT_type{i_column}, c_mm];
                    if reg_match(LUT_type{i_column}{1},'_WN')
                        LUT_type{i_column}=[LUT_type{i_column}, c_neutral];
                    end
                else
                    % complex color setup, need to identify colorbar more
                    % specifically, will use a test for empty to see that.
                    colorbar_name={};
                end
            end


            measure_name=regexprep(columns_to_plot(i_column),'(_-)+','');
            if numel(LUT_type{i_column})==1
                data_identity=[sov, contrast_names{i_contrast}, measure_name,LUT_type{i_column}];
            else
                data_identity=[sov, contrast_names{i_contrast}, measure_name];
            end
            data_identity=strrep(data_identity,':','BY');

            C_contrast_dir=[C_metric_dir, contrast_names{i_contrast}];
            lookup_dir=fullfile(C_contrast_dir{:},'lookup_tables');
            if ~exist(lookup_dir,'dir')
                mkdir(lookup_dir);
            end

            try
                lookup_name_slicer=strjoin([data_identity,'lookup.txt'],'_');
            catch
                keyboard;
            end

            slice_lut_out=fullfile(lookup_dir,lookup_name_slicer);


            if reg_match(LUT_type{i_column}{1},'pvalue')
                C_colorbar_dir={scalar_complex_vis_dir};
            elseif reg_match(LUT_type{i_column}{1},'^(singleside_cohen)$')
                C_colorbar_dir={scalar_complex_vis_dir};
            elseif reg_match(LUT_type{i_column}{1},change_data_type) 
                C_colorbar_dir=[C_metric_dir,'ColorBars'];
            end
            
            colorbar_dir=fullfile(C_colorbar_dir{:});

            if ~exist(colorbar_dir,'dir')
                mkdir(colorbar_dir);
            end

            if isempty(colorbar_name)
                % this was not specific enough in some cases.
                %colorbar_name=measure_name;
                colorbar_name=regexprep(uncell(measure_name),sprintf('(%s)',change_data_type),LUT_type{i_column}{1});
            end
            out_lut=struct(...
                'png',fullfile(colorbar_dir,['ColorBar_',colorbar_name,'.png'] ),...
                'svg',fullfile(colorbar_dir,['ColorBar_',colorbar_name,'.svg'] ), ...
                'tbl',fullfile(colorbar_dir,['LUT_',colorbar_name,'.txt'] ) ...
                );

            [~,bar_plot_opts] = prepare_LUT(change_data_type,LUT_type, i_column,out_lut.tbl);
            queue_color_bar_plot(plot_queue,bar_plot_opts,out_lut)

            if ~exist(slice_lut_out,'file')
                stat_table_lookup(segmented_Statistical_Results, columns_to_plot{i_column}, out_lut.tbl, ontology_lookup, slice_lut_out);
            end

            %% Ontology Generation
            [ontology_paths] = prepare_layout_tables(C_contrast_dir,selected_parents,data_identity,segmented_Statistical_Results,ontology_with_stats);
            queue_ontology_plotting(plot_queue,ontology_paths,selected_parents,slice_lut_out)
            %% Slice Generation
            [slice_paths] = prepare_slice_levels(C_contrast_dir,slice_levels,DVlevels,data_identity);
            queue_slice_plotting(plot_queue,slice_paths,slice_levels,slice_level_data,slice_lut_out);
            %% Compositing of Onotology + Slice
            select_ontology_paths=ontology_paths(composite_ontology_order);
            select_slice_paths=slice_paths(composite_slice_order);
            [composite_out] = prepare_composite(C_contrast_dir,data_identity);
            queue_compositing(composite_queue, composite_out,select_ontology_paths,select_slice_paths)
        end
    end
end
end
