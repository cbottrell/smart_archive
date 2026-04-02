#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=archive_parallel
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=23:59:59
#SBATCH --output=archive_parallel_%A.out
#SBATCH --error=archive_parallel_%A.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

export SOURCE_DIR="/scratch/pawsey1149/bottrell/Simulations/swift-eagle"
export OUTPUT_PREFIX="swift-eagle"
export OUTPUT_DIR="/scratch/pawsey1149/bottrell/Simulations"
export TEMP_DIR="/scratch/pawsey1149/bottrell/tmp"
export NUM_PARTS=128
export MAX_PARALLEL=$SLURM_CPUS_PER_TASK

bash smart_archive_parallel.sh
