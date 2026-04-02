# Smart Archive & Unpack Tools

A set of intelligent shell scripts for efficiently packing large directory structures into multiple tar archives and extracting them with proper path handling.

## Overview

These tools solve the challenge of archiving very large data sets by:

1. **Smart Archive (`smart_archive.sh`)**: Intelligently splits a directory into multiple tar archives using bin-packing to balance file distribution by size
2. **Smart Unpack (`smart_unpack.sh`)**: Extracts tar archives while properly maintaining and correcting file paths

## Use Cases

- Archiving large simulation outputs or datasets
- Distributing files across multiple archives for improved I/O performance
- Resumable archiving (corrupted archives are automatically recreated)
- Portable archives that extract cleanly to any location with relative directory structure

## Smart Archive

### Purpose
Packages the contents of a source directory into a configurable number of tar archives. Uses a bin-packing algorithm to distribute files evenly by size, minimizing archive size variance.

### Configuration
Set the following environment variables before running:
- `SOURCE_DIR` - Directory to archive
- `OUTPUT_DIR` - Where to write the tar files  
- `OUTPUT_PREFIX` - Naming prefix for archives (e.g., "EAGLE_WDM" produces "EAGLE_WDM_001.tar", etc.)
- `NUM_PARTS` - Number of tar files to create
- `TEMP_DIR` - Temporary scratch directory for file lists

### Key Features
- **Bin-packing algorithm**: Files are sorted by size (largest first) and distributed into the partition with the least data
- **Resume support**: If interrupted, existing archives are validated; corrupted ones are recreated
- **Clean relative paths**: Uses `tar -C` to store only relative paths from SOURCE_DIR, ensuring clean directory structure on extraction (e.g., `swift-eagle/file.txt` instead of full paths)

### Usage
```bash
export SOURCE_DIR=/scratch/pawsey1149/bottrell/swift-eagle
export OUTPUT_DIR=/scratch/pawsey1149/bottrell/archives
export OUTPUT_PREFIX=swift-eagle
export NUM_PARTS=128
export TEMP_DIR=/scratch/pawsey1149/bottrell/tmp

./smart_archive.sh
```

### Slurm Submission
```bash
sbatch smart_archive.sl
```

## Smart Unpack

### Purpose
Extracts tar archives while automatically correcting and preserving file paths. Designed to handle archives created by `smart_archive.sh` and restore files to their correct locations in the filesystem.

### Configuration
Set the following environment variables before running:
- `ARCHIVE_DIR` - Directory containing tar files to extract
- `ARCHIVE_PATTERN` - Pattern for matching archives (e.g., "swift-eagle_*.tar")
- `EXTRACT_DIR` - Directory where files should be extracted

### Key Features
- **Relative path extraction**: Extracts archives with relative paths to preserve directory structure
- **Validation**: Can verify that extracted files are present in the expected location
- **Error handling**: Reports corrupt archives and fails safely

### Usage
```bash
export ARCHIVE_DIR=/scratch/pawsey1149/bottrell/archives
export ARCHIVE_PATTERN="swift-eagle_*.tar"
export EXTRACT_DIR=/scratch/pawsey1149/bottrell/Simulations

./smart_unpack.sh
```

### Slurm Submission
```bash
sbatch smart_unpack.sl
```

## Slurm Integration

Submit archiving or unpacking jobs to the Slurm job scheduler using the provided `.sl` batch scripts:

- `smart_archive.sl` - Runs `smart_archive.sh` sequentially (1 CPU core)
- `smart_unpack.sl` - Runs `smart_unpack.sh` sequentially (1 CPU core)
- `smart_archive_parallel.sl` - Runs `smart_archive_parallel.sh` with parallelization (4 CPU cores by default)
- `smart_unpack_parallel.sl` - Runs `smart_unpack_parallel.sh` with parallelization (4 CPU cores by default)

### Example
```bash
sbatch smart_archive_parallel.sl
sbatch smart_unpack_parallel.sl
```

## Parallel Variants

Parallel versions of these tools are also available for improved performance on multi-core systems:

- `smart_archive_parallel.sh` / `smart_archive_parallel.sl` - Parallel archiving (runs multiple tar jobs simultaneously)
- `smart_unpack_parallel.sh` / `smart_unpack_parallel.sl` - Parallel extraction (runs multiple tar jobs simultaneously)

These variants spawn multiple tar jobs controlled by `MAX_PARALLEL` environment variable (defaults to `$SLURM_CPUS_PER_TASK` in batch scripts).

## Error Handling

Both scripts include robust error handling:
- Exit on first error with clear error messages
- Archive integrity checks before and after operations
- Detailed logging of progress through each phase
- Safe cleanup procedures

## Dependencies

- Requires standard Unix utilities: `bash`, `tar`, `find`, `awk`
- No special modules required (Slurm partition=copy)
- Designed for high-performance computing environments (tested with Pawsey Supercomputing Centre infrastructure)

## Notes

- Archives store only relative paths (e.g., `swift-eagle/file.txt`) for portability and clean extraction
- Use with caution on production systems; test with small datasets first
- For optimal performance on multi-core systems, use parallel variants (`smart_archive_parallel.sh`, `smart_unpack_parallel.sh`)
- Parallel variants spawn multiple tar jobs controlled by `MAX_PARALLEL` environment variable
- All scripts validate archive integrity before and after operations
