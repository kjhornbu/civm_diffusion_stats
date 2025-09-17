function [matrix] = binary_interaction_generator(test_grouping,type)

% from 1..((2^(nGroupColumns))-)
output_means_to_generate=(2^(numel(test_grouping)))-1;

matrix=zeros(output_means_to_generate,numel(test_grouping));

% For each test grouping iterate and add to the list
for n=1:output_means_to_generate
    character_array=dec2bin(n,numel(test_grouping));
    logical_array=logical(character_array-'0');
    matrix(n,:)=double(logical_array);
end

interactions=sum(matrix,2);

switch type
    case 'no_interaction'
        matrix(interactions>1)=[];
    case 'pairwise'
        matrix(interactions>2)=[];
end


end