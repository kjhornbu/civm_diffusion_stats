function [opts] = setStatisticalModelInputs(opts)
%% Data setup -- User Input form

%% Unpack back into variable form
dataframe_path=opts.dataframePath;
config_file=opts.configFile;
save_dir=opts.statSaveDir;

%% Keep last Statistical Model in Config? Otherwise will take what you have passed and the prior statistical model input.


%% CHECK first what to start from [1] Dataframe? [2] cleaned/Edited google doc then Dataframe? [3] googledoc then cleaned/edited google doc then dataframe? 
opts.keep_last_frame = 0; % if 0 we are NOT keeping the last data frame, if 1 we ARE keeping the last dataframe
Connectome_Type_IDX=nnz(reg_match(opts.analysisPipelineType,'^(Connectome)$'));
for m=1:numel(opts.using_series)
    %% Do a data handler to make a new version if a dataframe or a cleanedgoogleDocPath
    if m==1
        if exist(opts.(opts.using),'file') && ~reg_match(opts.using,'^(googleDocPath)$')
            
            [opts.keep_last_frame] = do_frame_ui(opts.(opts.using),opts.using);

            if Connectome_Type_IDX & reg_match(opts.using,'^(dataframePath)$') & opts.keep_last_frame
                %If you are starting from a old dataframe it must have
                %labels inside of it to be able to process connectomic
                %data. I don't think we have to check again to confirm that
                %the dataframePath exists the using_series is generated
                %earlier and checks for that.

                temp_dataframe=civm_read_table(opts.dataframePath);
                assert(~isempty(temp_dataframe.label_path),'Cannot Keep This Exact Dataframe for Connectomics! There are no Labels provided in it!')
            end

            if ~opts.keep_last_frame
                [path,name,extension]=fileparts(opts.(opts.using));
                info=dir(opts.(opts.using));
                idate=datetime(info.date);
                idate.Format='yyyy-MM-dd''T''HHmm';
                old_file_path=fullfile(path,sprintf('%s_%s%s',name,char(idate),extension));
                movefile(opts.(opts.using),old_file_path) %stashing prior doc at same name location
            else
                % ARE KEEPING THE LAST DATAFRAME!!!

                %Clear out any lingering names in the dataframe table
                frame=civm_read_table(opts.(opts.using));
                not_empty_logical=~cellfun(@isempty,frame.Properties.VariableDescriptions);
                not_empty_positional=find(not_empty_logical);

                for n=1:numel(not_empty_positional)
                    frame.Properties.VariableDescriptions(not_empty_positional(n))={''};
                end

                civm_write_table(frame,opts.(opts.using));
            end
        else
            continue;
            %we just use the googleDocPath we don't do anything funny with it
        end
    else
        if exist(opts.(opts.using_series{m}),'file')
            [path,name,extension]=fileparts(opts.(opts.using_series{m}));
            info=dir(opts.(opts.using_series{m}));
            idate=datetime(info.date);
            idate.Format='yyyy-MM-dd''T''HHmm';
            old_file_path=fullfile(path,sprintf('%s_%s%s',name,char(idate),extension));
            movefile(opts.(opts.using_series{m}),old_file_path) %stashing prior doc at same name location
        end
    end
end

