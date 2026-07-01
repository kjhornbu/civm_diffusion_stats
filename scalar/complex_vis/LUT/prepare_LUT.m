function [stat_colors,bar_plot_opts] = prepare_LUT(change_data_type,LUT_type, i_column,out_lut_tbl)

%% Get LUT for plotting
clear stat_colors; % to prevent accidental re-use of wrong colors.
if reg_match(LUT_type{i_column}{1},'pvalue')
    stat_colors=lookup_pvalue(LUT_type{i_column}{1});
    bar_plot_opts={'proportional',false};
elseif reg_match(LUT_type{i_column}{1},'^(singleside_cohen)$')
    stat_colors=lookup_cohen(LUT_type{i_column}{1});
    bar_plot_opts={'proportional',false};
elseif reg_match(LUT_type{i_column}{1},change_data_type)
    % todo: check lut_type params for neutral, when it exists we
    % have 2.
    neutral_count=0;
    if reg_match(cell2str(LUT_type{i_column}),'neutral')
        neutral_count=2;
    end
    % look for special keyword indicating proscribed range
    % instead of auto-calc
    idx_range=cellfun(@(x) ischar(x) && strcmp(x,'color_range'),LUT_type{i_column});
    idx_names=cellfun(@(x) ischar(x) && strcmp(x,'color_names'),LUT_type{i_column});
    if any( idx_range )
        color_range=LUT_type{i_column}{find(idx_range)+1};
        color_names=LUT_type{i_column}{find(idx_names)+1};
        % force tall not wide, in case our input is backwards.
        color_names=reshape(color_names,numel(color_names),1);
        Color = lookup_colors_generate(numel(color_range)-neutral_count-1, false, neutral_count, false);
    else
        desired_steps=10;
        %color_range=lookup_range(desired_steps,neutral_count,'step_size',step_size,'neutrals_are_steps',i_tx);
        color_range=lookup_range(desired_steps,LUT_type{i_column}{2:end});
        [Color, color_names]=lookup_colors_generate(numel(color_range)-neutral_count-1, false, neutral_count, false);
    end
    stat_colors=lookup_colors_apply_values(Color,color_range,color_names);

    bar_plot_opts={};
else
    warning('ERROR lut type not recognized.')
    keyboard
end


if ~exist(out_lut_tbl,'file')
    civm_write_table(stat_colors,out_lut_tbl,false,true,{},'quiet');
end

end