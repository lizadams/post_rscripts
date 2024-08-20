library(ncdf4)
source("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/M3_functions.r")
library(fields)
library(rlang)
library(viridis)
library(lattice)
# Usage: add to batch script, and submit using Rscript prc_diff_less_1.R
# Developed by Manish Soni 07/22/2024


base <- "v5.5_gcc_debug"
base2 <- ""
base3 <- "v5.5_intel_debug"

sens.list2 <- c("")
sens.list3 <- c("")
sens.list <- c("v5.5_intel_debug")

inf.base <- nc_open("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/output_CCTM_v55_gcc_Bench_2018_12NE3_cracmm2_debug/CCTM_ACONC_v55_gcc_Bench_2018_12NE3_cracmm2_debug_20180701.nc")
#spc.list <- c("PRES", "O3", "NO2", "ATIJ")
spc.list <- names(inf.base$var[-1])
lay.sens.list <- c("layer1_only")

startplotdate <- as.Date("2018-07-01", format="%Y-%m-%d")
endplotdate <- as.Date("2018-07-01", format="%Y-%m-%d")  # Changed end date for more columns

# Create directories if they don't exist
current_dir <- getwd()
plot_dir <- file.path(current_dir)

# Initialize an empty list to store results for each species
species_results <- list()

# Create a vector of dates for the column headers
date_seq <- seq(startplotdate, endplotdate, by="day")
date_headers <- format(date_seq, "%Y-%m-%d")

# Column names with 'spc' and dates
col_names <- c("spc", date_headers)

for (lay.sens in lay.sens.list) {

  for (spc in spc.list) {

    # Initialize a vector to collect results for this species
    spc_results <- c()

    theDate <- startplotdate
    while (theDate <= endplotdate) {
      plotdate <- format(theDate, "%Y%m%d")

      # Correctly construct the file paths using sprintf
      inf.base.file <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/output_CCTM_v55_gcc_Bench_2018_12NE3_cracmm2_debug/CCTM_ACONC_v55_gcc_Bench_2018_12NE3_cracmm2_debug_%s.nc", plotdate)
      inf.sens.file <- sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/CMAQv55_testing/CMAQ_Project/data/output_CCTM_v54_intel21.4_debug_Bench_2018_12NE3/CCTM_ACONC_v54_intel21.4_debug_Bench_2018_12NE3_%s.nc", plotdate)

      # Open the NetCDF files
      inf.base <- nc_open(inf.base.file)
      inf.sens <- nc_open(inf.sens.file)

      spc.base <- ncvar_get(inf.base, spc)
      spc.base.units <- ncatt_get(inf.base, spc, "units")
      spc.sens <- ncvar_get(inf.sens, spc)

      # Write the CSV file for this species
      prc_diff_array <- array(NA, dim = c(dim(spc.base)[1], dim(spc.base)[2], 24))
      for (hour in 1:24) { # Loop for 24 hours
        for (col in 1:dim(spc.base)[1]) {
          for (row in 1:dim(spc.base)[2]) {
            prc_diff_array[col, row, hour] <- ((abs(spc.sens[col, row, hour] - spc.base[col, row, hour])) / ((spc.base[col, row, hour] + spc.sens[col, row, hour]) / 2)) * 100
          } # row loop
        } # col loop
      } # hour loop

      # Compute mean percentage difference for each grid cell
      mean_prc_diff <- apply(prc_diff_array, c(1, 2), mean, na.rm = TRUE)
      # Calculate percentage of values where prc_diff < 1%
      total_cells <- dim(mean_prc_diff)[1] * dim(mean_prc_diff)[2]
      cells_less_than_1 <- sum(mean_prc_diff < 1, na.rm = TRUE)
      percentage_less_than_1 <- (cells_less_than_1 / total_cells) * 100
      #print(paste("Total cells:", total_cells))
      #print(paste("Cells with mean percentage difference < 1%:", cells_less_than_1))
      #print(paste("Percentage of cells with mean percentage difference < 1%:", percentage_less_than_1))

      # Append the result to the vector for this species
      spc_results <- c(spc_results, round(percentage_less_than_1,2))

      # Clean up
      nc_close(inf.base)
      nc_close(inf.sens)
      
      theDate <- theDate + 1
    }

    # Combine results for this species into a single data frame row
    species_results[[spc]] <- data.frame(spc = spc, t(spc_results))
  }
}

# Combine all species results into a single data frame
combined_results <- do.call(rbind, species_results)

# Set the column names
colnames(combined_results) <- col_names

# Write the combined results to the CSV file
summary_file_path <- sprintf("%s/prc_summary_result_1.csv", plot_dir)
write.table(combined_results, file = summary_file_path, row.names = FALSE, quote = FALSE, col.names = TRUE, sep=",")

