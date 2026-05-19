function [dataFrame] = polishingData_FormingInitalRecord(cloud_notebook,unique_column,opts)

% if data frame not created yet, OR cloud notebook is newer, polish data
% and make sure dataFrame records what we get.

dataFrame=cloud_notebook; %This is a list of what specimen you need to grab
failures=0;

m=1;

for n=1:height(cloud_notebook)

    [~,temp_connectome_data] = check_connectome_directory(m,n,cloud_notebook,unique_column,opts);

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
        if nnz(reg_match(opts.analysisPipelineType,'Connectome'))
            %  For connectomes only grab the label files
            dataFrame.label_path{n}=temp_connectome_data.labels; %WE NEED THIS FOR CONNECTOMES!!!! WHY DO YOU COMMENT IT OUT JAMES/HARRISON? NEED TO FIX HOW WE GET SCALES FOR CONNECTOME FIRST
        end

        dataFrame.connectome_obj{n}=temp_connectome_data;
    elseif numel(fieldnames(temp_connectome_data.headfile)) == 0 && ~isempty(opts.alternative_statsheet_dir) &&...
            ~any(reg_match(opts.stats_archive,'research[\/]?$'))
        
        % no fields in the headfile struct indicates the headfile was not loaded (and probably not found).
        % This does NOT MEAN we're not looking at archive!
        % We should only search extra in the stats_archive when we're
        % not in the main CIVM archive to avoid getting stuck searching through all
        % dirs in the archive, which will take forever
        % So, we add the protection against looking at the base of research archive.

        % This silly construct avoids unnecessary test for cell array.
        % This will force search_dirs to allways be a cell array, with at
        % least 1 entry.

        search_dirs={}; search_dirs=[search_dirs,opts.stats_archive];

        found_stat='NOFILE';
        idx_sd=1;
        while ~exist(found_stat,'file') && idx_sd <= numel(search_dirs)
            pattern=sprintf('%s_.+stats.txt$',cloud_notebook.(unique_column){n});
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
            dataFrame.label_lookup_path{n}=opts.overrideLabelLUT;
            dataFrame.connectome_obj{n}=temp_connectome_data;

            if nnz(reg_match(opts.analysisPipelineType,'Connectome'))
                error('You cannot run the alterative stat sheet directory form of analysis for connectomic processing!!! Change "analysisPipelineType" to ONLY scalar mode.')
            end
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

        temp_atlas_data=opts.fullAtlasOntology;
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

end

