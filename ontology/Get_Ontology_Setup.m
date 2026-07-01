% clear all
% close all;

w_settings=wks_settings();

atlas_name='DMBA';
label_nick='RCCF';
atlas_label_dir=fullfile(path_convert_platform(w_settings.data_directory,'native'),'atlas',atlas_name,'labels',label_nick);

atlas_stats_file=fullfile(atlas_label_dir,sprintf('%s_%s_ontology_with_stats.txt',atlas_name,label_nick));
atlas_centroid_file=fullfile(atlas_label_dir,sprintf('%s_%s_labels_centroids.txt',atlas_name,label_nick));

% this is configued to default load ontology
ontology_with_stats=civm_read_table(atlas_stats_file,[],[],true);
% load centroids
atlas_centroids=civm_read_table(atlas_centroid_file,[],[],true);

check_data_in_centroid={'id64_fSABI','centroid_'};
logical_check_data_in_centroid=~cellfun(@isempty,regexpi(atlas_centroids.Properties.VariableNames,strjoin(check_data_in_centroid,'|')));
Label_Ontology_Centroid_cleaned=atlas_centroids(:,logical_check_data_in_centroid);

ontology_with_stats=innerjoin(ontology_with_stats,Label_Ontology_Centroid_cleaned,'Keys',{'id64_fSABI'});
% remove temporaries.
clear atlas_centroid_file check_data_in_centroid logical_check_data_in_centroid atlas_centroids Label_Ontology_Centroid_cleaned

%selected_parents = {'BRN-B'};
selected_parents ={'^(RVG-B|MID-B|HBR-B|CBN-B|CBX-B)$'};

for parent=1:numel(selected_parents)
    [ontology_layout] = gen_ontology_ordered(ontology_with_stats,selected_parents{parent});
end

[ontology_layout] = coordinate_positioning(ontology_layout);
ontology_layout=ontology_layout(ontology_layout.ontology_most_child==1,:);

ontology_layout.ontology_order_ROI=[];
ontology_layout.ontology_order_Structure=[];

%Fix offset issue at start of the ontology
idx=ontology_layout.start_of_bar==0;
pos_idx=find(idx);

ontology_layout.start_of_bar(ontology_layout.start_of_bar>0)=ontology_layout.start_of_bar(ontology_layout.start_of_bar>0)+numel(pos_idx);
ontology_layout.start_of_bar(pos_idx)=pos_idx;

for n=2:height(ontology_layout)
    ontology_layout.ontology_order_GN_Symbol{n}=strrep(ontology_layout.ontology_order_GN_Symbol{n},' ','');
    ontology_layout.ontology_order_GN_Symbol{n}=strrep(ontology_layout.ontology_order_GN_Symbol{n},'-B','');
    ontology_layout.ontology_order_GN_Symbol{n}=strjoin(ontology_layout.ontology_order_GN_Symbol{n},'-');
end

ontology_layout=sortrows(ontology_layout,'start_of_bar','descend');

ontology_layout.L_Vertex=ontology_layout.ROI;
ontology_layout.R_Vertex=ontology_layout.L_Vertex+180;

civm_write_table(ontology_layout,'Ontology_Layout_DMBA_20260317_RobFixedOrder.txt')
