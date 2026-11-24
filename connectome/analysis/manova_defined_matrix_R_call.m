function [output_file,defined_formula] = manova_defined_matrix_R_call(output_file,file,defined_formula,definition_matrix,stats_test)

code_dir=fileparts(mfilename('fullpath'));
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
        %R_BIN_LOCATION="C:\workstation\auxiliary\R-4.3.2\bin\Rscript.exe"; ---> CTX04 path to R
    elseif ismac
        R_BIN_LOCATION='/usr/local/bin/Rscript';
        % Might need to check names for this work for specific machines.
    end
end

assert(exist(R_BIN_LOCATION,'file'),'couldn''t find the Rscript program at %s', R_BIN_LOCATION);

% Wilkinson Notation https://www.jstor.org/stable/2346786?seq=1
%This already did the remove the sources if not actually using that we
%previously did. This builds stuff with and without the :

length_of_sources_of_variation=size(definition_matrix,1);

% create discrete/continous LUT
try
    vars = [stats_test.group_name,stats_test.subgroup_name]';
    types = [stats_test.variable_type_group,stats_test.variable_type_subgroup]';
    grouping={strcat('group',num2str(1:size(stats_test.group_name,1))');strcat('subgroup',num2str(1:size(stats_test.subgroup_name,1))')};
catch
    vars = stats_test.group_name;
    types = stats_test.variable_type_group;
    grouping={strcat('group',num2str(1:size(stats_test.group_name,1))')};
end
criteriaTable = table(grouping,vars,types, 'VariableNames', {'grouping_variable','variable','type'});

criteriaFile = fullfile(fileparts(output_file),'criteria.csv');

%flip into a general writing version
for n=1:height(criteriaTable)
   defined_formula=strrep(defined_formula,criteriaTable.variable{n},criteriaTable.grouping_variable{n});
end

writetable(criteriaTable,criteriaFile);

% Call R
fprintf('Calling R MANOVA\n')
try
    cmd=sprintf('%s --vanilla %s %s %s %s %d "%s"', R_BIN_LOCATION, r_code, output_file,file,criteriaFile,length_of_sources_of_variation,defined_formula);
    [s,sout]=system(cmd);
catch
    keyboard
end
assert(s==0,sout);
fprintf('R call completed\n')

end

