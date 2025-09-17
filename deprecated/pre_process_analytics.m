function [data_frame] = pre_process_analytics(google_doc_path,polished_sheets_path,data_frame_path,bad_columns,extendedStudyColumns,column_filters)

path_to_atlasontology=fullfile(WKS_DATA,'atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt');
atlasOntology=civm_read_table(path_to_atlasontology);

reset_cols={ {'voxel_presence','none'} };
[success, fullAtlasOntology, name_to_idx, name_to_onto] = ...
    ontology_resolve_implied_rows(atlasOntology, reset_cols, [], 'quiet');
assert(success==1,'resolved implied rows of ontology data');

%% Make Polished Data Files

%% Make DataFrame
cloud_notebook=civm_read_table(google_doc_path);

%% get bad columns from the user (show the columns what ones not useful)
% remove columns which just cause trouble (SPECIFIC TO THIS CLOUD NOTEBOOK)
cols=column_find(cloud_notebook,strjoin(bad_columns,'|'),1);
cloud_notebook(:,cols)=[];

%make sure to keep key entries
cloud_notebook = civm_metadata_cleanup(cloud_notebook,extendedStudyColumns);

%% Comprehension code here
%% show ready to go table interactively
% indicate columns that could be studied and thier "unique" values
% allow user to indicate if they want to change/edit the values (additional
% typo protection)
%marker on every column if we want to omit it (drop columns checkbox)

%% special column filters? -- this filters out the remove for particular columns etc. 
%need to idicate column filters somehow...
%put in regex for include or exclude criteria (green include this /red
%exclude (red takes prescidene) 
%this)
% Remove empty runnos
empty_runno_idx=cellfun(@isempty,cloud_notebook.CIVM_Scan_ID);
cloud_notebook(empty_runno_idx,:)=[];

% run study specific inclusion/exclusion filters
for i_h=1:height(column_filters)
    col_n_reg=column_filters{i_h,1};
    col_c_reg=column_filters{i_h,2};
    inc=column_filters{i_h,3};
    matches=row_find(cloud_notebook,col_n_reg,col_c_reg,1);
    if strcmp(inc,'include')
        remove_strains_idx=~matches;
    elseif strcmp(inc,'exclude')
        remove_strains_idx=matches;
    else
        error('bad column_filter spec');
    end
    cloud_notebook(remove_strains_idx,:)=[];
end

disp('pre_process_complete');
end