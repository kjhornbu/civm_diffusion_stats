function [ ] = create_circos_file(directory,ontology,total_Ordering,vertex_select,output,selection_pull,group_A,group_B,threshold)

[vertex,~,vertex_idx]=unique(output.vertex);
atlas_ontology_path=fullfile(getenv("WORKSTATION_HOME"),'static_data','atlas','symmetric15um','labels','RCCF','symmetric15um_RCCF_labels_lookup.txt'); 
atlas_ontology=civm_read_table(atlas_ontology_path);

atlas_ontology=atlas_ontology(~isnan(atlas_ontology.ROI)&~(atlas_ontology.ROI==0)&atlas_ontology.ROI<1200,:); %filter the atlas ontology to just the cannonical atlas minus the exterior

for n=1:size(vertex_select,1)
    for m=1:numel(selection_pull)

        vertex_position=find(vertex_select(n)==vertex);

        idx_A=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,group_A)) & vertex_idx==vertex_position;
        idx_B=~cellfun(@isempty,regexpi(output.selection_group,strcat('^(',selection_pull{m},')$'))) & ~cellfun(@isempty,regexpi(output.compare_group,group_B)) & vertex_idx==vertex_position;

        % paths we are going to save data at
        A_name=fullfile(directory,strcat(selection_pull{m},'_',group_A,'_vertex_',num2str(vertex_select(n)),'_circos_input_file_atTHRES',num2str(threshold)));
        B_name=fullfile(directory,strcat(selection_pull{m},'_',group_B,'_vertex_',num2str(vertex_select(n)),'_circos_input_file_atTHRES',num2str(threshold)));

        if ~exist(A_name,'dir')
            mkdir(A_name);
        end

        if ~exist(B_name,'dir')
            mkdir(B_name);
        end

        %normalize together
        normalization_metric=max(max([output.data{idx_A};output.data{idx_B}]));

        %this data is in ROI order
        raw_percent_A=output.data{idx_A}./normalization_metric;
        raw_percent_B=output.data{idx_B}./normalization_metric;

        % Get abbrevation for the seed region
        Seed_ABB=ontology.GN_Symbol{ontology.ROI==vertex_select(n)};

        %Prep Map.txt
        prep_map_4_circos(A_name,atlas_ontology,total_Ordering)
        prep_map_4_circos(B_name,atlas_ontology,total_Ordering)

        %Prep Map Links.txt (the actual data)
        prep_data_4_circos(A_name,raw_percent_A,Seed_ABB,ontology,total_Ordering,threshold);
        prep_data_4_circos(B_name,raw_percent_B,Seed_ABB,ontology,total_Ordering,threshold);
    end
end

end