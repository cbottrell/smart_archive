#!/bin/bash -l
#SBATCH --account=pawsey1149
#SBATCH --job-name=unpack
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=23:59:59
#SBATCH --output=unpack.out
#SBATCH --error=unpack.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=connor.bottrell@uwa.edu.au
#SBATCH --export=NONE

# Configuration: Set archive and extraction directory
# EXTRACT_DIR is where files will be extracted (archives contain relative paths)
export ARCHIVE_DIR="/scratch/pawsey1149/bottrell/archives"
export ARCHIVE_PATTERN="swift-eagle_*.tar"
export EXTRACT_DIR="/scratch/pawsey1149/bottrell"

bash smart_unpack.sh
