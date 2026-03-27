#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=archive
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=23:59:59
#SBATCH --output=Slurm/archive_%A.out
#SBATCH --error=Slurm/archive_%A.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

# Modules 
module load rclone/1.68.1

export SOURCE_DIR="/scratch/pawsey1149/bottrell/Simulations/EAGLE"
export OUTPUT_PREFIX="EAGLE"
export OUTPUT_DIR="/scratch/pawsey1149/bottrell/Simulations"
export TEMP_DIR="/scratch/pawsey1149/bottrell/tmp"
export NUM_PARTS=512

bash smart_archive.sh
