# Required libraries.
library(ncdf4)
#library("M3")
source("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/M3_functions.r")
library(fields)
library(rlang)
library(viridis)
library(lattice)

# More information about ncdf package
# http://geog.uoregon.edu/bartlein/courses/geog607/Rmd/netCDF_01.htm

startplotdate <- as.Date("20180701",format="%Y%m%d")
endplotdate <- as.Date("20180702",format="%Y%m%d")

theDate <- startplotdate

while (theDate <= endplotdate) {
#	print(theDate)
	plotdate <- format(theDate,"%Y%m%d")
#	print(plotdate)

base <- "v5.5"
base2 <- ""
base3 <- "v5.4.0.1"

cctm.file1 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/output_CCTM_v55_gcc_Bench_2018_12NE3_cb6r5_ae7_aq/CCTM_ACONC_v55_gcc_Bench_2018_12NE3_cb6r5_ae7_aq_%s.nc" ,plotdate)
cctm.file2 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.4.0.4/CMAQ_REPO/data/output_CCTM_v54_gcc_Bench_2018_12NE3/CCTM_ACONC_v54_gcc_Bench_2018_12NE3_%s.nc", plotdate)
inf.base <- nc_open(cctm.file1)

sens.list2 <- c("")
sens.list3 <- c("")
sens.list <- c("v5.4.0.1")

spc.list <- names(inf.base$var[-1])
#spc.list <- c("PRES","O3","NO2")
lay.sens.list <- c("layer1_only")

for (lay.sens in lay.sens.list) {

  i <- 1

  bigdat <- data.frame(base=double(), sens=double(), spc=double(), hour=double(), lay=double(), row=double(), col=double(), base_val=double(), sens_val=double(), max_diff=double(), prc_diff=double(), base_units=character(), sens_units=character(), stringsAsFactors=F)

  for (sens in sens.list) {

    sens2 <- sens.list2[which(sens.list == sens)]
    sens3 <- sens.list3[which(sens.list == sens)]

    inf.sens <- nc_open(cctm.file2)

    for (spc in spc.list) {

      spc.base <- ncvar_get(inf.base, spc)
      spc.base.units <- ncatt_get(inf.base, spc, "units")
      print(spc.base.units$value)
      spc.sens <- ncvar_get(inf.sens, spc)
      print(spc.sens)
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

      for (hour in 1:24) {

        print(paste(lay.sens, base, sens, spc, hour, i))

        if (lay.sens == "layer1_only") {
          lay <- 1
          row <- arrayInd(which.max(abs(spc.diff[, , hour])), dim(spc.diff[, , hour]))[2]
          col <- arrayInd(which.max(abs(spc.diff[, , hour])), dim(spc.diff[, , hour]))[1]
        }

        if (lay.sens == "all_layers") {
          lay <- arrayInd(which.max(abs(spc.diff[, , , hour])), dim(spc.diff[, , , hour]))[3]
          row <- arrayInd(which.max(abs(spc.diff[, , , hour])), dim(spc.diff[, , , hour]))[2]
          col <- arrayInd(which.max(abs(spc.diff[, , , hour])), dim(spc.diff[, , , hour]))[1]
        }

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

      } # hour loop
    } # spc loop
  } # sens loop

  for (spc in spc.list) {

    subdat <- bigdat[bigdat$spc == spc, ]
    spc.sens.units <- ncatt_get(inf.sens, spc, "units")
    print(spc.sens.units$value)
    sens_units <- spc.sens.units$value
    # Create directories if they don't exist
    plot_dir1 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/plots_cb6_ae7_aq/compiler_sens/base_%s/%s", base, lay.sens)
    plot_dir2 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/plots_cb6_ae7_aq/prc_diff/base_%s/%s", base, lay.sens)
    plot_dir3 <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/plots_cb6_ae7_aq/m3diffout", base, lay.sens)
    if (!dir.exists(plot_dir1)) {
      dir.create(plot_dir1, recursive = TRUE)
    }
    if (!dir.exists(plot_dir2)) {
      dir.create(plot_dir2, recursive = TRUE)
    }
    if (!dir.exists(plot_dir3)) {
      dir.create(plot_dir3, recursive = TRUE)
    }
    png(sprintf("%s/scatterplot_%s_%s.png", plot_dir1, spc, plotdate), res=150)
    plot <- xyplot(sens_val ~ base_val, groups=sens, data=subdat,
                   main=list(label=sprintf("Date: %s, %s vs %s Compiler Tests \nBase vs Sensitivity Values at max diff(col,row) for each timestep \n %s, %s", plotdate, base, base3, spc, sens_units), cex=0.7),
                   xlab=list(label=sprintf("%s", base), cex=0.8),
                   ylab=list(label=sprintf("Sensitivity Run %s", base3), cex=0.8),
                   panel = function(x, y, ...) {
                     panel.xyplot(x, y, ...)
                     panel.abline(0, 1)
                   },
                   par.settings=list(superpose.symbol=list(pch=1:7), fontsize=list(text=10, points=8)))
    print(plot)
    dev.off()


    png(sprintf("%s/scatterplot_prc_diff_vs_time_%s_%s.png", plot_dir2, spc, plotdate), res=150)
    plot <- xyplot(prc_diff ~ hour, groups=sens, data=subdat,
                   main=list(label=sprintf("Date: %s, %s vs %s Compiler Tests \n Percentage Difference at each timestep \n %s ", plotdate, base, base3, spc ), cex=0.7),
		   xlab=sprintf("Time",base),
                   ylab="Percentage Difference",
                          panel = function(x, y, ...){
                          panel.xyplot(x, y, ...)
                   },
                   par.settings=list(superpose.symbol=list(pch=1:7), fontsize=list(text=10, points=8)))
    print(plot)
    dev.off()
    write.csv(subdat, file=sprintf("%s/concdiff_base_%s_%s_%s_%s.csv", plot_dir3, base, base3, spc, plotdate), row.names=F, quote=F)
   # Create a list to store the results for each species
results <- list()

# Loop through each species
for (spc in unique(subdat$spc)) {
  # Write the CSV file for this species
  file_path <- sprintf("%s/concdiff_base_%s_%s_%s_%s.csv", plot_dir3, base, base3, spc, plotdate)
  write.csv(subdat[subdat$spc == spc, ], file = file_path, row.names = F, quote = F)
  
  # Read the CSV file back in
  data <- read.csv(file_path, stringsAsFactors = TRUE)
  
  # Filter rows where prc_diff is less than 5
  filtered_data <- subset(data, prc_diff < 5)
  
  # Calculate the percentage of time steps where prc_diff is less than 5
  percentage <- nrow(filtered_data) / nrow(data) * 100
  
  # Create a new data frame with the desired columns
  result <- data.frame(spc = spc, avg_prc_diff = round(percentage,1))
  
  # Add the result to the list
  results <- rbind(results, result)
  print(results)
  # Write the result to a new CSV file (append to existing file)
  write.table(result, file = sprintf("%s/prc_diff_base_%s_%s_%s_%s.csv", plot_dir3, base, base3, spc, plotdate), 
              row.names = F, quote = F,col.names = TRUE)
}
if (!file.exists(sprintf("%s/total_%s_%s_%s.csv", plot_dir3, base, base3, plotdate))) {
  write.table(results, file = sprintf("%s/total_%s_%s_%s.csv", plot_dir3, base, base3, plotdate), 
              row.names = F, quote = F, col.names = T)
} else {
  write.table(results, file = sprintf("%s/total_%s_%s_%s.csv", plot_dir3, base, base3, plotdate), 
              row.names = F, quote = F, append = TRUE, col.names = FALSE)
}
  }
}
theDate <- theDate + 1
}
