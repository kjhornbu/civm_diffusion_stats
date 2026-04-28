function label_nrrd=ontology_and_slice_generator(group_stats_file,column_setup,scalar_complex_vis_dir,label_nrrd)
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
py_env=path_convert_platform(fullfile(getenv('WORKSTATION_AUX'),'py_env_svg_stack'),'native');
assert(exist(py_env,'dir'),'python setup not complete, need %s',py_env);
complex_code_dir=fileparts(which('ontology_and_slice_generator'));
assert(exist(complex_code_dir,'dir'),'Failed to find complex code dir, this is required to use the composite code');

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

%{
Original processing order of the data
ColorSlice_Figure_Generation/make_LUT_4_slicegen.m:function [LUT] = make_LUT(type,Statistical_Results,Data_Column,file_path)
ColorSlice_Figure_Generation/save_color_slice.m:function [] = save_color_slice(img_slice,filename)
ColorSlice_Figure_Generation/slice_colorer.m:function [img_slice] = slice_colorer(LUT_path,slice_data)
Ontology_Figure_Generation/coordinate_positioning.m:function [ontology_layout] = coordinate_positioning(ontology_layout)
Ontology_Figure_Generation/make_LUT.m:function [LUT, plot_lut] = make_LUT(type,Statistical_Results,Data_Column,file_path, plot_lut)
Ontology_Figure_Generation/ontology.m:function [ontology_layout] = ontology(Label_Ontology,Statistical_Results,parent_structure)
Ontology_Figure_Generation/ontology_plotting.m:function [] = ontology_plotting(ontology_layout,new_main_parent,color_LUT,file_path)
Ontology_Figure_Generation/parentage_checking.m:function [Full_Parent] = parentage_checking(table_A,table_B)
Ontology_Figure_Generation/rob_order_fixer.m:function [ontology_layout] = rob_order_fixer(ontology_layout,parent_structure)
%}

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

