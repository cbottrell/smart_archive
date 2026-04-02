#!/bin/bash

# ==============================================================================
# SMART UNPACK V2 PARALLEL - Unpacks tar archives with relative paths
# ==============================================================================
# Parallelized version: runs MAX_PARALLEL extraction jobs simultaneously
# Designed for tar files created by updated smart_archive.sh which stores relative paths
# ==============================================================================
# CONFIGURATION
# ==============================================================================
# ARCHIVE_DIR                           # Directory containing .tar files
# ARCHIVE_PATTERN                       # Pattern for tar files to unpack
# EXTRACT_DIR                           # Directory for extraction
# MAX_PARALLEL                          # Number of parallel jobs (default: 4)
# ==============================================================================

# Exit on error (safety)
set -e

# Error handler to show where script fails
trap 'echo "ERROR: Script failed at line $LINENO"; kill $(jobs -p) 2>/dev/null || true; exit 1' ERR

# 1. VALIDATION
# ------------------------------------------------------------------------------
if [ -z "$ARCHIVE_DIR" ]; then
    echo "Usage: $0"
    echo "Set ARCHIVE_DIR, ARCHIVE_PATTERN, EXTRACT_DIR, MAX_PARALLEL environment variables"
    exit 1
fi

# Set default for MAX_PARALLEL
MAX_PARALLEL=${MAX_PARALLEL:-4}

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "ERROR: ARCHIVE_DIR does not exist: $ARCHIVE_DIR"
    exit 1
fi

if [ ! -d "$EXTRACT_DIR" ]; then
    echo "ERROR: EXTRACT_DIR does not exist: $EXTRACT_DIR"
    exit 1
fi

echo "--- Starting Smart Unpack V2 Parallel (Relative Paths) ---"
echo "Source Archives: $ARCHIVE_DIR/$ARCHIVE_PATTERN"
echo "Extract Directory: $EXTRACT_DIR"
echo "Parallel Jobs: $MAX_PARALLEL"

# Count archives
archive_count=$(find "$ARCHIVE_DIR" -maxdepth 1 -name "$ARCHIVE_PATTERN" -type f | wc -l)
if [ "$archive_count" -eq 0 ]; then
    echo "ERROR: No archives found matching pattern: $ARCHIVE_PATTERN"
    exit 1
fi

echo "Found $archive_count archives to process"

# 2. EXTRACTION WITH RELATIVE PATHS (PARALLEL)
# ------------------------------------------------------------------------------
echo "[1/2] Extracting archives with relative paths (parallel mode)..."

extract_archive() {
    archive_file=$1
    archive_name=$(basename "$archive_file")

    echo "      Processing $archive_name ... "

    # Check if archive is valid
    if ! tar -tf "$archive_file" >/dev/null 2>&1; then
        echo "ERROR: Corrupt archive - $archive_name"
        return 1
    fi

    # Extract with relative paths to extract directory
    # Archives contain relative paths, extraction creates subdirectories
    pushd "$EXTRACT_DIR" > /dev/null
    tar -xf "$archive_file"
    popd > /dev/null
    
    echo "          ... $archive_name extraction complete"
    return 0
}

export -f extract_archive
export EXTRACT_DIR

# Process all matching archives in parallel
job_count=0
failed_archives=()

for archive_file in "$ARCHIVE_DIR"/$ARCHIVE_PATTERN; do
    if [ -f "$archive_file" ]; then
        # Run job in background
        (
            if ! extract_archive "$archive_file"; then
                echo "ERROR processing $(basename "$archive_file")" >&2
                exit 1
            fi
        ) &
        
        ((++job_count))
        
        # Wait when we reach MAX_PARALLEL
        if [ $((job_count % MAX_PARALLEL)) -eq 0 ]; then
            echo "      Waiting for batch of $MAX_PARALLEL jobs to complete..."
            wait
        fi
    fi
done

# Wait for remaining jobs
echo "      Waiting for remaining jobs to complete..."
if ! wait; then
    echo "ERROR: Some extraction jobs failed"
    exit 1
fi

echo "      All $job_count archives processed"

# 3. VERIFICATION (Optional)
# ------------------------------------------------------------------------------
if [ -n "$EXTRACT_DIR" ] && [ -d "$EXTRACT_DIR" ]; then
    echo "[2/2] Verifying extracted files..."
    
    file_count=$(find "$EXTRACT_DIR" -type f | wc -l)
    dir_count=$(find "$EXTRACT_DIR" -type d | wc -l)
    
    echo "      Extracted directories: $dir_count"
    echo "      Extracted files: $file_count"
    
    # Check for any "scratch" directories in current directory (sign of failed paths)
    if [ -d "scratch" ]; then
        echo "      WARNING: Found 'scratch' directory in current path!"
        echo "      Some files may not have been extracted with absolute paths."
    fi
else
    echo "[2/2] Skipping verification (EXTRACT_DIR not set or doesn't exist)"
fi

# 4. SUMMARY
# ------------------------------------------------------------------------------
echo ""
echo "--- Unpack Complete ---"
echo "Successfully extracted: $job_count archives"
echo "All archives processed successfully."
exit 0
