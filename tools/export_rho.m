% Export density data
altitude_data = 0:1000:80000;
density_data = density_model(altitude_data);
tb_density_data  = table(altitude_data', density_data');
tb_density_data.Properties.VariableNames{1} = 'm';
tb_density_data.Properties.VariableNames{2} = 'kg/m^3';
writetable(tb_density_data,[exportfolder '\' SimFilename '_rho_data.csv'])
%plot(density_model(0:80000))

