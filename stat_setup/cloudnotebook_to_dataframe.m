function [] = cloudnotebook_to_dataframe(unique_column,input_doc, ...
   opts)

%The main difference between a cloud notebook and a dataframe is just that
%the dataframe has paths to data items within it.


stats_archive=opts.researchArchivePath;

% stats_archive is either the "research" directory for this
% project in the primary CIVM archive, OR a folder which contains stats
% files someplace underneath it.
%
% James added the second case to support stats from the samba stats folder.
% (This is a folder where samba measures all your labels while it is
% processing.)
% 
% For both archive and arbitrary directory, it can be a cell array to
% specify multiple search locations. 
% The first valid location found will be used. 

if istable(input_doc)
    cloud_notebook=input_doc;
else
    cloud_notebook=civm_read_table(input_doc);
end

%% load (simple) ontology and resolve implications
if ~isempty(opts.overrideLabelLUT)
    atlasOntology=civm_read_table(opts.overrideLabelLUT);
    reset_cols={ {'voxel_presence','none'} };
    [success, fullAtlasOntology, name_to_idx, name_to_onto] = ontology_resolve_implied_rows(atlasOntology, reset_cols, [], 'quiet');
    assert(success==1,'resolved implied rows of ontology data');
else
    fullAtlasOntology=[];
end


% if data frame not created yet, OR cloud notebook is newer, build data
% frame and polish.

dataFrame=cloud_notebook;
failures=0;

m=1;
for n=1:height(cloud_notebook)

    [~,temp_connectome_data] = check_connectome_directory(m,n,stats_archive,cloud_notebook,unique_column,opts);

    % Stats Polisher output, NOT where the files currently live.
    polished_stats=fullfile(opts.polishedSheetPath, [cloud_notebook.(unique_column){n},'stats.txt']);
    polished_e1stats=fullfile(opts.polishedSheetPath, [cloud_notebook.(unique_column){n},'e1stats.txt']);
    
    % assign paths and variables to output dataframe
    dataFrame.vcount(n)=360; % This could be functionalized!!!!!
    dataFrame.ecount(n)=dataFrame.vcount(n)*dataFrame.vcount(n);
    
    if isfield(temp_connectome_data.headfile, 'ProgramDetails_dsi_studio_connectome_params_fiber_count')       
        % IF the headfile is found, it would have been loaded, if it was NOT
        % loaded, then we didnt find the connectome folder.
        dataFrame.tract_count(n)=temp_connectome_data.headfile.ProgramDetails_dsi_studio_connectome_params_fiber_count;
        dataFrame.connectome_file{n}=temp_connectome_data.conmat;

        dataFrame.stat_path{n}=polished_stats;
        dataFrame.stat_path_erode{n}=polished_e1stats;
        if ~isempty(opts.overrideLabelLUT)
            dataFrame.label_lookup_path{n}=opts.overrideLabelLUT;
        else
            dataFrame.label_lookup_path{n}=temp_connectome_data.lookup;
        end
        dataFrame.label_path{n}=temp_connectome_data.labels; %WE NEED THIS FOR CONNECTOMES!!!! WHY DO YOU COMMENT IT OUT JAMES/HARRISON? NEED TO FIX HOW WE GET SCALES FOR CONNECTOME FIRST 
        dataFrame.connectome_obj{n}=temp_connectome_data;
    elseif numel(fieldnames(temp_connectome_data.headfile)) == 0 && ...
            ~any(reg_match(stats_archive,'research[\/]?$'))
        % no fields in the headfile struct indicates the headfile was not loaded (and probably not found).
        % This does NOT MEAN we're not looking at archive! 
        % We should only search extra in the stats_archive when we're
        % not in the main CIVM archive to avoid getting stuck searching through all 
        % dirs in the archive, which will take forever
        % So, we add the protection against looking at the base of research archive.

        % This silly construct avoids unnecessary test for cell array. 
        % This will force search_dirs to allways be a cell array, with at
        % least 1 entry.
        search_dirs={}; search_dirs=[search_dirs,stats_archive];
        
        found_stat='NOFILE';
        idx_sd=1;
        while ~exist(found_stat,'file') && idx_sd <= numel(search_dirs)
            pattern=sprintf('%s_.+stats.txt$',cloud_notebook.(unique_column){n});
            %pattern=sprintf('%s%s',cloud_notebook.(unique_column){n},RUNNO_mod);
            found=regexpdir(search_dirs{idx_sd},pattern);
            if numel(found)
                % what about finding too many? Right now we'll just crash.
                % Leaving that for now. 
                found_stat=uncell(found);
                break;
            end
            idx_sd=idx_sd+1;
        end
        if idx_sd <= numel(search_dirs)
            % if idx_sd is less than search dirs, we found it.
            % Update the connectome object with the stat file.
            temp_connectome_data.stats=found_stat;
            for badfield=list2cell('inputs work results headfile_path program')
                temp_connectome_data.(uncell(badfield))='';
            end
            dataFrame.stat_path{n}=polished_stats;
            %dataFrame.stat_path_erode{n}=polished_e1stats;
            dataFrame.label_lookup_path{n}=opts.overrideLabelLUT;
            % dataFrame.label_path{n}=temp_connectome_data.labels;
            dataFrame.connectome_obj{n}=temp_connectome_data;
        end
    else
        % probably no headfile found
    end
