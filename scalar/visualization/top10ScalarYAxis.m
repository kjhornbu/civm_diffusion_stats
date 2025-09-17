function [] = top10ScalarYAxis(Current_Fig,Contrast,low_bound,top_bound)
%Sets the Y axis of the top 10 plots in the scalar plotting cleanup

x_axis_temp=xlim;

set(Current_Fig.CurrentAxes,'fontsize',8,'fontname','Arial');

if (strcmp(Contrast,'volume_mm3') || strcmp(Contrast,'volume_mm3_total_automated_vol')|| strcmp(Contrast,'voxels'))==1
    reduce_contrast=strsplit(Contrast,{'volume_mm3_','_vol'});
    reduce_contrast_idx=~cellfun(@isempty,reduce_contrast);

    set(Current_Fig.CurrentAxes,'YScale','log');

    if strcmp(Contrast,'voxels')
        ylabel(Current_Fig.CurrentAxes,strcat('log(Regional Voxel Count)'));
    elseif strcmp(Contrast,'volume_mm3')
        ylabel(Current_Fig.CurrentAxes,strcat('log(Regional Absolute Volume) (mm^3)'));
    else
        ylabel(Current_Fig.CurrentAxes,strcat('log(',reduce_contrast(reduce_contrast_idx),' volume) (mm^3)'));
    end

elseif strcmp(Contrast,'volume_fraction')==1
    set(Current_Fig.CurrentAxes,'YScale','log');
    ylabel(Current_Fig.CurrentAxes,strcat('log(Fractional Volume) (% of Total Brain Volume)'));
elseif (reg_match(Contrast,'^(fa|nqa|gfa)(_.*)?$'))==1
    ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (-)'));
    low_bound=0;
    top_bound=1;
elseif  (reg_match(Contrast,'^(ad|rd|md)(_.*)?$'))==1
    ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (mm^{2}/s)'));
elseif (reg_match(Contrast,'^(dwi|qa|iso)(_.*)?$'))==1
    ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (-)'));
end

axis(Current_Fig.CurrentAxes,[x_axis_temp(1) x_axis_temp(2) low_bound top_bound])

end