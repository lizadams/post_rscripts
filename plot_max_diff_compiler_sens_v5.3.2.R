#Required libraries.
library(ncdf4)
#install.packages("/home/kfoley/tools/Rcode/R-packages/M3", repos = NULL, type="source")
#library("M3")
source("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/M3_functions.r")
library(fields)
library(rlang)
library(viridis)
library(lattice)

#more information about ncdf package
#http://geog.uoregon.edu/bartlein/courses/geog607/Rmd/netCDF_01.htm

base <- "4x4"
base2 <- "opt"
base3 <- "opt_4x4"
inf.base <- nc_open(sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.3.2_rel2/from_EPA/output_CCTM_v532_gcc9.1_Bench_2016_12SE1/CCTM_ACONC_v532_gcc9.1_Bench_2016_12SE1_20160701.nc",base2,base))
#note - don't try to use files on /21dayscratch this filesystem isn't accessible from longleaf


#sens.list2 <- c("16pe","16pe")
#sens.list3 <- c("opt","opt")
#sens.list <- c("opt_16","debug_16")
sens.list2 <- c("4x4pe")
sens.list3 <- c("opt")
sens.list <- c("opt_4x4")

#spc.list <- names(inf.base$var[-1])
spc.list <- c("O3")

#lay.sens.list <- c("all_layers", "layer1_only")
lay.sens.list <- c("layer1_only")
#lay.sens.list <- c("all_layers")

for(lay.sens in lay.sens.list){

i <- 1

bigdat <- data.frame(base=double(), sens=double(), spc=double(), hour=double(), lay=double(), row=double(), col=double(), base_val=double(), sens_val=double(), max_diff=double(), prc_diff=double(), base_units=character(), sens_units=character(), stringsAsFactors=F)

for(sens in sens.list){

sens2 <- sens.list2[which(sens.list == sens)]
sens3 <- sens.list3[which(sens.list == sens)]


inf.sens <- nc_open(sprintf("/proj/ie/proj/CMAS/CMAQ/CMAQv5.3.2_rel2/openmpi_4.0.1_gcc_9.1.0_2/data/output_CCTM_v532_ISAM_gcc_Bench_2016_12SE1/CCTM_ACONC_v532_ISAM_gcc_Bench_2016_12SE1_20160701.nc",sens3,sens2))

for(spc in spc.list){

spc.base <- ncvar_get(inf.base, spc)
#print(spc.base)
spc.base.units <- att.get.ncdf(inf.base, spc, "units") 
print(spc.base.units$value)
spc.sens <- get.var.ncdf(inf.sens, spc)
print(spc.sens)
spc.sens.units <- att.get.ncdf(inf.sens, spc, "units")
print(spc.sens.units$value)
spc.diff <- spc.sens-spc.base
#print(spc.diff)
spc.prc <- ((abs(spc.sens-spc.base))/((spc.base+spc.sens)/2))*100
#print(spc.prc)

for(hour in 1:24){

print(paste(lay.sens, base, sens, spc, hour, i))

if(lay.sens == "layer1_only"){
lay <- 1
row <- arrayInd(which.max(abs(spc.diff[,,hour])), dim(spc.diff[,,hour]))[2]
col <- arrayInd(which.max(abs(spc.diff[,,hour])), dim(spc.diff[,,hour]))[1]
}

if(lay.sens == "all_layers"){
lay <- arrayInd(which.max(abs(spc.diff[,,,hour])), dim(spc.diff[,,,hour]))[3]
row <- arrayInd(which.max(abs(spc.diff[,,,hour])), dim(spc.diff[,,,hour]))[2]
col <- arrayInd(which.max(abs(spc.diff[,,,hour])), dim(spc.diff[,,,hour]))[1]
}

base_val <- spc.base[col,row,hour]
sens_val <- spc.sens[col,row,hour]
max_diff <- spc.diff[col,row,hour]
prc_diff  <- spc.prc[col,row,hour]
base_units <- spc.base.units$value
sens_units <- spc.sens.units$value

#base, sens, spc, hour, lay, row, col, base_val, sens_val, max_diff
bigdat[i,1] <- base
bigdat[i,2] <- sens
bigdat[i,3] <- spc
bigdat[i,4] <- hour
bigdat[i,5] <- lay
bigdat[i,6] <- row
bigdat[i,7] <- col
bigdat[i,8] <- base_val
bigdat[i,9] <- sens_val
bigdat[i,10] <- max_diff
bigdat[i,11] <- prc_diff
bigdat[i,12] <- base_units
bigdat[i,13] <- sens_units

#print(bigdat[i,])

i <- i+1

} # hour loop
} # spc loop
} # sens loop

for(spc in spc.list){

subdat <- bigdat[bigdat$spc == spc,]
spc.sens.units <- att.get.ncdf(inf.sens, spc, "units")
print(spc.sens.units$value)
sens_units <- spc.sens.units$value

openImg(sprintf("plots/compiler_sens/base_%s/%s/scatterplot_%s.png", base, lay.sens, spc), res=150)
plot <- xyplot(sens_val ~ base_val, groups=sens, data=subdat, 
	main=sprintf("CMAQv5.3.2 Compiler Tests \nBase vs Sensitivity Values at max diff(col,row) for each timestep \n %s, %s", spc,sens_units),
	xlab=sprintf("%s,%s",base,base3),
	ylab="Sensitivity Run",
        panel = function(x, y, ...){
		panel.xyplot(x, y, ...)
		#panel.abline(0, 0.9, lty=2)
		#panel.abline(0, 0.95, lty=2)
		#panel.abline(0, 0.98, lty=2)
		panel.abline(0, 1)
		#panel.abline(0, 1.02, lty=2)
		#panel.abline(0, 1.05, lty=2)
		#panel.abline(0, 1.1, lty=2)
		},
	auto.key=list(space="right"),
	par.settings=list(superpose.symbol=list(pch=1:7)))
print(plot)
dev.off()

openImg(sprintf("plots/prc_diff/base_%s/%s/scatterplot_prc_diff_vs_time_%s.png", base, lay.sens, spc), res=150)
plot <- xyplot(prc_diff ~ hour, groups=sens, data=subdat,
	main=sprintf("CMAQv5.3.2 Compiler Tests \n Percentage Difference at each timestep \n %s from base: %s", spc,base3),
	xlab=sprintf("Time",base),
	ylab="Percentage Difference",
		panel = function(x, y, ...){
		panel.xyplot(x, y, ...)
		#panel.abline(0, 0.9, lty=2)
		#panel.abline(0, 0.95, lty=2)
		#panel.abline(0, 0.98, lty=2)
		#panel.abline(0, 1)
		#panel.abline(0, 1.02, lty=2)
		#panel.abline(0, 1.05, lty=2)
		#panel.abline(0, 1.1, lty=2)
		},
		auto.key=list(space="right"),
		par.settings=list(superpose.symbol=list(pch=1:7)))
print(plot)
dev.off()

write.csv(bigdat, file=sprintf("m3diffout/concdiff_base_%s_%s_per_spc.csv", base, lay.sens), row.names=F, quote=F)

} # spc loop

write.csv(bigdat, file=sprintf("m3diffout/concdiff_base_%s_%s.csv", base, lay.sens), row.names=F, quote=F)

} # lay sens