end

found_stats=ismember('stat_path',dataFrame.Properties.VariableNames);
found_e1stats=ismember('stat_path_erode',dataFrame.Properties.VariableNames);
found_connectomes=ismember('connectome_file',dataFrame.Properties.VariableNames);
found_labels=ismember('label_path',dataFrame.Properties.VariableNames);

%% validate we found data to process, 
% we need stats files, or connectome files in order to process
% data, ideally we'd have both. This checks that at least some data was
% found. Individual checks happen later. 
assert(found_stats||found_connectomes, ...
    'No stats or connectome files assigned, maybe the archive is not connected? Are you sure labels and connectomes have been created?');

%% Polish stats files.
if found_stats
    missing_erode_stats_idx=false(height(dataFrame),1);
    % Because polishing is slow, we use parfor.
    % Due to limits of parfor, must pull out the relevant columns before
    % the loop.
    df_connectome_obj=dataFrame.connectome_obj;
    df_stat_path=dataFrame.stat_path;
    if found_e1stats
        df_stat_path_erode=dataFrame.stat_path_erode;
    else
        df_stat_path_erode=cell(size(df_stat_path));
    end
    parfor n=1:numel(df_connectome_obj)
        
        temp_atlas_data=fullAtlasOntology;
        temp_connectome_data=df_connectome_obj{n};
        if isempty(temp_atlas_data)
            temp_atlas_data=temp_connectome_data.lookup;
        end

        polished_stats=df_stat_path{n};
        polished_e1stats=df_stat_path_erode{n};
        if isempty(temp_connectome_data) || ~exist(temp_connectome_data.stats,'file')
            % if no input file, cannot polish. This can happen on if we do not have an archived connectome dir, OR re-run if
            % archive were disconnected. Someplace else we should address re-run.
            continue;
        end

        % have to use the new check because if the file does not exist we
        % return false.
        if ~file_time_check(polished_stats, 'newer', temp_connectome_data.stats)
            stats_polisher(temp_connectome_data.stats,temp_atlas_data,polished_stats); %,project_research_archive
        end
        if ~isempty(temp_connectome_data.e1_stats)
            if ~file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats)
                stats_polisher(temp_connectome_data.e1_stats,temp_atlas_data,polished_e1stats);
            end
        end
    end
    %% Validate polishing worked.
    for n=1:height(dataFrame)
        temp_connectome_data=dataFrame.connectome_obj{n};
        polished_stats=dataFrame.stat_path{n};
        % Have to use the newer check because if the file does not exist we
        % return false.
        have_stats_been_polished = ~isempty(temp_connectome_data) && file_time_check(polished_stats, 'newer', temp_connectome_data.stats );
        if ~found_e1stats
            stat_ready=have_stats_been_polished;
        else
            polished_e1stats=dataFrame.stat_path_erode{n};
            if ~isempty(temp_connectome_data) && ~isempty(temp_connectome_data.e1_stats)
                have_e1stats_polished = file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats );
            else
                missing_erode_stats_idx(n)=1;
                have_e1stats_polished=true; %just so we can pass through the check condition
            end
            stat_ready=(have_stats_been_polished+have_e1stats_polished)/2;
        end
        failures=failures+(1-stat_ready);
        if stat_ready < 1
            continue;
        end
        % if any labels were found, its presumed we're supposed to have
        % labels.
        if found_labels
            dataFrame.label_path{n}=temp_connectome_data.labels;
        end
    end
