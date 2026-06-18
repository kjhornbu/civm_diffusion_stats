function [failures] = dataframePolisher(dataFrame,unique_column,opts)

failures=0;
m=1;

% Stats Polisher output, NOT where the files currently live. Get all output
% paths for all things we care about first!
for o=1:numel(opts.scalarContrastMetrics)
    %polished_stats{o,:}=fullfile(opts.polishedSheetPath,strcat(dataFrame.(unique_column),opts.scalarContrastMetrics(o).stat_extension{:}));
    polished_stats{o,:}=fullfile(opts.polishedSheetPath,strcat(dataFrame.(unique_column),opts.scalarContrastMetrics(o).Name{:}));
end

for n=1:height(dataFrame)
    [~,temp_connectome_data] = check_connectome_directory(m,n,dataFrame,unique_column,opts);
    % assign paths and variables to output dataframe
    dataFrame.vcount(n)=360; % This could be functionalized!!!!!
    dataFrame.ecount(n)=dataFrame.vcount(n)*dataFrame.vcount(n);

    if isfield(temp_connectome_data.headfile, 'ProgramDetails_dsi_studio_connectome_params_fiber_count')
        check='connectome_dir_load';
        % IF the headfile is found, it would have been loaded, if it was NOT
        % loaded, then we didnt find the connectome folder.
        dataFrame.tract_count(n)=temp_connectome_data.headfile.ProgramDetails_dsi_studio_connectome_params_fiber_count;
        dataFrame.connectome_file{n}=temp_connectome_data.conmat;

        %several of these assume the former method/ method 1 for the temp
        %connectome dir object would need to revise when finished deciding
        %which one to use. 

        for o=1:numel(opts.scalarContrastMetrics)
            dataFrame.(opts.scalarContrastMetrics(o).Column{:}){n}=polished_stats{o}{n};
        end
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
        check='flat_file_load';
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
            pattern=sprintf('%s_.+stats.txt$',dataFrame.(unique_column){n});
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
            temp_connectome_data.regionaldata(1).stats=found_stat;
            for badfield=list2cell('inputs work results headfile_path program')
                temp_connectome_data.(uncell(badfield))='';
            end
            dataFrame.(opts.scalarContrastMetrics(1).Column{:}){n}=polished_stats{1}{n}; %No it puts it into stat_path if it just is a folder of data.
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

if reg_match(check,'^(flat_file_load)$')
    found_stats=ismember(opts.scalarContrastMetrics(1).Column{:},dataFrame.Properties.VariableNames);
elseif reg_match(check,'^(connectome_dir_load)$')
    for o=1:numel(opts.scalarContrastMetrics)
        found_stats(o)=ismember(opts.scalarContrastMetrics(o).Column{:},dataFrame.Properties.VariableNames);
    end
end

found_connectomes=ismember('connectome_file',dataFrame.Properties.VariableNames);
found_labels=ismember('label_path',dataFrame.Properties.VariableNames);

%% validate we found data to process,
% we need stats files, or connectome files in order to process
% data, ideally we'd have both. This checks that at least some data was
% found. Individual checks happen later.
assert(sum(found_stats)>=1||found_connectomes, ...
    'No stats or connectome files assigned, maybe the archive is not connected? Are you sure labels and connectomes have been created?');

if sum(found_stats)>=1
    missing_stats_idx=false(height(dataFrame),1);

    % Because polishing is slow, we use parfor.
    % Due to limits of parfor, must pull out the relevant columns before
    % the loop.

    input_path=dataFrame.connectome_obj;
    output_path=polished_stats;

%% now polish the stats
    stats_polisher_bulk(output_path,input_path,opts.fullAtlasOntology,opts.scalarContrastMetrics)

    %% Validate polishing worked.
    for n=1:height(dataFrame)
        temp_connectome_data=dataFrame.connectome_obj{n};
        polished_stats=dataFrame.(opts.scalarContrastMetrics(1).Column{:}){n};
        % Have to use the newer check because if the file does not exist we
        % return false.
        have_stats_been_polished = ~isempty(temp_connectome_data) && file_time_check(polished_stats, 'newer', temp_connectome_data.regionaldata(1).stats );
        if numel(found_stats)==1
            stat_ready=have_stats_been_polished;
        else
            polished_e1stats=dataFrame.stat_path_erode{n};
            if ~isempty(temp_connectome_data) && ~isempty(temp_connectome_data.e1_stats)
                have_e1stats_polished = file_time_check(polished_e1stats, 'newer', temp_connectome_data.e1_stats );
            else
                missing_stats_idx(n)=1;
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
if nnz(missing_stats_idx)>0
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