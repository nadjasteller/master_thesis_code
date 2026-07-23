#!/bin/bash
#SBATCH --job-name=taxonomy_all
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --partition=cpu
#SBATCH --output=taxonomy_all_%j.out
#SBATCH --error=taxonomy_all_%j.err

module load math/R

Rscript ~/Master_Thesis/assign_taxonomy_all.R