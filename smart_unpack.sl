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

# Modules 
module load rclone/1.68.1

# Configuration: Set archive and target directories
# TARGET_DIR is where extracted files will be placed (archives contain relative paths)
export ARCHIVE_DIR="/scratch/pawsey1149/bottrell/Simulations"
export ARCHIVE_PATTERN="EAGLE_*.tar"
export TARGET_DIR="/scratch/pawsey1149/bottrell/Simulations"
export EXTRACT_DIR="/scratch/pawsey1149/bottrell/Simulations"

bash smart_unpack_v2.sh
