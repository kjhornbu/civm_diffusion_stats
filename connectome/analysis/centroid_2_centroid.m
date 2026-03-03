function [output,s_X] = centroid_2_centroid(Data,groups_to_compare,groups_to_hold,varargin)
% groups to compare is the study condition you want to compare centroid to
% centroid distance over (for example in 18gaj42 we are comparing old
% versus young so this is the centroid to centroid distance of whatever
% stratificaiton condition young versus old.

%groups_to_hold is the stratification you are using (for example if you
%want to see which sex has most difference the group to hold would be the
%{sub}group# corresponding to that

if ~isempty(varargin)
    compare_setting=varargin{1};
end

logical_X_finder=reg_match(Data.Properties.VariableNames,'^(X)');
logical_vertex_finder=reg_match(Data.Properties.VariableNames,'^([Vv]ertex)');
positional_vertex_finder=find(logical_vertex_finder);

if ~isempty(positional_vertex_finder)
    name_vertex_finder=Data.Properties.VariableNames{positional_vertex_finder};
end

if sum(logical_vertex_finder)>0
    [vertex,~,vertex_idx]=unique(Data.(name_vertex_finder));
    data_height=sum(vertex_idx==1);
else
    vertex=1;
    data_height=height(Data);
    vertex_idx=ones(data_height,1);
end

% for n=1:sum(logical_X_finder)
%     s_X(n)=std(Data.(strcat('X',num2str(n))));
% end

[~,group_name_hold,group_name_idx_hold] = find_group_information_from_groupingcriteria(Data,groups_to_hold);
[~,group_name_compare,group_name_idx_compare] = find_group_information_from_groupingcriteria(Data,groups_to_compare);

if numel(group_name_compare)>2 && ~exist('compare_setting','var')
    error('We cannot measure centroid to centroid when we have more than 2 delineations for the compare group(s) across the hold condition(s) and no information of how to use those delineations.');
else
    groups_to_hold_idx=group_name_idx_hold==1:numel(group_name_hold)';
    %groups_to_compare_idx=group_name_idx_compare==1:numel(group_name_compare)';
end

%in the case that we have many compare groups to use we only want to look
%at key groupings. 
if exist('compare_setting','var')
    count_n=1;
    for n=1:numel(compare_setting)
        basis(:,n)=reg_match(group_name_compare,compare_setting{n}{1});
        varying(:,n)=reg_match(group_name_compare,compare_setting{n}{2});

        groups_idx(:,count_n)=sum(group_name_idx_compare==find(basis(:,n))',2)>0;
        count_n=count_n+1;
        groups_idx(:,count_n)=sum(group_name_idx_compare==find(varying(:,n))',2)>0;
        count_n=count_n+1;
    end

    group_name_compare=horzcat(compare_setting{:});
    
else
    %In a two group system you just have the two groups to define.
    basis(:,1)=[1 0];
    varying(:,1)=[0,1];

    compare_setting{1}{1}=group_name_compare{1};
    compare_setting{1}{2}=group_name_compare{2};

    groups_idx(:,1)=sum(group_name_idx_compare==find(basis(:,1))',2)>0;
    groups_idx(:,2)=sum(group_name_idx_compare==find(varying(:,1))',2)>0;
end

output=table;
count_n=1;

%first all!
for p=1:width(groups_idx)
    for n = 1:numel(vertex)
        for m = 1:sum(logical_X_finder)
            s_X(m,n)=std(Data.(strcat('X',num2str(m)))(vertex_idx==n));

            coordinate=and(vertex_idx==n,groups_idx(:,p));
            coordinate_positional=find(coordinate);
            temp_data=Data.(strcat('X',num2str(m)))(coordinate);

            output.hold(count_n)={'All'};
            output.compare(count_n)=group_name_compare(p);
            output.GroupCount(count_n)=numel(coordinate_positional);
            if numel(vertex)~=1
                output.vertex(count_n)=vertex(n);
            end


            output.(strcat('raw_X',num2str(m),'_mean'))(count_n)=mean(temp_data,'omitnan');
            output.(strcat('raw_X',num2str(m),'_std'))(count_n)=std(temp_data,'omitnan');

            output.(strcat('Scaling_Term_X',num2str(m)))(count_n)=s_X(m,n);

            output.(strcat('scaled_X',num2str(m),'_mean'))(count_n)=mean(temp_data./s_X(m,n),'omitnan');
            output.(strcat('scaled_X',num2str(m),'_std'))(count_n)=std(temp_data./s_X(m,n),'omitnan');
        end
        count_n=count_n+1;
    end
end

for o=1:width(groups_to_hold_idx)
    for p=1:width(groups_idx)
        for n = 1:numel(vertex)
            for m = 1:sum(logical_X_finder)
                coordinate=and(and(groups_to_hold_idx(:,o),vertex_idx==n),groups_idx(:,p));
                coordinate_positional=find(coordinate);
                temp_data=Data.(strcat('X',num2str(m)))(coordinate);

                output.hold(count_n)=group_name_hold(o);
                output.compare(count_n)=group_name_compare(p);
                output.GroupCount(count_n)=numel(coordinate_positional);
                if numel(vertex)~=1
                    output.vertex(count_n)=vertex(n);
                end

                output.(strcat('raw_X',num2str(m),'_mean'))(count_n)=mean(temp_data,'omitnan');
                output.(strcat('raw_X',num2str(m),'_std'))(count_n)=std(temp_data,'omitnan');

                output.(strcat('Scaling_Term_X',num2str(m)))(count_n)=s_X(m,n);

                output.(strcat('scaled_X',num2str(m),'_mean'))(count_n)=mean(temp_data./s_X(m,n),'omitnan');
                output.(strcat('scaled_X',num2str(m),'_std'))(count_n)=std(temp_data./s_X(m,n),'omitnan');
            end
            count_n=count_n+1;
        end
    end
end

%Now adjust to the output file to select data for the vertex comparision
logical_vertex_finder=reg_match(output.Properties.VariableNames,'^([Vv]ertex)');
positional_vertex_finder=find(logical_vertex_finder);

if ~isempty(positional_vertex_finder)
    name_vertex_finder=output.Properties.VariableNames{positional_vertex_finder};
end

if sum(logical_vertex_finder)>0
    [vertex,~,vertex_idx]=unique(output.(name_vertex_finder));
    data_height=sum(vertex_idx==1);
else
    vertex=1;
    data_height=height(output); % This isn't going to be the same as the input height as the comparsion needs to be across what is held/compared.
    vertex_idx=ones(data_height,1);
end

%now we need to re-find for each comparision which basis versus vary exist
[value_compare,~,idx_compare]=unique(output.compare,'stable');
[value,~,idx]=unique(output.hold,'stable');

for p = 1:numel(compare_setting)
    for o = 1:numel(vertex)
        for n=1:numel(value)

            basis_idx=find(reg_match(value_compare,strcat('^(',compare_setting{p}{1},')$')));
            varying_idx=find(reg_match(value_compare,strcat('^(',compare_setting{p}{2},')$')));

            positional_coordinate(1)=find(and(and(idx==n,vertex_idx==o),idx_compare==basis_idx)); %but what if we are doing something that has not a just pairwise comparision
            positional_coordinate(2)=find(and(and(idx==n,vertex_idx==o),idx_compare==varying_idx));

            [pooled_standard_deviation] = pooled_standard_deviation_calculator(output(positional_coordinate,:),{'compare'});

            temp_diff_raw=0;
            temp_cohenD_diff_raw=0;
            temp_diff_scaled=0;
            temp_cohenD_diff_scaled=0;

            for m=1:sum(logical_X_finder)
                output.(strcat('pooled_raw_X',num2str(m),'_std'))(positional_coordinate)=pooled_standard_deviation.(strcat('raw_X',num2str(m),'_std'));
                output.(strcat('pooled_scaled_X',num2str(m),'_std'))(positional_coordinate)=pooled_standard_deviation.(strcat('scaled_X',num2str(m),'_std'));
                output.(strcat('raw_difference_X',num2str(m)))(positional_coordinate)=output.(strcat('raw_X',num2str(m),'_mean'))(positional_coordinate(2))-output.(strcat('raw_X',num2str(m),'_mean'))(positional_coordinate(1));
                output.(strcat('raw_cohenDLike_X',num2str(m)))(positional_coordinate)=output.(strcat('raw_difference_X',num2str(m)))(positional_coordinate)./pooled_standard_deviation.(strcat('raw_X',num2str(m),'_std'));
                output.(strcat('scaled_difference_X',num2str(m)))(positional_coordinate)=output.(strcat('scaled_X',num2str(m),'_mean'))(positional_coordinate(2))-output.(strcat('scaled_X',num2str(m),'_mean'))(positional_coordinate(1));
                output.(strcat('scaled_cohenDLike_X',num2str(m)))(positional_coordinate)=output.(strcat('scaled_difference_X',num2str(m)))(positional_coordinate)./pooled_standard_deviation.(strcat('scaled_X',num2str(m),'_std'));

                temp_diff_raw=temp_diff_raw+output.(strcat('raw_difference_X',num2str(m)))(positional_coordinate).^2;
                temp_cohenD_diff_raw=temp_cohenD_diff_raw+output.(strcat('raw_cohenDLike_X',num2str(m)))(positional_coordinate).^2;
                temp_diff_scaled=temp_diff_scaled+output.(strcat('scaled_difference_X',num2str(m)))(positional_coordinate).^2;
                temp_cohenD_diff_scaled=temp_cohenD_diff_scaled+output.(strcat('scaled_cohenDLike_X',num2str(m)))(positional_coordinate).^2;
            end

            output.(strcat('raw_distance'))(positional_coordinate)=sqrt(temp_diff_raw);
            output.(strcat('raw_cohenDLike_distance'))(positional_coordinate)=sqrt(temp_cohenD_diff_raw);
            output.(strcat('scaled_distance'))(positional_coordinate)=sqrt(temp_diff_scaled);
            output.(strcat('scaled_cohenDLike_distance'))(positional_coordinate)=sqrt(temp_cohenD_diff_scaled);
        end
    end
end
end