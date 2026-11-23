function [graph] = diag_aug(graph)
row_sum=sum(graph,2);
diagonal=row_sum/(size(graph,1)-1);

    for n=1:size(graph,1)
        graph(n,n)=diagonal(n,1);
    end
end