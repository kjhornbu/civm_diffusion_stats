function [] = EstimatedPower_Finder(save_dir,folder_loc,totalN,file,file_extension,source_of_variation,name_lookup)

    w_settings=wks_settings();
    temp_data_dir=strsplit(path_convert_platform(w_settings.data_directory,'native'),{'/','\'});
    CohenF_Path=fullfile(temp_data_dir{1},temp_data_dir{2},'code','analysis','civm_diffusion_stats','scalar','analysis','CohenF_LUTs_GivenSampleSizeandPower',strcat('CohenF_N',num2str(totalN),'_DF1Group2_at0p05_GivenPower.txt'));

    CohenF_DF1_Group2_N=civm_read_table(CohenF_Path);
    StatisticalResult=civm_read_table(strcat(save_dir,folder_loc,file,file_extension));

    StatisticalResult_reduced=StatisticalResult(reg_match(StatisticalResult.source_of_variation,source_of_variation),:);

    logical_CohenD_idx=reg_match(StatisticalResult_reduced.Properties.VariableNames,name_lookup);
    positional_CohenD_idx=find(logical_CohenD_idx);
    name_CohenD=StatisticalResult_reduced.Properties.VariableNames(positional_CohenD_idx);

    for n=1:height(StatisticalResult_reduced)
        for o=1:numel(name_CohenD)
            name_estimated_Power{o}=strrep(name_CohenD{o},'cohenD','estimated_power');
            [~,power_set_idx]=min(abs(abs(StatisticalResult_reduced.("cohenF")(n))-CohenF_DF1_Group2_N.Effect_Size));

            pos_sign_idx=StatisticalResult_reduced.(name_CohenD{:})(n)>0;
            if pos_sign_idx
                StatisticalResult_reduced.(name_estimated_Power{:})(n)=CohenF_DF1_Group2_N.Power(power_set_idx);
            else
                StatisticalResult_reduced.(name_estimated_Power{:})(n)=-1*CohenF_DF1_Group2_N.Power(power_set_idx);
            end
        end
    end
    civm_write_table(StatisticalResult_reduced,strcat(save_dir,folder_loc,file,'-Filtered_wEstPower',file_extension));
end