lut_map=containers.Map();
task_map=containers.Map();
composite_map=containers.Map();
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
            slice_name_pos=5; % where in slice_name is the position text (m1.98 etc.)

            C_metric_dir=[scalar_complex_vis_dir, strrep(sov,':','BY')];
            if ~iscell(LUT_type{i_column})
                LUT_type{i_column}=LUT_type(i_column);
            end
            colorbar_name=LUT_type{i_column}{1};
            if reg_match(LUT_type{i_column}{1},'percent_change|cohenD')
                sov={};
                slice_name_pos=slice_name_pos-1;
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
            
            try
                lookup_name_slicer=strjoin([data_identity,'lookup.txt'],'_');
            catch
                keyboard;
            end

            slice_lut_out=fullfile(lookup_dir,lookup_name_slicer);

            % creating the direct output path is deferred until below
            % inside the slice loop, so we can insert the slice
            % identifier as the first part of the filename.
            % This could all be deferred until below, however i like
            % keeping the path handling together(as much as possible)
            figure_type='slice';
            slice_dir=fullfile(C_contrast_dir{:});
            C_slice_name=[data_identity, figure_type, 'SLICELEVEL']; % RIGHT HERE DOES THE SLICE THING!!!

            slice_name_pos=find(reg_match(C_slice_name,'SLICELEVEL'));
            
            figure_type='ontology_composite';
            composite_ol_dir=fullfile(C_contrast_dir{:});
            C_ontoslice_name=[data_identity,figure_type];
            composite_out=path_convert_platform(fullfile(composite_ol_dir,'svg',[ strjoin(C_ontoslice_name,'_') '.svg' ]),'native');

            %% Get LUT for plotting
            change_data_type='percent_change|cohenD';
            clear stat_colors; % to prevent accidental re-use of wrong colors.
            if reg_match(LUT_type{i_column}{1},'pvalue')
                C_colorbar_dir={scalar_complex_vis_dir};
                stat_colors=lookup_pvalue(LUT_type{i_column}{1});
                bar_plot_opts={'proportional',false};
            elseif reg_match(LUT_type{i_column}{1},'^(singleside_cohen)$')
                C_colorbar_dir={scalar_complex_vis_dir};
                stat_colors=lookup_cohen(LUT_type{i_column}{1});
                bar_plot_opts={'proportional',false};
            elseif reg_match(LUT_type{i_column}{1},change_data_type)
                C_colorbar_dir=[C_metric_dir,'ColorBars'];
                % todo: check lut_type params for neutral, when it exists we
                % have 2.
                neutral_count=0;
                if reg_match(cell2str(LUT_type{i_column}),'neutral')
                    neutral_count=2;
                end
                % look for special keyword indicating proscribed range
                % instead of auto-calc
                idx_range=cellfun(@(x) ischar(x) && strcmp(x,'color_range'),LUT_type{i_column});
                idx_names=cellfun(@(x) ischar(x) && strcmp(x,'color_names'),LUT_type{i_column});
                if any( idx_range )
                    color_range=LUT_type{i_column}{find(idx_range)+1};
                    color_names=LUT_type{i_column}{find(idx_names)+1};
                    % force tall not wide, in case our input is backwards.
                    color_names=reshape(color_names,numel(color_names),1);
                    Color = lookup_colors_generate(numel(color_range)-neutral_count-1, false, neutral_count, false);
                else
                    desired_steps=10;
                    %color_range=lookup_range(desired_steps,neutral_count,'step_size',step_size,'neutrals_are_steps',i_tx);
                    color_range=lookup_range(desired_steps,LUT_type{i_column}{2:end});
                    [Color, color_names]=lookup_colors_generate(numel(color_range)-neutral_count-1, false, neutral_count, false);
                end
                stat_colors=lookup_colors_apply_values(Color,color_range,color_names);
                if isempty(colorbar_name)
                    % this was not specific enough in some cases.
                    %colorbar_name=measure_name;
                    colorbar_name=regexprep(uncell(measure_name),sprintf('(%s)',change_data_type),LUT_type{i_column}{1});
                end
                bar_plot_opts={};
            else
                warning('ERROR lut type not recognized.')
                keyboard
            end

            colorbar_dir=fullfile(C_colorbar_dir{:});
            out_lut=struct(...
                'png',fullfile(colorbar_dir,['ColorBar_',colorbar_name,'.png'] ),...
                'svg',fullfile(colorbar_dir,['ColorBar_',colorbar_name,'.svg'] ), ...
                'tbl',fullfile(colorbar_dir,['LUT_',colorbar_name,'.txt'] ) ...
                );
            if ~exist(lookup_dir,'dir')
                mkdir(lookup_dir);
            end
            if ~exist(colorbar_dir,'dir')
                mkdir(colorbar_dir);
            end
            
            % NOTE: direction == horizontal NOT implemented.
            bar_plot_opts=[bar_plot_opts,'direction','vertical'];
            
            % Lookup plotting **before** we stuff it into the anonymous
            % function stack.
            % lookup_plot(table2struct(stat_colors),out_bar,bar_plot_opts{:});
            %These break if we re-runstuff
            if ~exist(out_lut.tbl,'file')
                civm_write_table(stat_colors,out_lut.tbl,false,true,{},'quiet');
            end
            if (~exist(out_lut.svg,'file') || ~exist(out_lut.png,'file'))
                % but these are not ran here so the checer isn't actually
                % makign teh out_lut figures here. 

                % to prevent issue with anonymous functions this has to be
                % a var before we define the fuction. -- the problem is
                % this is making a ton of the same things

                t_st=table2struct(stat_colors);
                %This makes all the plots a ton of times for each one and
                %this is craziness. 
                lut_map(slice_lut_out)=@() lookup_plot(t_st,out_lut,bar_plot_opts{:});
            end
            if ~exist(slice_lut_out,'file')
                LUT = stat_table_lookup(segmented_Statistical_Results, columns_to_plot{i_column}, stat_colors, ontology_lookup, slice_lut_out);
                % it should be possible to switch to
                % ontology_with_stats(WHICH HAS BEEN TRIMMED) to minimal
                % N-rows.
                %LUT = stat_table_lookup(segmented_Statistical_Results, columns_to_plot{i_column}, stat_colors, ontology_with_stats, slice_lut_out);
            else 
                clear LUT;
            end
            if exist(composite_out,'file')
                continue;
            end

            %{
            % ontology
            %[oLUT, plot_lut] = make_LUT(LUT_type{i_column},segmented_Statistical_Results,columns_to_plot{i_column},scalar_complex_vis_dir,plot_lut);
            gen_olut=@() make_LUT(LUT_type{i_column},segmented_Statistical_Results,columns_to_plot{i_column},scalar_complex_vis_dir,plot_lut);
            % slice
            if ~exist(slice_lut_out,'file')
                %[sLUT] = make_LUT_4_slicegen(LUT_type{i_column},segmented_Statistical_Results,columns_to_plot{i_column},scalar_complex_vis_dir);
                %civm_write_table(sLUT,slice_lut_out,false,true,'');
                gen_lut=@() make_LUT_4_slicegen(LUT_type{i_column},segmented_Statistical_Results,columns_to_plot{i_column},scalar_complex_vis_dir);
                gen_and_write_lut=@(g_lut) civm_write_table(g_lut(),slice_lut_out,false,true,'');
                lut_map(slice_lut_out)=@() gen_and_write_lut(gen_lut);
            else% if ~exist('sLUT','var')
                lut_map(slice_lut_out)=@() fprintf('%s ready\n',slice_lut_out);
            %    sLUT=civm_read_table(slice_lut_out);
            end
            %}


            %% ontology component loop
            ontology_paths=cell(size(selected_parents));
            for i_parent = 1:numel(selected_parents)
                figure_type='ontology_segment';
                ontology_dir=fullfile(C_contrast_dir{:},figure_type);
                if strcmp(selected_parents{i_parent},'BRN-B')
                    figure_type='ontology';
                    ontology_dir=fullfile(C_contrast_dir{:});
                end
                simplified_parent_list=replace(selected_parents{i_parent},{'$','(',')','^','-B','-L','-R'},'');
                if ~ any(simplified_parent_list=='|')
                    % single parent
                    % parent_word='parent';
                else
                    % multi parent
                    % parent_word='parents';
                    simplified_parent_list=strrep(simplified_parent_list,'|','_');
                end
                %ontology_fig_name=strjoin([num2str(i_parent) data_identity parent_word simplified_parent_list ], '_' );
                ontology_fig_name=strjoin([data_identity figure_type num2str(i_parent) simplified_parent_list ], '_' );
                ontology_base_path=path_convert_platform(fullfile(ontology_dir, 'svg', ontology_fig_name),'native');
                ontology_paths{i_parent}=sprintf('%s.svg',ontology_base_path);

                % the mkdirs are all hear because whole-brain ontology is
                % segregated using figure type.
                out_dirs={ontology_dir,slice_dir,composite_ol_dir};
                for i_out_dir=1:numel(out_dirs)
                    if ~exist(out_dirs{i_out_dir},'dir')
                        mkdir(out_dirs{i_out_dir});
                    end
                end
                
                %% Find the ontology layout to actually be able to layout data only need 1 time per parent/stat_data type
                %{
                if i_contrast == 1 && i_sov == 1
                    %[ontology_layout] = ontology(ontology_with_stats,segmented_Statistical_Results,selected_parents{i_parent});
                    %[ontology_layout] = coordinate_positioning(ontology_layout);
                    
                    base_layout=@() ontology(ontology_with_stats,segmented_Statistical_Results,selected_parents{i_parent});
                    complete_layout = @(b_l) coordinate_positioning(b_l());
                end
                %}

                base_layout=@() gen_ontology_ordering_table(ontology_with_stats,segmented_Statistical_Results,selected_parents{i_parent});
                complete_layout = @(b_l) coordinate_positioning(b_l());

                %% Do actual plotting
                % PLEASE ONLY READ THIS LINE. The anonymos functions are an
                % artifact of adding delayed exection, and should be
                % refactored. 
                %ontology_plotting(ontology_layout,selected_parents{i_parent},LUT,ontology_base_path);
                
                %onto_plot=@(c_l,g_lut) ontology_plotting(c_l(base_layout),selected_parents{i_parent},g_lut(),ontology_base_path);
                %task_map(ontology_base_path)=@() onto_plot(complete_layout,gen_olut);

                onto_plot=@(c_l,lut) ontology_plotting(c_l(base_layout),selected_parents{i_parent},lut,ontology_base_path);

                if ~exist('LUT','var')
                    LUT=civm_read_table(slice_lut_out,[],[],true);
                end

                task_map(ontology_base_path)=@() onto_plot(complete_layout,LUT);
            end
            %close all;

            %% slice loop
            slice_paths=cell(size(slice_levels));
            for i_slice=1:numel(slice_levels)
                C_t_sn=C_slice_name;
                C_t_sn{slice_name_pos}=DVlevels{i_slice};
                slice_out=path_convert_platform(fullfile(slice_dir,'svg',strjoin(C_t_sn,'_')),'native');
                slice_paths{i_slice}=sprintf('%s.svg',slice_out);
                if exist(slice_out,'file')
                    continue;
                end
                %{
                slice_data=slice_level_data(:,:,i_slice);
                [img_slice] = slice_colorer(slice_lut_out,slice_data);
                save_color_slice(img_slice,slice_out);
                %}
                gen_img = @() uint8( slice_colorer(slice_lut_out,slice_level_data(:,:,i_slice)) *255 );
                %gen_and_write_img=@(g_img) save_color_slice(g_img(),slice_out);
                gen_and_write_img=@(g_img) slice_saver(g_img(),slice_out,'image');
                
                %task_list{i_task}=@() gen_and_write_img(gen_img);
                %i_task=i_task+1;
                task_map(slice_out)=@() gen_and_write_img(gen_img);
            end
            %close all;
            %% composite slice here.
            % this is different than our other code beacuase we're not
            % bothering to generate a anonymous function.
            % want a single quote around each string, so join with a ' ',
            % will require prefix/suffix quote when embedding into command.
            %py_args=strjoin( [ ontology_paths(composite_ontology_order), slice_paths(composite_slice_order) ], ''' ''');
            % set the "quote character" 
            qq=char("'");
            if ispc
                qq='"';
            end
            
            py_file=path_convert_platform(fullfile(complex_code_dir,'Python_Support','composite_ontology_w_slice.py'),'native');
            py_cmd=[ py_env 'python' py_file ontology_paths(composite_ontology_order), slice_paths(composite_slice_order) '-o' composite_out ];
            py_cmd=sprintf([qq '%s' qq ' '],py_cmd{:});
            cmd=sprintf('conda run -p %s',py_cmd);
            
            composite_map(composite_out)=cmd;
        end
    end
