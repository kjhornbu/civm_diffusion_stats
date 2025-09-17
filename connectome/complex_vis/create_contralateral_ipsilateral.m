function [output_connectome] = create_contralateral_ipsilateral(graphs,selection_group,selection_group_idx,compare_group,compare_group_idx)
% for most of our data sets the data_middle idx == 180 (data is 1:180 and
% 180+(1:180) so 1:middle_idx and middle_idx + (1: middle_idx))

output_connectome=table;
count=1;

data_middle_idx=size(graphs,2)/2;
vertex=1:size(graphs,2);
vertex=reshape(vertex,[],2);

for n=1:size(vertex,1)
    for m=1:numel(selection_group)
        for o=1:numel(compare_group)
            idx=find(and(selection_group_idx==m,compare_group_idx==o)==1);
            if isempty(idx)
                continue;
            end
            output_connectome.selection_group{count}=selection_group{m};
            output_connectome.compare_group{count}=compare_group{o};
            output_connectome.vertex(count)=vertex(n,1);
            output_connectome.ROI(count)=vertex(n,1);
            output_connectome.N(count)=numel(idx);

            output_connectome.idx_in_dataframe{count}=idx;
            %Flip L/R the Rt hemisphere respose and average with Lt
            %hemisphere

            clear connectome_parts

            temp_part1=squeeze(graphs(idx,vertex(n,1),:));

            if size(temp_part1,1)==size(graphs,2)
                connectome_parts(1,:,1)=temp_part1'; %ispsilateral
                temp_part2=[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx)));squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))];
            else
                connectome_parts(:,:,1)=temp_part1; %ispsilateral
                temp_part2=[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx))),squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))];
            end

            if size(temp_part2,1)==size(graphs,2)
                connectome_parts(1,:,2)=temp_part2'; %contralateral component
            else
                connectome_parts(:,:,2)=temp_part2;  %contralateral component
            end

            output_connectome.data{count}=mean([connectome_parts(:,:,1);connectome_parts(:,:,2)]);
            output_connectome.std_data{count}=std([connectome_parts(:,:,1);connectome_parts(:,:,2)]);

            %output_connectome.mean_data{count}=std([squeeze(graphs(idx,vertex(n,1),:));[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx))),squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))]]);
            %output_connectome.std_data{count}=std([squeeze(graphs(idx,vertex(n,1),:));[squeeze(graphs(idx,vertex(n,2),data_middle_idx+(1:data_middle_idx))),squeeze(graphs(idx,vertex(n,2),1:data_middle_idx))]]);

            output_connectome.indiv_specimen_data{count}=mean(connectome_parts,3);
            output_connectome.indiv_specimen_std{count}=std(connectome_parts,0,3);

            %output.RegionHits{count}=output.data{count}>max(output.data{count})*0.1;
            %but this is for each bit of data not everything together. --
            %If I want to see the all togther response you have to to do
            %for the actual everything.
            count=count+1;
        end
    end
end
end