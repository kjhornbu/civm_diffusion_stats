function generateHtmlPages(files)
%% create html files
% files.html_out
% save('testing_debug');
% load('testing_debug');
for htm=files.html_out.keys()
    htm=uncell(htm);
    html_conf=files.html_out(htm);
    
    if strcmp(html_conf.type,'slice')
        %success=write_slice_htm(out_htm, headings, slices, colorbar)
        headings=struct('h3',html_conf.stratification, ...
            'h4',sprintf('%s %s',html_conf.contrast, html_conf.column_variant) );
        if not( file_time_check(html_conf.output,'new',html_conf.colorbar) )
            warning('TODO multi-file time check, include code');
            write_slice_htm(html_conf.output, headings, html_conf.slices, html_conf.colorbar);
        end
    elseif strcmp(html_conf.type,'effect_distribution')
        headings=struct('h3',html_conf.stratification, ...
            'h4',sprintf('effect distribution %s', html_conf.column_name) );
        % forcing update temporarily.
        % if not( file_time_check(html_conf.output,'new',[html_conf.summary_sov,html_conf.efects]) )
            warning('TODO multi-file time check, include code');
            write_effect_dist_htm(html_conf.output, headings, html_conf.summary_sov, html_conf.effects);
        % end
    elseif strcmp(html_conf.type,'statistical_view')
        % THIS SHOULD BE DONE LAST SOMEHOW. 
        %if not( file_time_check(html_conf.output,'new', fieldnames(html_conf.out_types) ) )
            warning('TODO multi-file time check, include code');
            write_statistical_view_htm(html_conf.output, html_conf.contrasts, fieldnames(html_conf.out_types));
        %end
    else
        warning('unhandled html conf type');
        keyboard;

    end

end

end