end
% remove connectome_obj from dataframe as it cannot be saved to spreadsheet.
dataFrame.connectome_obj=[];


%% drop data frame entries which were not populated,
% For the data cols, we will require all data files for any entry included.
% This loop marks which specimen are missing one of their data files.
data_cols=column_find(dataFrame,'^(stat_path|connectome_file)$',1);
missing_data_idx=zeros(height(dataFrame),1,'logical');
for col_name = dataFrame.Properties.VariableNames(data_cols)
    missing_data_idx=missing_data_idx|cellfun(@isempty,dataFrame.(uncell(col_name)));
end
% Remove all eroded stats if any are not found.
if found_e1stats && nnz(missing_erode_stats_idx)>0
    dataFrame=removevars(dataFrame,'stat_path_erode');
end
% If any data had labels, expect that all should have had labels. 
% This marks specimen that are missing labelsd.
if found_labels
    missing_labels_idx=cellfun(@isempty,dataFrame.label_path);
    missing_data_idx=missing_data_idx|missing_labels_idx;
end
% Save the missing entries to the "missing" data fram to record clearly
% they were excluded for misisng data, then remove them.
[p,n,e]=fileparts(opts.dataframePath);
missing_path = fullfile(p,sprintf('MISSING_%s%s', n, e));
missing_frame=dataFrame(missing_data_idx,:);
if nnz(missing_data_idx) && opts.allowMissing==0
    warning('Not all entries found');
    disp(missing_frame);
    civm_write_table(missing_frame, missing_path);
    error('Not all entries found. Terminating Execution due to Missing Specimen. If you wish to continue with Missing Specimen, add optional input "allowMissing" as true');
elseif nnz(missing_data_idx) && opts.allowMissing==1
    warning('Not all entries found');
    disp(missing_frame);
    civm_write_table(missing_frame, missing_path);
    warning('Not all entries found, see above. Proceeding with Analysis!');
    pause(3);
elseif exist(missing_path,'file')
    delete(missing_path);
end
% fix any trailing issues with column headings, they MUST be struct field
% safe due to code choices made later.
dataFrame.Properties.VariableNames=matlab.lang.makeValidName(dataFrame.Properties.VariableNames);
% drop specimen which are missing data.
dataFrame=dataFrame(~missing_data_idx,:);

%% dataframe creation complete, save.
civm_write_table(dataFrame,opts.dataframePath);
end

function [archive_idx,temp_connectome_data] = check_connectome_directory(m,n,project_research_archive,cloud_notebook,unique_column,opts)
%Checks all possible project research archives given by user for where data
%is saved.
if iscell(project_research_archive)
    temp_connectome_data=connectome_dir(project_research_archive{m},[cloud_notebook.(unique_column){n} 'NLSAM'],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    if isempty(temp_connectome_data.labels) % If not NLSAMed then it is without
        temp_connectome_data=connectome_dir(project_research_archive{m},[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    end
    archive_idx=m;

    if ~exist(temp_connectome_data.results,'dir')
        if numel(project_research_archive)==m
            return;
        else
            % lol, recursion instead of loop
            [archive_idx,temp_connectome_data] = check_connectome_directory(m+1,n,project_research_archive,cloud_notebook,unique_column,opts);
        end
    end
else
    temp_connectome_data=connectome_dir(project_research_archive,[cloud_notebook.(unique_column){n} 'NLSAM'],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    if isempty(temp_connectome_data.labels) %If not NLSAMed then it is without
        temp_connectome_data=connectome_dir(project_research_archive,[cloud_notebook.(unique_column){n}],'optional_suffix',opts.isSuffixOptional,'suffix',opts.suffix);
    end
    archive_idx = 1;
end
end
