#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=1g
#SBATCH -n 1
#SBATCH -t 02:00:00

Rscript scatterplot_final_gcc_debug_vs_intel_debug.R
