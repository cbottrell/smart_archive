#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=unpack_v2_parallel
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=23:59:59
#SBATCH --output=Slurm/unpack_v2_parallel_%A.out
#SBATCH --error=Slurm/unpack_v2_parallel_%A.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

# Configuration: Set archive and target directories
# TARGET_DIR is where extracted files will be placed (archives contain relative paths)
export ARCHIVE_DIR="/scratch/pawsey1149/bottrell/Simulations"
export ARCHIVE_PATTERN="EAGLE_*.tar"
export TARGET_DIR="/scratch/pawsey1149/bottrell/Simulations"
export EXTRACT_DIR="/scratch/pawsey1149/bottrell/Simulations"
export MAX_PARALLEL=$SLURM_CPUS_PER_TASK

bash smart_unpack_v2_parallel.sh
