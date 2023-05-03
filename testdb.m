rec_i = 2
entry_lat = [sdb_ImportData.AMS.LatestData.entry_Lat(rec_i)-sdb_ImportData.AMS.LatestData.err_entry_Lat(rec_i) sdb_ImportData.AMS.LatestData.entry_Lat(rec_i) sdb_ImportData.AMS.LatestData.entry_Lat(rec_i)+sdb_ImportData.AMS.LatestData.err_entry_Lat(rec_i)]
entry_lon = [sdb_ImportData.AMS.LatestData.entry_Long(rec_i)-sdb_ImportData.AMS.LatestData.err_entry_Long(rec_i) sdb_ImportData.AMS.LatestData.entry_Long(rec_i) sdb_ImportData.AMS.LatestData.entry_Long(rec_i)+sdb_ImportData.AMS.LatestData.err_entry_Long(rec_i)]
end_lat = [sdb_ImportData.AMS.LatestData.end_Lat(rec_i)-sdb_ImportData.AMS.LatestData.err_end_Lat(rec_i) sdb_ImportData.AMS.LatestData.end_Lat(rec_i) sdb_ImportData.AMS.LatestData.end_Lat(rec_i)+sdb_ImportData.AMS.LatestData.err_end_Lat(rec_i)]
end_lon = [sdb_ImportData.AMS.LatestData.end_Long(rec_i)-sdb_ImportData.AMS.LatestData.err_end_Long(rec_i) sdb_ImportData.AMS.LatestData.end_Long(rec_i) sdb_ImportData.AMS.LatestData.end_Long(rec_i)+sdb_ImportData.AMS.LatestData.err_end_Long(rec_i)]
gx = geoaxes;
hold on
geoscatter(entry_lat,entry_lon,'b','filled')
geoscatter(end_lat,end_lon,'y','filled')