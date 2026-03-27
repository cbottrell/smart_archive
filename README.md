# Smart Archive & Unpack Tools

A set of intelligent shell scripts for efficiently packinglarge directory structures into multiple tar archives and extracting them with proper path handling.

## Overview

These tools solve the challenge of archiving very large data sets by:

1. **Smart Archive (`smart_archive.sh`)**: Intelligently splits a directory into multiple tar archives using bin-packing to balance file distribution by size
2. **Smart Unpack (`smart_unpack.sh`)**: Extracts tar archives while properly maintaining and correcting file paths

## Use Cases

- Archiving large simulation outputs or datasets
- Distributing files across multiple archives for improved I/O performance
- Resumable archiving (corrupted archives are automatically recreated)
- Path-preserving extraction with automatic transformation for correct directory placement

## Smart Archive

### Purpose
Packages the contents of a source directory into a configurable number of tar archives. Uses a bin-packing algorithm to distribute files evenly by size, minimizing archive size variance.

### Configuration
Set the following environment variables before running:
- `SOURCE_DIR` - Directory to archive
- `OUTPUT_DIR` - Where to write the tar files
- `OUTPUT_PREFIX` - Naming prefix for archives (e.g., "EAGLE_WDM" produces "EAGLE_WDM_001.tar", etc.)
- `NUM_PARTS` - Number of tar files to create (default: 512)
- `TEMP_DIR` - Temporary scratch directory for file lists

### Key Features
- **Bin-packing algorithm**: Files are sorted by size (largest first) and distributed into the partition with the least data
- **Resume support**: If interrupted, existing archives are validated; corrupted ones are recreated
- **Path preservation**: Maintains absolute paths in the archives

### Usage
```bash
export SOURCE_DIR=/path/to/data
export OUTPUT_DIR=/path/to/archives
export OUTPUT_PREFIX=EAGLE_WDM
export NUM_PARTS=512
export TEMP_DIR=/scratch/pawsey1149/bottrell/tmp

./smart_archive.sh
```

## Smart Unpack

### Purpose
Extracts tar archives while automatically correcting and preserving file paths. Designed to handle archives created by `smart_archive.sh` and restore files to their correct locations in the filesystem.

### Configuration
Set the following environment variables before running:
- `ARCHIVE_DIR` - Directory containing tar files to extract
- `ARCHIVE_PATTERN` - Pattern for matching archives (e.g., "EAGLE_*.tar")
- `TARGET_DIR` - Root directory where files should be extracted (typically "/")
- `EXTRACT_DIR` - Optional: Directory to verify extracted files were written

### Key Features
- **Path transformation**: Automatically prepends "/" to relative paths in archives to ensure correct extraction location
- **Validation**: Can verify that extracted files are present in the expected location
- **Error handling**: Reports corrupt archives and fails safely

### Usage
```bash
export ARCHIVE_DIR=/path/to/archives
export ARCHIVE_PATTERN="EAGLE_*.tar"
export TARGET_DIR=/
export EXTRACT_DIR=/scratch/pawsey1149/bottrell/Simulations

./smart_unpack.sh
```

## Slurm Integration

Submit archiving or unpacking jobs to the Slurm job scheduler using the provided `.sl` batch scripts:

- `smart_archive.sl` - Batch script for running `smart_archive.sh` on Slurm
- `smart_unpack.sh` - Batch script for running `smart_unpack.sh` on Slurm

### Example
```bash
sbatch smart_archive.sl
sbatch smart_unpack.sl
```

## Parallel Variants

Parallel versions of these tools are also available:
- `smart_archive_parallel.sh` / `smart_archive_parallel.sl`
- `smart_unpack_v2_parallel.sh` / `smart_unpack_v2_parallel.sl`

These variants provide enhanced performance for distributed archiving and unpacking across multiple compute nodes.

## Error Handling

Both scripts include robust error handling:
- Exit on first error with clear error messages
- Archive integrity checks before and after operations
- Detailed logging of progress through each phase
- Safe cleanup procedures

## Notes

- Requires standard Unix utilities: `bash`, `tar`, `find`, `awk`
- Designed for high-performance computing environments (tested with Pawsey Supercomputing Centre infrastructure)
- Use with caution on production systems; test with small datasets first
