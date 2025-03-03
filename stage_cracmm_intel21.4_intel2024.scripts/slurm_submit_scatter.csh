#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=8g
#SBATCH -n 1
#SBATCH -t 24:00:00

Rscript scatterplot_final_liz.R
