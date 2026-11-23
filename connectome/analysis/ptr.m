function [graph] = ptr(graph)
non_zeros=graph(graph~=0);
rank=tiedrank(non_zeros);
normalizer=size(rank,1);
rank=2*rank/(normalizer); %removed +1 because matlab doesn't do 0 indexing
graph(graph~=0)=rank;
end