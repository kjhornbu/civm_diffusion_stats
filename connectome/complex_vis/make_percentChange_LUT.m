function [LUT,plot_lut] = make_percentChange_LUT(directory,difference_criteria,matrix_2_print,plot_lut)
%not the exact same as the other LUT files lol James --KH 2025-09-12

%% Making Color Range, Bounds, and Color Levels themselves
if reg_match(difference_criteria,'percent_difference')
    color_range=linspace(-0.5,0.5,11); %Percent Change
end
if reg_match(difference_criteria,'cohenD_difference')
    color_range=[-1.5,linspace(-1.4,-0.5,4),0,linspace(0.5,1.4,4),1.5]; %CohenD
    %linspace(-4,4,11)
end

color_bounds=[color_range(1:end-1);color_range(2:end)];

if reg_match(difference_criteria,'percent_difference')
    %% Blue -, Red + form
    %Cyan Side:
    Color(:,1)=linspace(26,250,round(numel(color_range)/2));
    Color(:,2)=linspace(133,250,round(numel(color_range)/2));
    Color(:,3)=linspace(255,250,round(numel(color_range)/2));

    %Magenta side:
    Color2(:,1)=linspace(250,212,round(numel(color_range)/2));
    Color2(:,2)=linspace(250,17,round(numel(color_range)/2));
    Color2(:,3)=linspace(250,89,round(numel(color_range)/2));

    length_color=size(Color,1)-1;

    Color(length_color+(1:(size(Color2,1)-1)),1)=Color2(2:end,1);
    Color(length_color+(1:(size(Color2,1)-1)),2)=Color2(2:end,2);
    Color(length_color+(1:(size(Color2,1)-1)),3)=Color2(2:end,3);
elseif reg_match(difference_criteria,'cohenD_difference')
    Color(:,1)=linspace(26,250,round((numel(color_range)-1)/2));
    Color(:,2)=linspace(133,250,round((numel(color_range)-1)/2));
    Color(:,3)=linspace(255,250,round((numel(color_range)-1)/2));

    %Magenta side:
    Color2(:,1)=linspace(250,212,round((numel(color_range)-1)/2));
    Color2(:,2)=linspace(250,17,round((numel(color_range)-1)/2));
    Color2(:,3)=linspace(250,89,round((numel(color_range)-1)/2));

    length_color=size(Color,1);

    Color(length_color+(1:(size(Color2,1))),1)=Color2(1:end,1);
    Color(length_color+(1:(size(Color2,1))),2)=Color2(1:end,2);
    Color(length_color+(1:(size(Color2,1))),3)=Color2(1:end,3);
end

%% Setting the colors into a structure with fields
rgbf={'r','g','b'};

for n=1:height(Color)
    colorlvl{n,1}=num2cell(Color(n,:)./255);
end

st_args=[rgbf;{nan,nan,nan}];
colors(numel(colorlvl))=struct(st_args{:});
for gn=numel(colorlvl):-1:1
    st_args=[rgbf;colorlvl{gn}];
    colors(gn)=struct(st_args{:});
end

%% Using cost function to assign colors to entries
for n=1:size(matrix_2_print,1)
    for m=1:size(matrix_2_print,2)
        data=matrix_2_print(n,m);
        if ~(isnan(data))
            if data>=color_range(end)
                bin_postional_idx=size(color_bounds,2);
            elseif data<=color_range(1)
                bin_postional_idx=1;
            else
                bin_logical_idx=and(data>=color_bounds(1,:),data<=color_bounds(2,:));
                bin_postional_idx=find(bin_logical_idx==1);
            end

            if  data == 0
                LUT.c_r(n,m) = 250/255;
                LUT.c_g(n,m) = 250/255;
                LUT.c_b(n,m) = 250/255;
                LUT.c_a(n,m) = 1;
            else
                LUT.c_r(n,m) = colors(bin_postional_idx).r;
                LUT.c_g(n,m) = colors(bin_postional_idx).g;
                LUT.c_b(n,m) = colors(bin_postional_idx).b;
                LUT.c_a(n,m) = 1;
            end
        end
    end
end

%% Plot colormap to output
if plot_lut == 1
    fig_colormap=figure;
    set(gca,'FontSize',8,'FontName','Arial');
    set(gcf,'PaperUnits', 'inches','PaperPosition',[0 0 2 15],'Units','inches','InnerPosition',[0 0 2 10.4895833333333]);

    hold on

    for n=1:numel(colors)
        rectangle('Position',[0 n 1 1],'FaceColor',[colors(n).r,colors(n).g,colors(n).b],'EdgeColor',[colors(n).r,colors(n).g,colors(n).b]);
    end

    axis([0 1 size(color_range)])

    xticks(linspace(0,1,2))
    xticklabels(repmat('',2,1))

    yticks(linspace(1,size(color_range,2),size(color_range,2)))
    yticklabels(color_range)

    print(fig_colormap, fullfile(directory,'LUT_ColorMap.png'),'-dpng','-r600');
    print(fig_colormap, fullfile(directory,'LUT_ColorMap.svg'),'-dsvg','-vector');

    plot_lut = false;
end

end