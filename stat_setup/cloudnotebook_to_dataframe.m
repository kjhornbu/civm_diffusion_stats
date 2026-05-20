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

dataFrame=cloud_notebook; %This is a list of what specimen you need to grab the first step to making a dataframe is to keep the key information from teh cloud notebok

[failures] = dataframePolisher(dataFrame,unique_column,opts);
end



