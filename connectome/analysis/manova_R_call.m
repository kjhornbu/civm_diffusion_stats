function [output_file,defined_formula] = manova_R_call(output_file,file,test_criteria)

if ispc
    home_path=getenv('WORKSTATION_HOME');
    R_BIN_LOCATION=fullfile(home_path,'auxiliary\R-4.3.2\bin\Rscript.exe');
    %R_BIN_LOCATION="C:\workstation\auxiliary\R-4.3.2\bin\Rscript.exe"; %CTX04 path to R
elseif ismac
    R_BIN_LOCATION='/usr/local/bin/Rscript';
    %R_BIN_LOCATION='/usr/local/bin/Rscript'; %General Mac Version -- Might
    %need to check names for this work for specific machines.
end


%Clean test_critera form
R_form_test_critera=test_criteria{1};

    %Call R
    fprintf('Calling R MANOVA\n')

if ispc
        cmd=sprintf('%s --vanilla c:/workstation/code/analysis/Omni_Manova/manova_nways.R  %s %s %s', R_BIN_LOCATION, output_file,file,strjoin(R_form_test_critera));
        [s,sout]=system(cmd);
elseif ismac
    try
        cmd=sprintf('%s --vanilla /Users/Shared/workstation/code/analysis/Omni_Manova/manova_nways.R  %s %s %s', R_BIN_LOCATION,output_file,file,strjoin(R_form_test_critera));
        [s,sout]=system(cmd);
    catch
        cmd=sprintf('%s --vanilla /Volumes/workstation/code/analysis/Omni_Manova/manova_nways.R %s %s %s', R_BIN_LOCATION, output_file,file,strjoin(R_form_test_critera));
        [s,sout]=system(cmd);
    end
end
  
    if s~=0
        error(sout);
    end
    fprintf('R call completed\n')


defined_formula=strjoin(R_form_test_critera,'*');

end