end
% run using much parfor
% added randperms so thatn if we have errors, and re-run we'll get more
% done.
%% parfor luts
lut_gens=lut_map.values();
lut_gen_count=numel(lut_gens);
l_keys=lut_map.keys();
fails=zeros(size(l_keys),'logical');
parfor i_lut_gen=1:lut_gen_count
    if isa(lut_gens{i_lut_gen},'function_handle')
        try
            lut_gens{i_lut_gen}();
        catch merr
            m=sprintf('lut gen %i/%i failed with error: %i',i_lut_gen,lut_gen_count,merr.message);
            warning(merr.identifier,m);
            fails(i_lut_gen)=true;
        end
    end
end
fail_count=nnz(fails);
success_count=numel(fails)-fail_count;
if fail_count
    fprintf('Retrying %i fails (%i were succesful which is %3.0f%%%)\n',fail_count, success_count, 100* success_count/numel(fails) );
end
for i_lut_gen=1:lut_gen_count
    if isa(lut_gens{i_lut_gen},'function_handle')
        try
            lut_gens{i_lut_gen}();
            fails(i_lut_gen)=false;
        catch merr
            m=sprintf('lut gen %i/%i failed with error: %i',i_lut_gen,lut_gen_count,merr.message);
            warning(merr.identifier,m);
            fails(i_lut_gen)=true;
        end
    end
