function [ontology_layout] = coordinate_positioning(ontology_layout)
%The full coordinate positioning in the ontology being determined

[number_of_parent_value,~,number_of_parent_idx]=unique(ontology_layout.ontology_level);
Values_At_Level=number_of_parent_idx==1:numel(number_of_parent_value)';

%we find the ontology layout height and bar start for all entries first
for level=1:size(Values_At_Level,2)
    location_logical_idx=Values_At_Level(:,level);
    location_positional_idx=find(location_logical_idx==1);

    if level>1
        [unique_parent_ROI_at_level,~,unique_parent_ROI_at_level_idx]=unique(ontology_layout.ontology_order_ROI(location_positional_idx,level-1),'stable');
        %This is the unique counter for entries under a parent at a
        %given level. each unique parent has its own counter

    elseif level==1
        %if no parent position starts at zero because we just place
        %data starting at 0
        unique_parent_ROI_at_level=0;
        unique_parent_ROI_at_level_idx=1;

    end

    for unique_parent_number=1:numel(unique_parent_ROI_at_level)
        entry_start_position=0;

        %need to know the start position of the most direct parent, so
        %can shift the data into the correct bucket.
        if unique_parent_ROI_at_level==0
            %if no parent start at zero
            parent_entry_start_position=0;

            logical_entries_to_use=unique_parent_ROI_at_level_idx==unique_parent_number;
            positional_entries_to_use=find(logical_entries_to_use==1);

        else
            %adjust parent entry starting to the start of the parents bar
            parent_entry_start_position=ontology_layout.start_of_bar(ontology_layout.ROI==unique_parent_ROI_at_level(unique_parent_number));

            if isempty(parent_entry_start_position)
                keyboard;
            end
            
            logical_entries_to_use=unique_parent_ROI_at_level_idx==unique_parent_number;
            positional_entries_to_use=find(logical_entries_to_use==1);
        end
        for entry_at_level=1:numel(positional_entries_to_use)
            %Need to know how many children exist for the entry to assign the height of the column.

            logical_height=ontology_layout.ROI(location_positional_idx(positional_entries_to_use(entry_at_level)))==ontology_layout.ontology_order_ROI;

            column_height=sum(and(sum(logical_height,2)>0,ontology_layout.ontology_most_child));

            if column_height==0
                column_height=1; %For most child region we just make the smallest basis unit which is 1.
            end

            %assign for keeping track of data
            ontology_layout.length_of_bar(location_positional_idx(positional_entries_to_use(entry_at_level)))=column_height;
            ontology_layout.start_of_bar(location_positional_idx(positional_entries_to_use(entry_at_level)))=entry_start_position+parent_entry_start_position;

            entry_start_position=entry_start_position+column_height;
        end

    end
end
end