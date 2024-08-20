#Required libraries.
library(ncdf4)
#install.packages("/home/kfoley/tools/Rcode/R-packages/M3", repos = NULL, type="source")
#library("M3")
#source("/home/kfoley/tools/Rcode/R-packages/M3_functions.r")
source("/proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/M3_functions.r")
library(fields)
library(ggplot2)
library(gridExtra)


####################################################
#> Get environment variables set in .csh run script.
#> To run this script directly in R, rather than 
#> submitting the code through a run script, simply
#> define the following 7 variables. 


#> Location of R scripts for post processing and evaluation.
r.source <- Sys.getenv('UNIT_AQ_BASE')

#> Date for model run

plotdate <- Sys.getenv('DATE')


#> List of species to be plotted.  Can also use "ALL".
plot.spec.list <- unlist(strsplit(Sys.getenv('SPEC'), ","))

#> Set location where plots will be saved.
outdir <- Sys.getenv('OUTDIR')

#> Application name to use for plot titles, e.g. Code version, compiler, gridname, emissions, etc.
appl1 <- Sys.getenv('APPL1')

#> Main CMAQ output you want to evaluate, e.g. a new test or sensitivity simulation.
cctm.file1 <- Sys.getenv('CCTM_FILE_1')

#> (Optional)  A different set of output you would like to compare against cctm.file1, e.g. a base simulation.
cctm.file2 <- Sys.getenv('CCTM_FILE_2')

#> Application name for the second model run. (Optional)
appl2 <- Sys.getenv('APPL2')




####################################################
#> Open the CCTM file.
cctm1.in <- nc_open(cctm.file1)

#> Create a list of variables and units in  cctm.file1. TFLAG will always be the first variable listed in an I/O API file.
cctm1.spec <- unlist(lapply(cctm1.in$var, function(var)var$name))[-1]
#> Use gsub to strip out extra spaces.
cctm1.unit <- gsub(" ","",unlist(lapply(cctm1.in$var, function(var)var$units))[-1])

#> Pull out the time steps.
#> This M3 function is a wrapper for functions in the ncdf4 package.
datetime <- get.datetime.seq(cctm.file1)



####################################################
#> Check the species list that was provided through the SPEC variable.
#> If "ALL" is used, will plot all the species in the file. 
#> Note that this check is not case sensitive (i.e. can use "all","All", etc).
#> If a list is provided, make sure the species names match the names in the cctm.file1

if(length(grep("ALL", plot.spec.list, ignore.case=T, value=T))>0){
  
  plot.spec.list <- cctm1.spec 
  plot.unit.list <- cctm1.unit

  }else{
 
  if(sum(!plot.spec.list%in%cctm1.spec)>0){
    missing.spec <- plot.spec.list[!plot.spec.list%in%cctm1.spec]
    print(paste("WARNING",do.call("paste",c(as.list(missing.spec),sep=",")),"are not in file",cctm.file1,"and will be ignored."))
    plot.spec.list <- plot.spec.list[plot.spec.list%in%cctm1.spec]  
  }
  #Get the units associated with the species list to be plotted.
  find.unit.fun <- function(x)cctm1.unit[which(cctm1.spec==x)]
  plot.unit.list <- gsub(" ","",unlist(lapply(as.list(plot.spec.list),find.unit.fun)))

}

#> Check if a cctm.file2 was provided for comparison.
if(cctm.file2=="") stop("CCTM_FILE_2 not provided.")

#> Open the second CCTM file.
cctm2.in <- nc_open(cctm.file2)
cctm2.spec <- unlist(lapply(cctm2.in$var, function(var)var$name))[-1]

#> Make sure that the second file has the species in plot.species.list.
if(sum(!plot.spec.list%in%cctm2.spec)>0){
    missing.spec <- plot.spec.list[!plot.spec.list%in%cctm2.spec]
    print(paste("WARNING",do.call("paste",c(as.list(missing.spec),sep=",")),"are not in file",cctm.file2,"and will be ignored."))
    plot.spec.list <- plot.spec.list[plot.spec.list%in%cctm2.spec]  
  }

