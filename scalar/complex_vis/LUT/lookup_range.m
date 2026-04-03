function lut_range = lookup_range(varargin)
% function lut_range = lookup_range(desired_steps[,neutrals],PARAMS)
% generates a range of nubers using special constraints for our lookup
% table creation.
%
% desired_steps  - the number of non-neutral steps we want.
%
% neutrals  - the number of neutral steps(steps near 0) where we'll use a
%             netural color (see lookup_colors_dual_change).
% 
% PARAMS are name and value pairs (string and value) 
% min, max, step_size, directionality, neutrals_are_steps are supported. 
% Others are an error.
% require either min and max, OR step size. 
%
% when min/max are omited will simply increment by step_size up to N desired steps.
%
% directionality is one of 'double' (menaing + and - values), 'positive', or
% 'negative', 'double' is default. 
% directionality=='double' is the default, where we'll have a  0-centered
% range of N desired steps.
%
% 'neutrals_are_steps' changes the step-width of neutrals, when passed a true
% value neutrals will share step size with the rest of the data. When
% false(or not specified) they will use 1/2 of the first step. (First step
% is step closest to 0.)
%

p = inputParser;

% === Positional arguments ===
addRequired(p, 'desired_steps', @(x) isscalar(x) && isnumeric(x) && x >= 0 && x <= 255 && mod(x,1)==0); %forcing to a literal interger value
%addOptional(p, 'neutrals', 0,  @(x) isscalar(x) && ismember(x, [0, 1, 2]));

% Add parameters
addParameter(p, 'min', [], @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'neutral', [], @(x) isnumeric(x) && numel(x) == 2 );
addParameter(p, 'max', [], @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'step_size', [], @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'directionality', 'double', @(x) ( ischar(x) || isstring(x) ) && reg_match(x,'negative|double|positive') );

% addParameter(p, 'neutrals_are_steps', false,  @(x) isscalar(x) && ismember(x, [false, true]));

%%% todo add, neutral width, or neutral bounds to go with max/min+n_step

% Parse input
parse(p, varargin{:});

params=p.Results; 

float_step =  isempty(params.step_size) && ~isempty(params.min) && ~isempty(params.max);
force_step = ~isempty(params.step_size) &&  isempty(params.min) &&  isempty(params.max);
% could expand this logic in the future to support lopsided ranges. 
% in particular, one-sided ranges would want a min+stepsize, OR a
% max+stepsize(we'd subtract step size to get down to min)
assert(force_step||float_step,'either specifiy both min and max but NOT step_size, OR only specify step_size');

%  for right now, only two sided.
assert(strcmp(params.directionality,'double'),'only double sided direction implemented');

switch params.directionality
    case 'negative'
        step_div=1;
        if isempty(params.max)
            params.max=0;
        end
    case 'double'
        step_div=2;

        calc_steps=params.desired_steps/step_div;
        step_sz_div=calc_steps;
        %{
        if params.neutrals_are_steps
            step_sz_div=calc_steps + 0.5 * params.neutrals;
        end
        %}
        % account for neutrals
        neutral_offset=0;
        if ~isempty(params.neutral)
            neutral_offset=params.neutral(2);
            
            if isempty(params.max)
                params.max = params.step_size * step_sz_div + neutral_offset;  
            end
            p_max = params.max - neutral_offset;
            params.step_size=p_max/step_sz_div;
            params.step_size=round_nice(params.step_size);
        end
        if isempty(params.step_size)
            params.step_size=params.max/step_sz_div;
            % round to nice number
            params.step_size=round_nice(params.step_size);
        end
        if isempty(params.max)
            params.max = params.step_size * step_sz_div + neutral_offset;
        end
        if isempty(params.min)
            params.min = - params.step_size * step_sz_div - neutral_offset;
        end

        st=neutral_offset;
        pos = st : params.step_size : params.max + 0.99*params.step_size;
        neg = - reverse( pos );
        if neutral_offset ~=0
            lut_range=[neg, 0, pos];
        else
            lut_range=[neg, pos];
        end

        %{
        if params.neutrals_are_steps
            % neutrals share step size with the other steps
            
            st=0;
            st_idx=2;
            if params.neutrals == 1
                st=params.step_size/2;
                st_idx=1;
            end
            pos = st : params.step_size : params.max + 0.99*params.step_size;
            neg = - reverse( pos(st_idx:end) );
            lut_range=[neg,pos];
        else
            
            % neutrals carve themselves out of the first bucket(take 1/2 of it).
            entries = params.desired_steps+1;
            lin_range=linspace(params.min, params.max, entries);

            zero_pos = find(lin_range == 0);
            add_neutral=lin_range(zero_pos+1)/2;
            
            if numel(add_neutral) && params.neutrals== 2
                lut_range=[lin_range(1:zero_pos-1) -add_neutral 0 +add_neutral lin_range(zero_pos+1:end)];
            elseif numel(add_neutral) && params.neutrals== 1
                lut_range=[lin_range(1:zero_pos-1) -add_neutral +add_neutral lin_range(zero_pos+1:end)];
            else
            
                lut_range=lin_range;
            end
        end
        %}
    case 'positive'
        step_div=1;
        if isempty(params.min)
            params.min=0;
        end
    otherwise
        % unused due to earlier protections.
end


%{
% aging study recommended cohenF == 0.3
% converting to cohenD = 2 * cohenF
% we have both F and D calculated, could use the calculated D to get
% more precise multiplication.
if reg_match(type,'percent_change')
    add_neutral=0.01;
    data_max=0.1;
elseif reg_match(type,'cohenD')
    % NOT convinced that cohenD should share pct change color map!
    add_neutral=1;
    data_max=2;
end

lin_colors=size(Color,1)+1-neutral_count;
lin_range=linspace(-data_max, data_max, lin_colors);

zero_pos = find(lin_range == 0);
if neutral_count == 2
    color_range=[lin_range(1:zero_pos-1) -add_neutral 0 +add_neutral lin_range(zero_pos+1:end)];
elseif neutral_count == 1
    color_range=[lin_range(1:zero_pos-1) -add_neutral +add_neutral lin_range(zero_pos+1:end)];
else
    color_range=lin_range;%[lin_range(1:zero_pos-1) 0 lin_range(zero_pos+1:end)];
end
color_range(1)=-inf;
color_range(end)=inf;
%}



       