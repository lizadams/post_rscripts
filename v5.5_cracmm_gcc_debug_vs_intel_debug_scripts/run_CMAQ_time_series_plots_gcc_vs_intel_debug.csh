#! /bin/csh -f

#> Simple Linux Utility for Resource Management System 
#> (SLURM) - The following specifications are recommended 
#> for executing the runscript on the atmos cluster at the 
#> National Computing Center used primarily by EPA.
#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=1g
#SBATCH -n 1
#SBATCH -t 02:00:00



#> The following commands output information from the SLURM
#> scheduler to the log files for traceability.
#  if ( $SLURM_JOB_ID ) then
#     echo Job ID is $SLURM_JOB_ID
#     echo Host is $SLURM_SUBMIT_HOST
#     echo Nodefile is $SLURM_JOB_NODELIST
#     cat $SLURM_JOB_NODELIST | pr -o5 -4 -t
#     #> Switch to the working directory. By default,
#     #>   SLURM launches processes from your home directory.
#     echo Working directory is $SLURM_SUBMIT_DIR
#     cd $SLURM_SUBMIT_DIR
#  endif
#  echo '>>>>>> start model run at ' `date`

#> Configure the system environment and set up the module 
#> capability
   limit stacksize unlimited
#
# ==================================================================

#> Configure the system environment
 source ../R_env.csh

#> Set location of R scripts for post processing and evaluation.
 setenv UNIT_AQ_BASE  /proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts

# Set date
# foreach i ( 20180701 20180702 )
  foreach i ( 20180702 )
   setenv DATE $i

#> List of species in COMBINE file to compare.  Can also use "ALL" for plots of all species in COMBINE file.
#> Example:  setenv SPEC "O3,ATOTIJ,PM25_TOT,PM25_FRM,CO,NOX,ASO4IJ,ANO3IJ,ANH4IJ,AECIJ,AOCIJ" 
  setenv SPEC ALL

#> Set location where plots will be saved.
 setenv OUTDIR /proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/POST/rscripts/v5.5_cracmm_gcc_debug_vs_intel_debug_scripts/ts_compare_cracmm_gcc_debug_to_intel_debug

if(! -d $OUTDIR) then
      mkdir $OUTDIR
   endif

#> Application name to use for plot titles, e.g. Code version, compiler, gridname, emissions, etc.
 setenv APPL1 CMAQv5.5_gcc_debug

#> CCTM_FILE_1: Main CMAQ output you want to evaluate, e.g. a new test or sensitivity simulation.
 setenv CCTM_FILE_1 /proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/output_CCTM_v55_gcc_Bench_2018_12NE3_cracmm2_debug/CCTM_ACONC_v55_gcc_Bench_2018_12NE3_cracmm2_debug_$DATE.nc 

#> CCTM_FILE_2: (Optional)  A different set of output you would like to compare against CCTM_FILE_1, e.g. a base simulation.
#> This file was the Jun 16th version of the benchmark COMBINE_ACONC file. There were only minor model differences in this version and the final released code.
 setenv CCTM_FILE_2  /proj/ie/proj/CMAS/CMAQ/CMAQv5.5_testing/CMAQ_v5.5/data/CMAQv55_testing/CMAQ_Project/data/output_CCTM_v54_intel21.4_debug_Bench_2018_12NE3/CCTM_ACONC_v54_intel21.4_debug_Bench_2018_12NE3_$DATE.nc 

#> Application name for the second model run. (Optional)
 setenv APPL2  CMAQv5.5_intel_debug

#> List of species in COMBINE file to compare.  Can also use "ALL" for plots of all species in COMBINE file.
#> Example:  setenv SPEC "O3,ATOTIJ,PM25_TOT,PM25_FRM,CO,NOX,ASO4IJ,ANO3IJ,ANH4IJ,AECIJ,AOCIJ"
#  setenv SPEC ALL
#setenv SPEC  "O3,ATOTIJ,PM25_TOT,PM25_FRM,CO,NOX,ASO4IJ,ANO3IJ,ANH4IJ,AECIJ,AOCIJ"
#setenv SPEC  "PM25_TOT,PM25_FRM,CO,NOX,ASO4IJ,ANO3IJ,ANH4IJ,AECIJ,AOCIJ"
#setenv SPEC "O3,CO,NO2,NO"

#> Run the R script "ts_diff.R". This script creates a shaded timeseries for each species of 
#> min/25th/50th/75th/max concentration.  The ts is annotated with the median, mean and max concentrations.
 cd $OUTDIR
 R --no-save --slave < $UNIT_AQ_BASE/ts_diff.R >&! ts_diff_$APPL1.log
end