end
clear TASKNAME;
if any(fails)
    fprintf('Color bar error or Missing the following lut!\n');
    fprintf('\t%s\n',l_keys{fails});
    fails=fails+1;
    msg=sprintf(['%i/%i failed to create\n' ...
        'To run one failure for debuging (see above for task names), use t_task=lut_map(TASKNAME);t_task()'], ...
        nnz(fails),lut_gen_count);
    db_inplace(mfilename,msg);
    % the task-map can bse
end

%% parfor ontologies and slices
task_list=task_map.values();
task_list=task_list(randperm(numel(task_list)));
task_count=numel(task_list);
parfor i_task=1:task_count
    if isa(task_list{i_task},'function_handle')
        try
            task_list{i_task}();
        catch merr
            warning(merr.identifier,'task %i/%i failed with error: %i',i_task,task_count,merr.message);
        end
    end
end
warning('deactivated all svg checking and copositing because of inkscape conversion fails');
return;
t_keys=task_map.keys();
fails=zeros(size(t_keys),'logical');
for i_task=1:task_count
    svg_out=sprintf('%s.svg',t_keys{i_task});
    % intermittent failures in paralllllism, lets just run here, and only
    % report fail after that.
    if ~exist(svg_out,'file')
        TASKNAME=t_keys{i_task};
        t_task=task_map(TASKNAME);t_task();
    end
    if ~exist(svg_out,'file')
        fails(i_task)=true;
    end
end
clear TASKNAME;
if any(fails)
    fprintf('Missing svg for the following tasks!\n');
    fprintf('\t%s\n',t_keys{fails});
    fails=fails+1;
    msg=sprintf(['%i/%i failed to create\n' ...
        'To run one failure for debuging (see above for task names), use t_task=task_map(TASKNAME);t_task()'], ...
        nnz(fails),task_count);
    db_inplace(mfilename,msg);
    % the task-map can bse
end

%% parfor compositing
comp_list=composite_map.values();
comp_list=comp_list(randperm(numel(comp_list)));
parfor i_comp=1:numel(comp_list)
    [s,sout]=system(comp_list{i_comp});
    if s~=0
        warning(sout);
    end
end