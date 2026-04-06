function [opts] = optsErrorChecking(opts)

%% check for correct fields for study parameters

analysisMethodIdx=reg_match(opts.analysisPipelineType,'^(Scalar|Connectome)$');

if nnz(analysisMethodIdx)<numel(analysisMethodIdx)
    error('%d analysis pipeline types are not the correct term. Allowed options are: Scalar, Connectome or 1xN of options cell array',numel(analysisMethodIdx)-nnz(analysisMethodIdx))
end


pvalTypeIdx=reg_match(opts.pvalType,'^(pval_BH|pval)$');

if nnz(pvalTypeIdx)<numel(pvalTypeIdx)
    error('%d pvalue types are not the correct term. Allowed options are: pval_BH, pval or 1xN of options cell array ',numel(pvalTypeIdx)-nnz(pvalTypeIdx))
end

%% Check data sheets
if ~isempty(opts.dataframePath) &&  exist(opts.dataframePath,'file')
     %use dataframePath 
     opts.using='dataframePath';
     % Ask if want to remake the dataframe at location
else
    if ~isempty(opts.cleanedGoogleDocPath) && exist(opts.cleanedGoogleDocPath,'file')
        %use cleanedGoogleDocPath
        % Make a dataframePath and save to default location to output
        % directory or the dataframePathProvided
        opts.using='cleanedGoogleDocPath';
    else
        if ~isempty(opts.googleDocPath) && exist(opts.googleDocPath,'file')
            %use googleDocPath
            % Make a cleanedGoogleDocPath and save
            % Make a dataframePath and save
            opts.using='googleDocPath';
        else
            %ERROR
            error('You need to provide at least 1 datapath file: the google document (googleDocPath), a cleaned google document (cleanedGoogleDocPath), or a specific precreated dataframe (dataframePath).');
        end
    end
end

if reg_match(opts.using,'^(googleDocPath)$')
    opts.using_series={'googleDocPath','cleanedGoogleDocPath','dataframePath'};
elseif reg_match(opts.using,'^(cleanedGoogleDocPath)$')
    opts.using_series={'cleanedGoogleDocPath','dataframePath'};
elseif reg_match(opts.using,'^(dataframePath)$')
    opts.using_series={'dataframePath'};
end

%% Check input sheet polishing
if exist(opts.polishedSheetPath,'dir')
    if ~isempty(opts.polishedSheetPath)
        %opts.polish='checkcomplete';
        %polishedsheets have already been formed. Check to make sure all
        %have been polished for given sheet then continue
    elseif isempty(opts.researchArchivePath) && isempty(opts.polishedSheetPath)
        error('polishedSheetPath has not been populated and there is no research archive to pull from! Provide "researchArchivePath" so the sheets can be polished.');
    end
else
    if ~isempty(opts.polishedSheetPath)
        mkdir(opts.polishedSheetPath)
        if ~isempty(opts.researchArchivePath)
            %make polishing from research archive Path
           % opts.polish='startnew';
        else
            error('polishedSheetPath has not been populated and there is no research archive to pull from! Provide "researchArchivePath" so the sheets can be polished.');
        end
    else
        error('polishedSheetPath has not been populated! We will not know where to save polished sheet if you do not provide a path!');
    end
end

%% Check that save folder exists and if not make one
if ~exist(opts.statSaveDir,'dir')
    mkdir(opts.statSaveDir);
end
end