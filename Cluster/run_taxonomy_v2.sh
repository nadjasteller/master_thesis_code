#!/bin/bash
#SBATCH --job-name=taxonomy_v2
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=cpu
#SBATCH --output=taxonomy_v2_%j.out
#SBATCH --error=taxonomy_v2_%j.err

module load math/R

Rscript ~/Master_Thesis/assign_taxonomy_v2.R
