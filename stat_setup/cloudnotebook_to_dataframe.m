function [] = cloudnotebook_to_dataframe(unique_column,input_doc,path_to_atlasontology,polished_sheets,dataframe_path,project_research_archive,optional_suffix,suffix)

if istable(input_doc)
    cloud_notebook=input_doc;
else
    cloud_notebook=civm_read_table(input_doc);
end

atlasOntology=civm_read_table(path_to_atlasontology);
reset_cols={ {'voxel_presence','none'} };

[success, fullAtlasOntology, name_to_idx, name_to_onto] = ontology_resolve_implied_rows(atlasOntology, reset_cols, [], 'quiet');
assert(success==1,'resolved implied rows of ontology data');

if ~exist(polished_sheets,'dir')
    mkdir(polished_sheets);
end

% if data frame not created yet, OR cloud notebook is newer, build data
% frame and polish.
dataFrame=cloud_notebook;
failures=0;

% optional_suffix=true;
% suffix='GMDT';

m=1;
for n=1:height(cloud_notebook)

    [~,temp_connectome_data] = check_connectome_directory(m,n,project_research_archive,cloud_notebook,unique_column,optional_suffix,suffix);

    % Stats Polisher output
    polished_stats=fullfile(polished_sheets, [cloud_notebook.(unique_column){n},'stats.txt']);
    polished_e1stats=fullfile(polished_sheets, [cloud_notebook.(unique_column){n},'e1stats.txt']);
    % have_stats_been_polished=0;
    % have_e1stats_polished=0;
    % assign paths and variables to output dataframe
    dataFrame.vcount(n)=360; % This could be functionalized!!!!!
    dataFrame.ecount(n)=dataFrame.vcount(n)*dataFrame.vcount(n);
    if isfield(temp_connectome_data.headfile, 'ProgramDetails_dsi_studio_connectome_params_fiber_count')
        dataFrame.tract_count(n)=temp_connectome_data.headfile.ProgramDetails_dsi_studio_connectome_params_fiber_count;
        dataFrame.connectome_file{n}=temp_connectome_data.conmat;
        dataFrame.stat_path{n}=polished_stats;
        dataFrame.stat_path_erode{n}=polished_e1stats;
        dataFrame.label_lookup_path{n}=path_to_atlasontology;
        % dataFrame.label_path{n}=temp_connectome_data.labels;
        dataFrame.connectome_obj{n}=temp_connectome_data;
    else
        continue;
    end
end
%remove missing entries
idx=cellfun(@isempty,dataFrame.connectome_file); 
dataFrame(idx,:)=[];

df_connectome_obj=dataFrame.connectome_obj;
df_stat_path=dataFrame.stat_path;
df_stat_path_erode=dataFrame.stat_path_erode;
parfor n=1:numel(df_connectome_obj)
    temp_connectome_data=df_connectome_obj{n};
    polished_stats=df_stat_path{n};
    polished_e1stats=df_stat_path_erode{n};
    if ~exist(temp_connectome_data.stats,'file')
        % if no input file, cannot polish. This can happen on if we do not have an archived connectome dir, OR re-run if
        % archive were disconnected. Someplace else we should address re-run.
        continue;
    end

    % have to use the new check because if the file does not exist we
    % return false.
    if ~file_time_check(polished_stats, 'newer', temp_connectome_data.stats)
        stats_polisher(temp_connectome_data.stats,fullAtlasOntology,polished_stats); %,project_research_archive
    end
    if ~isempty(temp_connectome_data.e1_stats)
        if ~file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats)
            stats_polisher(temp_connectome_data.e1_stats,fullAtlasOntology,polished_e1stats);
        end
    end
end

count_noerode=false(height(dataFrame),1);
for n=1:height(dataFrame)
    temp_connectome_data=dataFrame.connectome_obj{n};
    polished_stats=dataFrame.stat_path{n};
    polished_e1stats=dataFrame.stat_path_erode{n};

    % have to use the new check because if the file does not exist we
    % return false.
    have_stats_been_polished = file_time_check(polished_stats, 'newer', temp_connectome_data.stats );
    if ~isempty(temp_connectome_data.e1_stats)
        have_e1stats_polished = file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats );
    else
        count_noerode(n)=1;
        have_e1stats_polished=true; %just so we can pass through the check condition
    end
        
    stat_ready=(have_stats_been_polished+have_e1stats_polished)/2;
    failures=failures+(1-stat_ready);
    if stat_ready < 1
        continue;
    end
    dataFrame.label_path{n}=temp_connectome_data.labels;
end

   % T2 = removevars(T1, vars);

dataFrame.connectome_obj=[];

%remove eroded stats if any are not found
if nnz(count_noerode)>0
    dataFrame=removevars(dataFrame,'stat_path_erode');
end

%% drop data frame entries which were not populated,
% THIS IS NOT TYPICAL BEHAVIOR.
missing_entries=cellfun(@isempty,dataFrame.label_path);
[p,n,e]=fileparts(dataframe_path);
missing_path = fullfile(p,sprintf('MISSING_%s%s', n, e));
missing_frame=dataFrame(missing_entries,:);
if nnz(missing_entries)
    warning('Not all entries found');
    disp(missing_frame);
    civm_write_table(missing_frame, missing_path);
    warning('Not all entries found, see above.');
    pause(3);
elseif exist(missing_path,'file')
    delete(missing_path);
end

dataFrame=dataFrame(~missing_entries,:);

%% dataframe creation complete...
civm_write_table(dataFrame,dataframe_path);
end

function [archive_idx,temp_connectome_data] = check_connectome_directory(m,n,project_research_archive,cloud_notebook,unique_column,optional_suffix,suffix)
%Checks all possible project research archives given by user for where data
%is saved.
if iscell(project_research_archive)
    temp_connectome_data=connectome_dir(project_research_archive{m},[cloud_notebook.(unique_column){n} 'NLSAM'],'optional_suffix',optional_suffix,'suffix',suffix);
    if isempty(temp_connectome_data.labels)%If not NLSAMed then it is without
        temp_connectome_data=connectome_dir(project_research_archive{m},[cloud_notebook.(unique_column){n}],'optional_suffix',optional_suffix,'suffix',suffix);
    end
    archive_idx=m;

    if ~exist(temp_connectome_data.results,'dir')
        if numel(project_research_archive)==m
            return;
        else
            [archive_idx,temp_connectome_data] = check_connectome_directory(m+1,n,project_research_archive,cloud_notebook,unique_column,optional_suffix,suffix);
        end
    end
else
    temp_connectome_data=connectome_dir(project_research_archive,[cloud_notebook.(unique_column){n} 'NLSAM'],'optional_suffix',optional_suffix,'suffix',suffix);
    if isempty(temp_connectome_data.labels) %If not NLSAMed then it is without
        temp_connectome_data=connectome_dir(project_research_archive,[cloud_notebook.(unique_column){n}],'optional_suffix',optional_suffix,'suffix',suffix);
    end
    archive_idx = 1;
end
end
