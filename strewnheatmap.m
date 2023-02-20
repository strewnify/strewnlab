numbins = 300;
hist_x = strewn_data(:,12);
hist_y = strewn_data(:,13);
[N,Xedges,Yedges] = histcounts2(hist_x,hist_y,numbins);
figure(6)
heatmap(Xedges(1:numbins),Yedges(1:numbins),N)
grid off