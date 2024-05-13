function [LAT,LONG,slantRange] = vectorsolution(AZ, ELEV, LAT0, LONG0, H0, H_target, ELLIPSOID, eventfolder)
% VECTORSOLUTION Sweep a solution set for a single array input to
% AER2GEOSOLVE

logformat('currently this function only supports H_target array input','WARN')

for idx = 1:numel(H_target)
    [LAT(idx),LONG(idx),slantRange(idx)] = aer2geosolve(AZ,ELEV,LAT0, LONG0, H0, H_target(idx), ELLIPSOID);
end

labels = arrayfun(@num2str, H_target./1000, 'UniformOutput', 0);
labels = strcat(labels,'km')
exportpins(eventfolder,'VectorSolution','VectorSolution',LAT,LONG,H_target,labels)