function [cloud_notebook] = check_consistency_N_spelling(cloud_notebook)

% disp(sprintf('INSTRUCTIONS:\n\n Change The Name of The File to "cloud_notebook".\n Make sure "Variable Names Row" is the correct row of the headers.\n Check the header row names parsed correctly.\n Make sure "range" only includes the data (not header info or meta trash).\n Take note of the extra columns (the #), we will remove them in a later step.\n'))
% uiimport(google_doc); 

%Check spelling Column heading
%check spelling entries

common_civm_words=list2cell("ID civm NLSAM DTIcs SAMBA connectome recon UTHSC QA T1 T2 MGRE calc 7T 7Ta 9T DOB M F C57BL/6 BXD[0-9][0-9] BXD[0-9][0-9][0-9]");

for n=1:size(cloud_notebook,2)
    [valf,~,idx]=unique(cloud_notebook(:,n));

    column_name=valf.Properties.VariableNames;
    column_name_split=strsplit(column_name{:},'_');

    updated_column_name = correctSpelling(tokenizedDocument(column_name_split));


    for m=1:size(column_name_split,2)
        in_common_civm_words(m)=sum(~cellfun(@isempty,regexpi(common_civm_words,column_name_split{m})))>0;

        if  in_common_civm_words(m)
            new_column_name{m}=column_name_split{m};
        else
            new_column_name{m}=char(updated_column_name.tokenDetails.Token(m));
        end
    end

    cleaned_column_name=lower(strjoin(new_column_name,'_'));

    cloud_notebook.Properties.VariableNames{n}=cleaned_column_name;

    if ~isnumeric(valf.(column_name{:}))
        keyboard;

        [inner_valf,~,inner_idx]=unique(valf.(column_name{:}));

        updated_inner_valf= correctSpelling(tokenizedDocument(inner_valf));
        
       

        for m=1:size(column_name_split,2)
            in_common_civm_words(m)=sum(~cellfun(@isempty,regexpi(common_civm_words,column_name_split{m})))>0;

            if  in_common_civm_words(m)
                new_column_name{m}=column_name_split{m};
            else
                new_column_name{m}=char(updated_column_name.tokenDetails.Token(m));
            end
        end

    end
end

end