#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=unpack_v2
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=23:59:59
#SBATCH --output=Slurm/unpack_v2_%A.out
#SBATCH --error=Slurm/unpack_v2_%A.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

# Configuration: Set archive and extraction directory
# EXTRACT_DIR is where files will be extracted (archives contain relative paths)
export ARCHIVE_DIR="/scratch/pawsey1149/bottrell/Simulations/eagle"
export ARCHIVE_PATTERN="EAGLE_*.tar"
export EXTRACT_DIR="/scratch/pawsey1149/bottrell/Simulations/eagle"

bash smart_unpack.sh
