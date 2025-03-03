# Required libraries.
library(ncdf4)
#library("M3")
source("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/M3_functions.r")
library(fields)
library(rlang)
library(viridis)
library(lattice)
library(data.table)

# More information about ncdf package
# http://geog.uoregon.edu/bartlein/courses/geog607/Rmd/netCDF_01.htm

startplotdate <- as.Date("20171222",format="%Y%m%d")
endplotdate <- as.Date("20171223",format="%Y%m%d")

theDate <- startplotdate

#while (theDate <= endplotdate) {
	print(theDate)
	plotdate <- format(theDate,"%Y%m%d")
	print(plotdate)

base <- "v5.5_gcc"
base2 <- ""
base3 <- "v5.5_intel"

cctm.file1 <- sprintf("/work/users/l/i/lizadams/CMAQ/data/data/output_CCTM_v55_intel_STAGE_EM_2018_12US1_two_week/CCTM_ACONC_v54_intel21.4_2018_12US1_%s.nc" ,plotdate)
cctm.file2 <- sprintf("/work/users/l/i/lizadams/CMAQ/data/data/output_CCTM_v55_intel_STAGE_EM_2018_12US1_two_week/CCTM_ACONC_v55_intel_STAGE_EM_2018_12US1_two_week_%s.nc", plotdate)
inf.base <- nc_open(cctm.file1)

sens.list2 <- c("")
sens.list3 <- c("")
sens.list <- c("v5.5_intel")

#spc.list <- names(inf.base$var[-1])
spc.list <- c("ATIJ","O3","NO2")
lay.sens.list <- c("layer1_only")

for (lay.sens in lay.sens.list) {
	    # Create directories if they don't exist
    plot_dir1 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5/build_sycamore/cmaq_intel/POST/rscripts/stage_cracmm_intel21.4_intel2024.scripts/m3diffout_all_coll_row", base, lay.sens)
    if (!dir.exists(plot_dir1)) {
      dir.create(plot_dir1, recursive = TRUE)
    }
  i <- 1
  lay <- 1
  bigdat <- data.frame(base=double(), sens=double(), spc=double(), hour=double(), lay=double(), row=double(), col=double(), base_val=double(), sens_val=double(), max_diff=double(), prc_diff=double(), mean_prc_diff=double(), base_units=character(), sens_units=character(), stringsAsFactors=F)
  for (sens in sens.list) {
    sens2 <- sens.list2[which(sens.list == sens)]
    sens3 <- sens.list3[which(sens.list == sens)]
    inf.sens <- nc_open(cctm.file2)
    for (spc in spc.list) {

      spc.base <- ncvar_get(inf.base, spc)
      spc.base.units <- ncatt_get(inf.base, spc, "units")
      print(spc)
      print(spc.base.units$value)
      spc.sens <- ncvar_get(inf.sens, spc)
      #print(spc.sens)
      spc.sens.units <- ncatt_get(inf.sens, spc, "units")
      print(spc.sens.units$value)
      print(dim(spc.base))
      print(dim(spc.sens))
      # Check if the dimensions are conformable
      if (!all(dim(spc.base) == dim(spc.sens))) {
        stop("Non-conformable arrays: dimensions of spc.base and spc.sens do not match.")
      }

      spc.diff <- spc.sens - spc.base
      spc.prc <- ((abs(spc.sens - spc.base)) / ((spc.base + spc.sens) / 2)) * 100
      
#      print(spc.prc)

       for (hour in 1:24) {
        for (col in 1:100) {
	      for (row in 1:105) {

        #print(paste(lay.sens, base, sens, spc, hour, spc.prc))

        base_val <- spc.base[col, row, hour]
        sens_val <- spc.sens[col, row, hour]
        max_diff <- spc.diff[col, row, hour]
	prc_diff <- spc.prc[col, row, hour]
        base_units <- spc.base.units$value
        sens_units <- spc.sens.units$value

        bigdat[i, 1] <- base
        bigdat[i, 2] <- sens
        bigdat[i, 3] <- spc
        bigdat[i, 4] <- hour
        bigdat[i, 5] <- lay
        bigdat[i, 6] <- row
        bigdat[i, 7] <- col
        bigdat[i, 8] <- base_val
        bigdat[i, 9] <- sens_val
        bigdat[i, 10] <- max_diff
        bigdat[i, 11] <- prc_diff
        bigdat[i, 12] <- base_units
        bigdat[i, 13] <- sens_units

        i <- i + 1

         } # col loop
        } # row loop	
       print(hour)
       } # hour loop
    } # spc loop
  } # sens loop
}

  for (spc in spc.list) {
    subdat <- bigdat[bigdat$spc == spc, ]
    subdat_table <- data.table(subdat)
    print(subdat_table)
    data3 <- subdat_table[, mean(prc_diff,na.rm=TRUE),by=.(lay, row, col, spc)]
    print(data3)
    spc.sens.units <- ncatt_get(inf.sens, spc, "units")
    print(spc.sens.units$value)
    sens_units <- spc.sens.units$value

   # Create a list to store the results for each species
results <- list()

# Loop through each species
#for (spc in unique(subdat$spc)) {

  # Write the CSV file for this species
  file_path <- sprintf("%s/concdiff_base_%s_%s_%s_%s.csv", plot_dir1, base, base3, spc, plotdate)
   fwrite(data3, file= file_path, row.names = F, quote = F )
  
# Loop through each species
 for (spc in unique(subdat$spc)) {
  
  # Filter rows where prc_diff is less than 5
 # filtered_data <- subset(data3, prc_diff < 5)
  filtered_data <- subset(data3,V1 < 5)
  print(filtered_data$spc)
  
  # Calculate the percentage of time steps where prc_diff is less than 5
  percentage <- nrow(filtered_data) / nrow(data3) * 100
  print(percentage)
  
  # Create a new data frame with the desired columns
  result <- data.frame(spc = spc, avg_prc_diff = round(percentage,1))

  
  # Add the result to the list
  results <- rbind(results, result)
  #results <- rbind(results, mean_avg_prc_diff)
  print(results)
  # Write the result to a new CSV file (append to existing file)
  write.table(results, file = sprintf("%s/prc_diff_base_%s_%s_%s_%s.csv", plot_dir1, base, base3, spc, plotdate), 
              row.names = F, quote = F,col.names = TRUE, append = TRUE)
    if (!file.exists(sprintf("%s/total_%s_%s_%s.csv", plot_dir1, base, base3, plotdate))) {
  write.table(results, file = sprintf("%s/total_%s_%s_%s.csv", plot_dir1, base, base3, plotdate), 
              row.names = F, quote = F, col.names = T, append = TRUE)
    } else {
  write.table(results, file = sprintf("%s/total_%s_%s_%s.csv", plot_dir1, base, base3, plotdate), 
              row.names = F, quote = F, append = TRUE, col.names = FALSE)
   }
} 
}
#theDate <- theDate + 1
