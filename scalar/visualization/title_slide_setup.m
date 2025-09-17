function [slidedata] = title_slide_setup(ppt,ppt_identity,user)

import mlreportgen.ppt.*;

title=strjoin( ppt_identity,' ');
slidedata = add(ppt,"Title Slide");
replace(slidedata,"Title",title);
replace(slidedata,"Subtitle",[user,date]);

end