####################################################
#> Source file containing color palettes (my.colors, my.col.cool, my.col.warm),
#> function for setting up zlim and color scale for concentration maps (find.zlim)
#> and function for setting up zlim and color scale for maps of differences or % differences (find.diff.zlim)
source(paste(r.source,"/find_zlim.R",sep=""))



####################################################
#> Function: plot.shaded.ts
#> Purpose: For a given species, create a shaded ts of min/25th/50th/75th/max concentration.
#> Annotate the ts with the median, mean and max concentrations.
#> Input:
#> - spec.name: species to be plotted, e.g. "O3"
#> - spec.unit: units of species to be plotted, e.g. "ppbV"
#> Returns a shaded ts of min/25th/50th/75th/max concentration.


plot.shaded.ts <- function(spec.name,spec.unit){
  #Extract species
  spec.array <- ncvar_get(cctm1.in,var=spec.name) 
  #Create 5 number summary across time series. 
  spec.iqr.summary <- apply(spec.array,3, quantile, c(.25,.5,.75))
  dimnames(spec.iqr.summary)[[1]] <- c("lower","median","upper")
  spec.iqr.summary.df <- data.frame(datetime,var="iqr",t(spec.iqr.summary))
  spec.ci.summary <- apply(spec.array,3, quantile, c(.05,.5,.95))
  dimnames(spec.ci.summary)[[1]] <- c("lower","median","upper")
  spec.ci.summary.df <- data.frame(datetime,var="ci",t(spec.ci.summary))
  spec.summary.df <- rbind(spec.ci.summary.df,spec.iqr.summary.df)

  spec.minmax.summary <- apply(spec.array,3, quantile, c(0,.5,1))
  dimnames(spec.minmax.summary)[[1]] <- c("lower","median","upper")
  spec.minmax.summary.df <- data.frame(datetime,var="minmax",t(spec.minmax.summary))

  # Read in second file.
  spec.array.base <- ncvar_get(cctm2.in,var=spec.name) 
  spec.array.diff <- spec.array - spec.array.base
  #Create 5 number summary across time series. 
  spec.iqr.diff.summary <- apply(spec.array.diff,3, quantile, c(.1,.5,.9))
  dimnames(spec.iqr.diff.summary)[[1]] <- c("lower","median","upper")
  spec.iqr.diff.summary.df <- data.frame(datetime,var="iqr",t(spec.iqr.diff.summary))
  spec.ci.diff.summary <- apply(spec.array.diff,3, quantile, c(.05,.5,.95))
  dimnames(spec.ci.diff.summary)[[1]] <- c("lower","median","upper")
  spec.ci.diff.summary.df <- data.frame(datetime,var="ci",t(spec.ci.diff.summary))
  spec.diff.summary.df <- rbind(spec.ci.diff.summary.df,spec.iqr.diff.summary.df)

  spec.minmax.diff.summary <- apply(spec.array.diff,3, quantile, c(0,.5,1))
  dimnames(spec.minmax.diff.summary)[[1]] <- c("lower","median","upper")
  spec.minmax.diff.summary.df <- data.frame(datetime,var="minmax",t(spec.minmax.diff.summary))

  my.breaks <- c("iqr","ci")
  my.labels <- c("IQR","[5th, 95th]") 
	
  p1 <- ggplot(data=spec.summary.df, aes(x=datetime, y=median, ymin=lower, ymax=upper, fill=var))+geom_ribbon(alpha=0.9)+geom_line(aes(color="black"))+
    scale_fill_manual(values=c("#999999","#0072B2"),name="",breaks=my.breaks,labels=my.labels)+
    ylab(paste0(spec.name, " (",spec.unit,")"))+xlab("")+
    ggtitle(paste0("Date: (",plotdate,"), Hourly Time Series for ",spec.name," [5th,25th,50th,75th,95th]"))+
    scale_colour_manual(values=c("black","black"),name="",breaks=my.breaks,labels=my.labels)+
    guides(fill = guide_legend(keywidth = 4, keyheight = 4))

  my.breaks <- c("minmax")
  my.labels <- c("[Min, Max]") 
	
  p2 <- ggplot(data=spec.minmax.summary.df, aes(x=datetime, y=median, ymin=lower, ymax=upper))+geom_ribbon(alpha=0.9)+geom_line(aes(color="black"))+
    scale_fill_manual(values=c("#999999"),name="",breaks=my.breaks,labels=my.labels)+
    ylab(paste0(spec.name, " (",spec.unit,")"))+xlab("")+
    ggtitle(paste0("Date: (",plotdate,"), Hourly Time Series for ",spec.name," [Min,Median,Max]"))+
    scale_colour_manual(values=c("black"),name="",breaks=my.breaks,labels=my.labels)+
    guides(fill = guide_legend(keywidth = 4, keyheight = 4))


   my.breaks <- c("iqr","ci")
   my.labels <- c("IQR","[5th, 95th]") 

  p3 <- ggplot(data=spec.diff.summary.df, aes(x=datetime, y=median, ymin=lower, ymax=upper, fill=var))+geom_ribbon(alpha=0.9)+geom_line(aes(color="black"))+
    scale_fill_manual(values=c("#999999","#0072B2"),name="",breaks=my.breaks,labels=my.labels)+
    ylab(paste0(spec.name, " (",spec.unit,")"))+xlab("")+
    ggtitle(paste0(appl1," - ", appl2," for ",spec.name," [5th,25th,50th,75th,95th]"))+
    scale_colour_manual(values=c("black","black"),name="",breaks=my.breaks,labels=my.labels)+
    guides(fill = guide_legend(keywidth = 4, keyheight = 4))
 

   my.breaks <- c("minmax")
   my.labels <- c("[Min, Max]") 

  p4 <- ggplot(data=spec.minmax.diff.summary.df, aes(x=datetime, y=median, ymin=lower, ymax=upper))+geom_ribbon(alpha=0.9)+geom_line(aes(color="black"))+
    scale_fill_manual(values=c("#999999"),name="",breaks=my.breaks,labels=my.labels)+
    ylab(paste0(spec.name, " (",spec.unit,")"))+xlab("")+
    ggtitle(paste0(appl1," - ", appl2," for ",spec.name," [Min,Median,Max]"))+
    scale_colour_manual(values=c("black"),name="",breaks=my.breaks,labels=my.labels)+
    guides(fill = guide_legend(keywidth = 4, keyheight = 4))

  grid.arrange(p1+theme(legend.position="none"),p2+theme(legend.position="none"),p3+theme(legend.position="none"),p4+theme(legend.position="none"),ncol=2,nrow=2)

}


####################################################
#> Set up size of jpeg plot. 
#> mai = a numerical vector of the form c(bottom, left, top, right) which gives the margin size specified in inches.
my.mai <- c(1.1, 0.4, 0.4, 1.1)
#> Width of jpeg plots (in inches). 
my.width <- 12 	
my.height <- 8

#> Create time series of hourly concentration of every species in plot.spec.list. Save a .jpeg.
print(paste("Creating time series for:",do.call("paste",c(as.list(plot.spec.list),sep=","))))
for(i in 1:length(plot.spec.list)){
 png(paste0(outdir,"/",plot.spec.list[i],"_M2M_ts_diff_",appl1,"-",appl2,plotdate,".png"),height=my.height,width=my.width,units="in",res=400)
 par(mai=my.mai)
 plot.shaded.ts(plot.spec.list[i],plot.unit.list[i])
 dev.off()
}



#> Script completed without error. 
print("ts_diff.R complete.")



