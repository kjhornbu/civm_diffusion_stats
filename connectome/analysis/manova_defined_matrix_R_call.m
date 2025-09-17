function [output_file,defined_formula] = manova_defined_matrix_R_call(output_file,file,test_criteria,definition_matrix,stats_test)

code_dir=fileparts(mfilename('fullpath'));
%code_dir=fileparts(which('omni_manova_processing_main'));
r_code=fullfile(code_dir,'manova_defined_matrix_nways.R');
assert(exist(r_code,'file'),'couldn''t find the R file to run');
[s,R_BIN_LOCATION]=system('which Rscript');
R_BIN_LOCATION=regexprep(R_BIN_LOCATION,'[\s]$','');

if s~=0
    % fall back hard-coded paths if auto-find doesnt work.
    if ispc
        warning('Tell james Rscript was not found automatically for matlab!');
        wks_home=getenv('WORKSTATION_HOME');
        % THE VERSION IS HARD CODED ON PURPOSE. R (like python) has lots of
        % chaos around libraries and version incompatabilities. 
        R_BIN_LOCATION=fullfile(wks_home,'auxiliary\R-4.3.2\bin\Rscript.exe');
        %R_BIN_LOCATION="C:\workstation\auxiliary\R-4.3.2\bin\Rscript.exe"; %CTX04 path to R
    elseif ismac
        R_BIN_LOCATION='/usr/local/bin/Rscript';
        %R_BIN_LOCATION='/usr/local/bin/Rscript'; %General Mac Version -- Might
        %need to check names for this work for specific machines.
    end
end
assert(exist(R_BIN_LOCATION,'file'),'couldn''t find the Rscript program at %s', R_BIN_LOCATION);

test_criteria_text=test_criteria{1};

% we're in progress figuring out how to set random variables in manova. 
% currently it doesnt work, so this is false.
WIP_R_RANDOM_STATS=false;

%assignEffect Type
if WIP_R_RANDOM_STATS
    for n=1:numel(test_criteria_text)
        temp=strsplit(test_criteria_text{n},'group');
        if isempty(temp{1})
            stats_test.random{n}=stats_test.effect_type_group{str2double(temp{2})};
        elseif regexpi(temp{1},'sub')
            stats_test.random{n}=stats_test.effect_type_subgroup{str2double(temp{2})};
        else
            keyboard;
        end
    end
end
% Wilkinson Notation https://www.jstor.org/stable/2346786?seq=1
%This already did the remove the sources if not actually using that we
%previously did. This builds stuff with and without the :

for n=1:size(definition_matrix,1)

    R_form_test_criteria{n}=strjoin(test_criteria_text(logical(definition_matrix(n,:))),':');

    if WIP_R_RANDOM_STATS
        if sum(random_terms)>0
            random_terms=~cellfun(@isempty,regexpi(stats_test.random(logical(definition_matrix(n,:))),'^(random)$'));
            R_form_test_criteria{n}=strcat('(1|',R_form_test_criteria{n},')');
        end
    end

end
length_of_sources_of_variation=size(definition_matrix,1);

% Call R
fprintf('Calling R MANOVA\n')
try
    cmd=sprintf('%s --vanilla %s %s %s %d "%s"', R_BIN_LOCATION, r_code, output_file,file,length_of_sources_of_variation,strjoin(R_form_test_criteria,'+'));
    [s,sout]=system(cmd);
catch
    keyboard
end
assert(s==0,sout);
fprintf('R call completed\n')

defined_formula=strjoin(R_form_test_criteria,'+');
end

