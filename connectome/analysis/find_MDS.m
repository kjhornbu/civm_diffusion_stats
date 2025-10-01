function [mds,eigen_fraction] = find_MDS(Dist)

if length(size(Dist))==2
    [~,eigen_total] = cmdscale(Dist);
    [temp_mds,temp_eigen] = cmdscale(Dist,2);%Force 2D embedding This matches JHU

    try
        if size(temp_mds,2)>1
            mds=temp_mds;
            eigen_fraction=temp_eigen./sum(eigen_total(eigen_total>0));
        else
            mds=[temp_mds zeros(size(temp_mds))];
            eigen_fraction=[temp_eigen 0]./sum(eigen_total(eigen_total>0));
        end
    catch
        mds=zeros(size(Dist,1),2);
        eigen_fraction=[0,0];
    end
else
    keyboard;
end

end