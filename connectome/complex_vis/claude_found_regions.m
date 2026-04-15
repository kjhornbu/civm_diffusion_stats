function [temp_key,connections_for_key_inLUT,output_ontology_set] = claude_found_regions(connection_LUT,ontology_Order,key_node)
%finds the regions with the given abbreviations in the claude look up
%sheets as it compares with the ontology. reorders the parsed ontology into
%a front to back of brain ordering.
ontology_Order.ontology_order=[1:height(ontology_Order)]';

key_idx=ontology_Order.ROI==key_node; 
key_positional_idx=find(key_idx);

temp_key=ontology_Order(key_positional_idx,:);

structure_key_parts=strsplit(temp_key.Structure{:},'_');

connections_idx=reg_match(connection_LUT.REGION,structure_key_parts{1});
connections_for_key_inLUT=connection_LUT(connections_idx,:);

structure_allregion_parts=cellfun(@strsplit, ontology_Order.Structure(:),repmat({'__'},height(ontology_Order),1), 'UniformOutput', false); 
structure_allregion_parts=vertcat(structure_allregion_parts{:});

[~,first_instance,~]=unique(connections_for_key_inLUT.NODE,'stable');
connections_for_key_inLUT=connections_for_key_inLUT(first_instance,:);

connections_for_key_inLUT.DIRECTION=[]; % Direction doesn't matter in diffusion because we do not have ability to measure direction.

output_ontology_set=table;
count=1;
try
    for n=1:height(connections_for_key_inLUT)
        idx_region=reg_match(structure_allregion_parts(:,1),strcat('^(',connections_for_key_inLUT.NODE{n},')$'));
        if sum(idx_region)
            connections_for_key_inLUT.Found_In_DMBA(n)=1;
            output_ontology_set(count,:)=ontology_Order(idx_region,:);
            count=count+1;
        else
            connections_for_key_inLUT.Found_In_DMBA(n)=0;
        end
    end
catch
    keyboard;
end

try
    output_ontology_set=sortrows(output_ontology_set,'start_of_bar','descend'); %so these are in ontology order now
catch
    keyboard;
end
end