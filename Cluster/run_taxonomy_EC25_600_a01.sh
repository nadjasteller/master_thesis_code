#!/bin/bash
#SBATCH --job-name=taxonomy_EC25_600_a01
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=cpu
#SBATCH --output=taxonomy_EC25_600_a01_%j.out
#SBATCH --error=taxonomy_EC25_600_a01_%j.err

module load math/R

Rscript ~/Master_Thesis/assign_taxonomy_v3_EC25_600_a01.R
