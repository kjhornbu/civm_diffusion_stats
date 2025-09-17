function [slidedata] = summary_slide_setup(ppt,name,compare_image)

import mlreportgen.ppt.*;

slidedata = add(ppt,"Two Content");
replace(slidedata,"Title",strcat('Summary:',{' '},name));

for n=1:numel(compare_image)
    picture = Picture(compare_image{n});

    if n==1
        replace(slidedata,"Left Content",picture);
    elseif n==2
        replace(slidedata,"Right Content",picture);
    end

end

end