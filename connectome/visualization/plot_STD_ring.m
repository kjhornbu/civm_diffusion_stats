function [] = plot_STD_ring(x,y,x_std,y_std,color)
theta=0:0.01:2*pi;

plot(x+(x_std*cos(theta)),y+(y_std*sin(theta)),'--','Color',color);

end