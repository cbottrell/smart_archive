#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=archive
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=23:59:59
#SBATCH --output=archive.out
#SBATCH --error=archive.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

export SOURCE_DIR="/scratch/pawsey1149/bottrell/swift-eagle"
export OUTPUT_PREFIX="swift-eagle"
export OUTPUT_DIR="/scratch/pawsey1149/bottrell/archives"
export TEMP_DIR="/scratch/pawsey1149/bottrell/tmp"
export NUM_PARTS=128

bash smart_archive.sh