if ~opts.keep_last_frame % if 0 we are NOT keeping the last data frame, if 1 we ARE keeping the last dataframe

    %% NOT KEEPING LAST DATAFRAME
    for m=1:numel(opts.using_series)
        if reg_match(opts.using_series{m},'^(googleDocPath)$')
            notebook=civm_read_table(opts.(opts.using_series{m}));
            % force all columns to be treated as text.
            notebook=column2text(notebook,notebook.Properties.VariableNames);

            if iscell(notebook) && numel(notebook)  == 1
                notebook=uncell(notebook);
            elseif iscell(notebook) && 1 < numel(notebook)
                %James combing stuff together code
                warning('%s\n\t%s\n','experimental conjoining of data sheets.','THESE MUST BE HIGHLY COMPATIBLE FOR THIS TO WORK');
                % should I enter auto-debug for any thing requiring user intervention with
                % helpful suggestions?
                db_inplace(mfilename,'auto-debug for experimental feature. DO NOT provide cell arrays of sheets if you dont want this.');
                % load all, get column headings into cell of struct
                docs=cell([numel(notebook),1]);
                fields=cell([numel(notebook),1]);
                field_matching_required=zeros(size(notebook),'logical');
                colname_match_data=cell([numel(notebook),1]);
                for idx_d=1:numel(notebook)
                    docs{idx_d}=civm_read_table(notebook{idx_d});
                    % force all columns to be treated as text.
                    docs{idx_d}=column2text(docs{idx_d},docs{idx_d}.Properties.VariableNames);
                    fields{idx_d}=docs{idx_d}.Properties.VariableNames;
                    [not_uniform,idx_1,idx_n]=setxor(fields{1},fields{idx_d},'stable');
                    if numel( not_uniform )
                        field_matching_required(idx_d)=true;
                        colname_match_data(idx_d)={{idx_1,idx_n}};
                    end
                end
                % allow user to somehow pick which columns could conjoin...
                if any(field_matching_required)
                    all_columns=unique([fields{:}],'stable');
                    non_matching=cell2table(cell([0,numel(all_columns)]),'VariableNames',all_columns);
                    for idx_d=1:numel(notebook)
                        %[columns_to_add,idx_all]=setxor(all_columns,fields{idx_d},'stable');
                        [common_column_names,idx_all,idx_n]=intersect(all_columns,fields{idx_d},'stable');
                        %[idx_1,idx_n]=colname_match_data{idx_d}{:}
                        row_dat=zeros([1,numel(all_columns)],'logical');
                        row_dat(idx_all)=true;
                        non_matching(idx_d,:)=num2cell(row_dat);

                        % just invent columns as empties :-p
                        idx_all=find(~row_dat);
                        for idx_a=idx_all
                            col_name=all_columns{idx_a};
                            %fprintf('\t%s',col_name);
                            docs{idx_d}.(col_name)=repmat({''},[height(docs{idx_d}),1]);
                        end
                    end

                end
                cloud_notebook=concat_tables({},docs{:});
                clear docs fields field_matching_required colname_match_data idx_d idx_all idx_a idx_n col_name non_matching idx_1 all_columns not_uniform;
            end

            notebook = civm_metadata_cleanup(notebook,opts.extendedStudyColumns);
            if opts.assumeNLSAM
                % alternative options, tryNLSAM where we would at some later point
                % try with and without NLSAM, although James doesnt like that due to the ambiguouity.
                % assumes nlsam is not part of runno, and adds it.
                %cloud_notebook.CIVM_Scan_ID=cellfun(@(x) sprintf('%sNLSAM',x),cloud_notebook.CIVM_Scan_ID,'UniformOutput',false);
                % forces nlsam at end of runno, but doesnt accidentially add it
                % when it already exists.
                notebook.CIVM_Scan_ID=cellfun(@(x) regexprep(x,'^(.*?)(NLSAM)?$',"$1NLSAM"),notebook.CIVM_Scan_ID,'UniformOutput',false);
            end

        elseif reg_match(opts.using_series{m},'^(cleanedGoogleDocPath)$')
            if ~exist('notebook','var')
                % if we've not loaded a bunch of notebooks and combined them
                % already, load the notebook now.
                notebook=civm_read_table(opts.('googleDocPath'));
                % force all columns to be treated as text.
                notebook=column2text(notebook,notebook.Properties.VariableNames);

                notebook = civm_metadata_cleanup(notebook,opts.extendedStudyColumns);
                if opts.assumeNLSAM
                    % alternative options, tryNLSAM where we would at some later point
                    % try with and without NLSAM, although James doesnt like that due to the ambiguouity.
                    % assumes nlsam is not part of runno, and adds it.
                    %cloud_notebook.CIVM_Scan_ID=cellfun(@(x) sprintf('%sNLSAM',x),cloud_notebook.CIVM_Scan_ID,'UniformOutput',false);
                    % forces nlsam at end of runno, but doesnt accidentially add it
                    % when it already exists.
                    notebook.CIVM_Scan_ID=cellfun(@(x) regexprep(x,'^(.*?)(NLSAM)?$',"$1NLSAM"),notebook.CIVM_Scan_ID,'UniformOutput',false);
                end
            end

            %do visualization to do final cleanup of cloudnotebook
            edit_frame_ui(notebook,opts.(opts.using_series{m}),opts.using_series{m});

        elseif reg_match(opts.using_series{m},'^(dataframePath)$')
            % if we've not loaded a bunch of notebooks and combined them
            % already, load the notebook now.
            notebook=civm_read_table(opts.cleanedGoogleDocPath);
            % force all columns to be treated as text.

            edit_frame_ui(notebook,opts.(opts.using_series{m}),opts.using_series{m});
            cloudnotebook_to_dataframe('CIVM_Scan_ID',opts.(opts.using_series{m}),opts);
        end
    end
