function [output,s_X] = specimen_2_specimen(Data)
% groups to compare is the study condition you want to compare centroid to
% centroid distance over (for example in 18gaj42 we are comparing old
% versus young so this is the centroid to centroid distance of whatever
% stratificaiton condition young versus old.

%groups_to_hold is the stratification you are using (for example if you
%want to see which sex has most difference the group to hold would be the
%{sub}group# corresponding to that

logical_X_finder=reg_match(Data.Properties.VariableNames,'^(X)');
logical_vertex_finder=reg_match(Data.Properties.VariableNames,'^([Vv]ertex)');
positional_vertex_finder=find(logical_vertex_finder);

if ~isempty(positional_vertex_finder)
    name_vertex_finder=Data.Properties.VariableNames{positional_vertex_finder};
end

logical_specimen_finder=reg_match(Data.Properties.VariableNames,'^(CIVM_SCAN_ID)|^(CIVM_ID)');
positional_specimen_finder=find(logical_specimen_finder);

if ~isempty(positional_specimen_finder)
    name_specimen_finder=Data.Properties.VariableNames{positional_specimen_finder};
end

if sum(logical_specimen_finder)>0
   [specimen,~,specimen_idx]=unique(Data.(name_specimen_finder),'stable'); 

   logical_group_finder=reg_match(Data.Properties.VariableNames,'^Group');
   positional_group_finder=find(logical_group_finder);
   logical_subgroup_finder=reg_match(Data.Properties.VariableNames,'^Subgroup');
   positional_subgroup_finder=find(logical_subgroup_finder);

   for n=1:height(specimen)
       for m=1:sum(logical_group_finder)
           temp=Data.(positional_group_finder(m));
           group_name{n,m}=temp{n};
       end
       for m=1:sum(logical_subgroup_finder)
           temp=Data.(positional_subgroup_finder(m));
           subgroup_name{n,m}=temp{n};
       end
   end
end

if sum(logical_vertex_finder)>0
    [vertex,~,vertex_idx]=unique(Data.(name_vertex_finder));
    data_height=sum(vertex_idx==1);
else
    vertex=1;
    data_height=height(Data);
    vertex_idx=ones(data_height,1);
end

for n=1:sum(logical_X_finder)
    s_X(n)=std(Data.(strcat('X',num2str(n))));
end

output=table;
count_n=1;

%first all!

for n = 1:numel(vertex)
    for m = 1:sum(logical_X_finder)
        coordinate=vertex_idx==n;

        if numel(specimen)~=1
            output.specimen{count_n}=specimen;
            output.group{count_n}=group_name;
            output.subgroup{count_n}=subgroup_name;
        end
        if numel(vertex)~=1
            output.vertex(count_n)=vertex(n);
        end

        % Raw Difference Between for each coordinate
        output.(strcat('raw_difference_X',num2str(m))){count_n}=Data.(strcat('X',num2str(m)))(coordinate).*ones(data_height,data_height)-transpose(Data.(strcat('X',num2str(m)))(coordinate).*ones(data_height,data_height));
        % Scaled Difference Between each coordinate
        output.(strcat('scaled_difference_X',num2str(m))){count_n}=(Data.(strcat('X',num2str(m)))(coordinate)./s_X(m)).*ones(data_height,data_height)-transpose((Data.(strcat('X',num2str(m)))(coordinate)./s_X(m)).*ones(data_height,data_height));
    end
    count_n=count_n+1;
end

%Now adjust to the output file to select data for the vertex comparision
%and get the final distance out.
logical_vertex_finder=reg_match(output.Properties.VariableNames,'^([Vv]ertex)');
positional_vertex_finder=find(logical_vertex_finder);

if ~isempty(positional_vertex_finder)
    name_vertex_finder=output.Properties.VariableNames{positional_vertex_finder};
end

if sum(logical_vertex_finder)>0
    [vertex,~,vertex_idx]=unique(output.(name_vertex_finder));
else
    vertex=1;
    data_height=height(output); % This isn't going to be the same as the input height as the comparsion needs to be across what is held/compared.
    vertex_idx=ones(data_height,1);
    data_height=size(output.(1){:});
end

for n = 1:numel(vertex)
    temp_diff_raw=zeros(data_height);
    temp_diff_scaled=zeros(data_height);

    for m=1:sum(logical_X_finder)
        temp_diff_raw=temp_diff_raw+output.(strcat('raw_difference_X',num2str(m))){n}.^2;
        temp_diff_scaled=temp_diff_scaled+output.(strcat('scaled_difference_X',num2str(m))){n}.^2;
    end

    output.(strcat('raw_distance')){n}=sqrt(temp_diff_raw);
    output.(strcat('scaled_distance')){n}=sqrt(temp_diff_scaled);
end

end