function [colors, color_names] = lookup_colors_generate(steps, steps_per_color, neutrals, flip_colors, varargin)
%function [colors, color_names] = lookup_colors_generate(steps, steps_per_color, neutrals, flip_colors, COLORS)
% 
% Generates interpolated colors tranitioning from one to the next.
% COLORS are either names, or rgb codes. 
% 
% For a two-tone color map with white in the middle, use COLOR1, White, COLOR2
% 
% The only tested combination is Cyan,White,Magenta.
% 
% steps are either the total number of steps, or the number of steps
% between colors when steps_per_color boolean is specified. 
%
% give lookup colors for N steps and optional neutral(s) for our two-tone
% lookup table. Expected usage is low to high, If requested can be returned
% in reverse.
%
% steps does not include neutral colors.
% 
% output have size (steps + neutrals x (nColors - 1) ) x 3
% or (steps + neutrals x (nColors - 1) ) x 3

    function is_odd=isodd(val)
        is_odd=mod(val,2);
    end
    function is_even=iseven(val)
        % using modulus operator test for val is even
        is_even=~isodd(val);
        return
    end

assert(iseven(steps),'I only understand the idea of symmetric color tables. Must have an even number of steps.' );
assert(steps<127,'Only supports 255 levels total(assuming single neutral), specify less than 127 steps.')

if ~exist('flip','var')
    flip_colors=false;
end

if ~exist('neutrals','var')
    neutrals=1;
end
if isempty(varargin)
    color_selection={'Cyan','White','Magenta'};
else
    color_selection=varargin;
end

mode='two-tone';
assert(numel(color_selection)==3,'Require 3 input colors to genreate a ramp to mid and ramp out of mid.');

% what are we using for our neutral color in the middle.
n_val=232;
supported_colors=struct(...
    'Black', [15,15,15],...
    'White', [250,250,250],...
    'neutral', [n_val,n_val,n_val],...
    'Magenta', [212,17,89], ...
    'Cyan', [26,133,255],...
    'Red', [255, 0, 0 ],...
    'Green', [0, 255, 0],...
    'Blue', [0, 0, 255],...
    'Yellow', [255, 255, 0],...
    'Teal', [0, 255, 255],... % full-cyan?
    'Purple', [255, 0, 255]...
    );
S=supported_colors;

if ~steps_per_color
    sz_side=round(steps/(numel(color_selection)-1));
else
    sz_side=steps;
end
% this formula for any N colors is incorrect. Sticking with two-tone for
% now(which is 3 input colors.)
% n_colors=sz_side*(numel(color_selection)-1)+numel(color_selection)-1-1;
n_colors=steps;
colors=zeros(n_colors,3);
color_names=cell(n_colors,1);
i_start=1;
i_stop=sz_side+1;
for i_s=1:numel(color_selection)-1

    clr1=color_selection{i_s};
    clr2=color_selection{i_s+1};

    Color=colorspace(S.(clr1), S.(clr2), sz_side+1);
    if i_s==1
        Color(end,:)=[];
        i_stop=height(Color);
    elseif strcmp(mode,'two-tone')
        Color(1,:)=[];
        i_stop=i_stop+height(Color);
    else
        i_stop=i_stop+height(Color);
    end
    if strcmp(mode,'two-tone')
        nums=sz_side:-1:1;
        if i_s==1
            pat=sprintf('%s%%i ',clr1);
            %offset=0;
        else
            pat=sprintf('%s%%i ',clr2);
            nums=reverse(nums);
            %offset=1;
        end
        %color_names(offset+i_start:i_stop)=list2cell(sprintf(pat, nums)) ;
        color_names(i_start:i_stop)=list2cell(sprintf(pat, nums));
    end

    colors( (i_start:i_stop),:)=Color;
    i_start=i_start+i_stop;
end


%{
% Magenta side:
Magenta=colorspace(S.White,S.Magenta,sz_side+1);
Magenta(1,:)=[];

% Cyan Side:
Cyan=colorspace(S.Cyan,S.White,sz_side+1);
Cyan(end,:)=[];

% composite low->neutral->high
% (repmat will give a 0x3 when neutrals is off)
colors=[S.Cyan;repmat(S.neutral,[neutrals,1]);S.Magenta];
if nargout==2
    color_names=[ ...
        list2cell(sprintf('Cyan%i ', sz_side:-1:1)), ...
        repmat({'neutral'}, [1,neutrals]), ...
        list2cell(sprintf('Magenta%i ', 1:sz_side)) ...
        ]';
end

%}
% composite low->neutral->high
% (repmat will give a 0x3 when neutrals is off)

if strcmp(mode,'two-tone') 
    colors=[colors(1:sz_side,:);repmat(S.neutral,[neutrals,1]);colors(end-sz_side+1:end,:)];
    color_names=[color_names(1:sz_side); repmat({'neutral'},[neutrals,1]); color_names(end-sz_side+1:end)];
end

if flip_colors
    colors=flip(colors,1);
    if nargout==2
        color_names=flip(color_names);
    end
end

end