else
    %% KEEPING LAST DATAFRAME item
    for m=1:numel(opts.using_series)
        if reg_match(opts.using_series{m},'^(googleDocPath)$')
            notebook=civm_read_table(opts.(opts.using_series{m}));
            % force all columns to be treated as text.
            notebook=column2text(notebook,notebook.Properties.VariableNames);
            notebook = civm_metadata_cleanup(notebook,opts.extendedStudyColumns);
            if opts.assumeNLSAM
                % alternative options, tryNLSAM where we would at some later point
                % try with and without NLSAM, although James doesnt like that due to the ambiguouity.
                % assumes nlsam is not part of runno, and adds it.
                %cloud_notebook.CIVM_Scan_ID=cellfun(@(x) sprintf('%sNLSAM',x),cloud_notebook.CIVM_Scan_ID,'UniformOutput',false);
                % forces nlsam at end of runno, but doesnt accidentially add it
                % when it already exists.
                notebook.CIVM_Scan_ID=cellfun(@(x) regexprep(x,'^(.*?)(NLSAM)?$',"$1NLSAM"),notebook.CIVM_Scan_ID,'UniformOutput',false);
            end

        elseif reg_match(opts.using_series{m},'^(cleanedGoogleDocPath)$')

            %do visualization to do final cleanup of cloudnotebook
            if m==1
                %first check the NLSAM
                test_notebook=civm_read_table(opts.(opts.using_series{m}));
                if opts.assumeNLSAM
                    assert((nnz(~cellfun(@isempty,regexpi(test_notebook.CIVM_Scan_ID,'^(.*?)(NLSAM)?$'))) & opts.assumeNLSAM),"You said to use the same cleanedGoogleDocPath but there is NLSAM where there shouldn't be!")
                elseif ~opts.assumeNLSAM
                    assert(~(nnz(~cellfun(@isempty,regexpi(test_notebook.CIVM_Scan_ID,'^(.*?)(NLSAM)?$'))) & opts.assumeNLSAM),"You said to use the same cleanedGoogleDocPath but there is not NLSAM where there should be!")
                end
                clear test_notebook

                continue;
            else
                if ~exist('notebook','var')
                    % if we've not loaded a bunch of notebooks and combined them
                    % already, load the notebook now.
                    notebook=civm_read_table(opts.(opts.using_series{m}));
                    % force all columns to be treated as text.
                    notebook=column2text(notebook,notebook.Properties.VariableNames);
                end

                edit_frame_ui(notebook,opts.(opts.using_series{m}),opts.using_series{m});
            end

        elseif reg_match(opts.using_series{m},'^(dataframePath)$')
            % if we've not loaded a bunch of notebooks and combined them
            % already, load the notebook now.
            % force all columns to be treated as text.
            if m==1
                %first check the NLSAM
               test_notebook=civm_read_table(opts.(opts.using_series{m}));
                if opts.assumeNLSAM
                    assert((nnz(~cellfun(@isempty,regexpi(test_notebook.CIVM_Scan_ID,'^(.*?)(NLSAM)?$'))) & opts.assumeNLSAM),"You said to use the same Dataframe but there is NLSAM where there shouldn't be!")
                elseif ~opts.assumeNLSAM
                    assert(~(nnz(~cellfun(@isempty,regexpi(test_notebook.CIVM_Scan_ID,'^(.*?)(NLSAM)?$'))) & opts.assumeNLSAM),"You said to use the same Dataframe but there is not NLSAM where there should be!")
                end
                clear test_notebook

                continue;
            else
                if ~exist('notebook','var')
                    notebook=civm_read_table(opts.cleanedGoogleDocPath);
                    notebook=column2text(notebook,notebook.Properties.VariableNames);
                end
                edit_frame_ui(notebook,opts.(opts.using_series{m}),opts.using_series{m});
                cloudnotebook_to_dataframe('CIVM_Scan_ID',opts.(opts.using_series{m}),opts);
            end
        end
    end
end

%% Stats Setup
% set a setup.mat path where we can save the configuration data, to let
% people skip it next time.
if isempty(config_file)
    [~,n,~]=fileparts(dataframe_path);
    config_file=fullfile(save_dir,sprintf('%s_setup.mat',n));
end

clear n;
% check thing exists -- intialize to do it.
opts.keep_last_setup=0;
if exist(config_file,'file')
    % prompt for keeping configuration (1 == keep)
    opts.keep_last_setup=do_configuration_ui(config_file);

    if ~opts.keep_last_setup
        % when NOT keeping, rename the previous to contain its save date so
        % we can tell what we ran and when.
        info=dir(config_file);
        [p,n,~]=fileparts(config_file);
        idate=datetime(info.date);
        idate.Format='yyyy-MM-dd''T''HHmm';
        old_file=fullfile(p,sprintf('%s_%s.mat',n,char(idate)));
        movefile(config_file,old_file)
        clear info idate old_file;
    end
end
clear p n;

if ~opts.keep_last_setup
    configuration_table=stats_configuration_ui(dataframe_path);
    statistical_model=assignmodelmatrix_ui(configuration_table);
    clear configuration_table
    [statistical_model]=pairwise_compare_ui_apply2summary(statistical_model,dataframe_path);

    %save configuration struct (which now includes
    % pariwise_criteria)
    save(config_file,'statistical_model','-mat');
else
    % load configuration struct (which now includes
    % pariwise_criteria)
    load(config_file,'statistical_model');
end

%save opts so can redo fully
temp_opt=strsplit(config_file,'.mat');
opts_file=strcat(temp_opt{1},'_opts.mat');

opts.statistical_model=statistical_model;

if exist(opts_file,'file')
    % rename the previous to contain its save date so
    % we can tell what we ran and when.
    info=dir(opts_file);
    [p,n,~]=fileparts(opts_file);
    idate=datetime(info.date);
    idate.Format='yyyy-MM-dd''T''HHmm';
    old_file=fullfile(p,sprintf('%s_%s.mat',n,char(idate)));
    movefile(opts_file,old_file)
    clear info idate old_file;
end

save(opts_file,'opts','-mat');

end