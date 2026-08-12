function [] = top10ScalarYAxis(Current_Fig,Contrast,low_bound,top_bound)
%Sets the Y axis of the top 10 plots in the scalar plotting cleanup

x_axis_temp=xlim;

set(Current_Fig.CurrentAxes,'fontsize',8,'fontname','Arial');

if (strcmp(Contrast,'volume_mm3') || strcmp(Contrast,'volume_mm3_total_automated_vol')|| strcmp(Contrast,'voxels'))==1
    reduce_contrast=strsplit(Contrast,{'volume_mm3_','_vol'});
    reduce_contrast_idx=~cellfun(@isempty,reduce_contrast);

    if low_bound>= 0
        set(Current_Fig.CurrentAxes,'YScale','log');

        if strcmp(Contrast,'voxels')
            ylabel(Current_Fig.CurrentAxes,strcat('log(Regional Voxel Count)'));
        elseif strcmp(Contrast,'volume_mm3')
            ylabel(Current_Fig.CurrentAxes,strcat('log(Regional Absolute Volume) (mm^3)'));
        else
            ylabel(Current_Fig.CurrentAxes,strcat('log(',reduce_contrast(reduce_contrast_idx),' volume) (mm^3)'));
        end
    else
        if strcmp(Contrast,'voxels')
            ylabel(Current_Fig.CurrentAxes,strcat('Z-Score of Regional Voxel Count'));
        elseif strcmp(Contrast,'volume_mm3')
            ylabel(Current_Fig.CurrentAxes,strcat('Z-Score of Regional Absolute Volume'));
        else
            ylabel(Current_Fig.CurrentAxes,strcat('Z-Score of',32,reduce_contrast(reduce_contrast_idx),' volume'));
        end
    end
elseif strcmp(Contrast,'volume_fraction')==1
    if low_bound>= 0
        set(Current_Fig.CurrentAxes,'YScale','log');
        ylabel(Current_Fig.CurrentAxes,strcat('log(Fractional Volume) (% of Total Brain Volume)'));
    else
        ylabel(Current_Fig.CurrentAxes,strcat('Z-Score of Fraction of Total Brain Volume'));
    end
elseif (reg_match(Contrast,'^(fa|nqa|gfa)(_.*)?$'))==1
    if low_bound>= 0
        ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (-)'));
        low_bound=0;
        top_bound=1;
    else
        ylabel(Current_Fig.CurrentAxes,strcat('Z-score of',32,strrep(Contrast,'_','-')));
    end
elseif  (reg_match(Contrast,'^(ad|rd|md)(_.*)?$'))==1
    if low_bound>=0
        ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (mm^{2}/s)'));
    else
        ylabel(Current_Fig.CurrentAxes,strcat('Z-score of',32,strrep(Contrast,'_','-')));
    end
elseif (reg_match(Contrast,'^(dwi|qa|iso)(_.*)?$'))==1
    if low_bound>=0
        ylabel(Current_Fig.CurrentAxes,strcat(strrep(Contrast,'_','-'),' (-)'));
    else
        ylabel(Current_Fig.CurrentAxes,strcat('Z-score of',32,strrep(Contrast,'_','-')));
    end
end

axis(Current_Fig.CurrentAxes,[x_axis_temp(1) x_axis_temp(2) low_bound top_bound])
end