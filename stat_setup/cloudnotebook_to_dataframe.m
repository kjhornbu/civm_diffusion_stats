function [] = cloudnotebook_to_dataframe(unique_column,input_doc, ...
   opts)

%The main difference between a cloud notebook and a dataframe is just that
%the dataframe has paths to data items within it.

if isempty(opts.alternative_statsheet_dir)&&~isempty(opts.researchArchivePath)
    %if the alterative stat sheet directory is empty (default behavior) and we have research
    %archive path, take the research arhive path
    stats_archive=opts.researchArchivePath;
elseif ~isempty(opts.alternative_statsheet_dir)
    % in any case of a  alterative stat sheet directory, take it. Doesn't
    % matter if have a research archive path (just ignore what is in there).
    stats_archive=opts.alternative_statsheet_dir;
end
opts.stats_archive=stats_archive;
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

opts.fullAtlasOntology=fullAtlasOntology;




[dataFrame] = polishingData_FormingInitalRecord(cloud_notebook,unique_column,opts);

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



