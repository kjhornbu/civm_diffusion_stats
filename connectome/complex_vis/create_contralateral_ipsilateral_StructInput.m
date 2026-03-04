function [output_connectome] = create_contralateral_ipsilateral_StructInput(graphs,selection_name,selection_group_idx,postional_idx_selection,compare_a_name,compare_group_A_idx,positional_idx_A,compare_b_name,compare_group_B_idx,positional_idx_B)

% for most of our data sets the data_middle idx == 180 (data is 1:180 and
% 180+(1:180) so 1:middle_idx and middle_idx + (1: middle_idx))

output_connectome=table;
count=1;

data_middle_idx=size(graphs,2)/2;
vertex=1:size(graphs,2);
vertex=reshape(vertex,[],2);

%Just pulls for each compare group and selection group possible with each list of criteria in the data
%set. if you don't have data for that criteria selection it just continues.
%
for n=1:size(vertex,1)
    for m=1:2
        if mod(m,2)==1
            try
                idx=find((selection_group_idx==postional_idx_selection & compare_group_A_idx==positional_idx_A)==1);
            catch
                keyboard;
            end
        elseif mod(m,2)==0
            idx=find((selection_group_idx==postional_idx_selection & compare_group_B_idx==positional_idx_B)==1);
        end

        output_connectome.selection_group{count}=selection_name;
        if mod(m,2)==1
            output_connectome.compare_group{count}=compare_a_name;
        elseif mod(m,2)==0
            output_connectome.compare_group{count}=compare_b_name;
        end

        output_connectome.vertex(count)=vertex(n,1);
        output_connectome.ROI(count)=vertex(n,1);
        output_connectome.N(count)=numel(idx);

        output_connectome.idx_in_dataframe{count}=idx;
        %Flip L/R the Rt hemisphere respose and average with Lt
        %hemisphere

        clear connectome_parts

        temp_part1=squeeze(graphs(idx,vertex(n,1),:));

        if size(temp_part1,1)==size(graphs,2)
            connectome_parts(1,:,1)=temp_part1'; %ispsilateral, all case
            temp_part2=[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx)));squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))]; %flip data around
        else
            connectome_parts(:,:,1)=temp_part1; %ispsilateral
            temp_part2=[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx))),squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))]; %flip data around
        end

        if size(temp_part2,1)==size(graphs,2)
            connectome_parts(1,:,2)=temp_part2'; %contralateral component, all case
        else
            connectome_parts(:,:,2)=temp_part2;  %contralateral component
        end

        output_connectome.data{count}=mean([connectome_parts(:,:,1);connectome_parts(:,:,2)]);
        output_connectome.std_data{count}=std([connectome_parts(:,:,1);connectome_parts(:,:,2)]);

        output_connectome.indiv_specimen_data{count}=mean(connectome_parts,3);
        output_connectome.indiv_specimen_std{count}=std(connectome_parts,0,3);

        count=count+1;
    end
end
end