#!/bin/bash

# ==============================================================================
# SMART UNPACK V2 - Unpacks tar archives with relative paths
# ==============================================================================
# Designed to work with tar files created by updated smart_archive.sh
# which stores relative paths for portable extraction across filesystems
# ==============================================================================
# CONFIGURATION
# ==============================================================================
# ARCHIVE_DIR="$1"                      # Directory containing .tar files
# ARCHIVE_PATTERN="EAGLE_*.tar"         # Pattern for tar files to unpack
# EXTRACT_DIR="/scratch/pawsey1149/bottrell/Simulations"  # Directory for extraction
# ==============================================================================

# Exit on error (safety)
set -e

# Error handler to show where script fails
trap 'echo "ERROR: Script failed at line $LINENO"; exit 1' ERR

# 1. VALIDATION
# ------------------------------------------------------------------------------
if [ -z "$ARCHIVE_DIR" ]; then
    echo "Usage: $0"
    echo "Set ARCHIVE_DIR, ARCHIVE_PATTERN, EXTRACT_DIR environment variables"
    exit 1
fi

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "ERROR: ARCHIVE_DIR does not exist: $ARCHIVE_DIR"
    exit 1
fi

if [ ! -d "$EXTRACT_DIR" ]; then
    echo "ERROR: EXTRACT_DIR does not exist: $EXTRACT_DIR"
    exit 1
fi

echo "--- Starting Smart Unpack V2 (Relative Paths) ---"
echo "Source Archives: $ARCHIVE_DIR/$ARCHIVE_PATTERN"
echo "Extract Directory: $EXTRACT_DIR"

# Count archives
archive_count=$(find "$ARCHIVE_DIR" -maxdepth 1 -name "$ARCHIVE_PATTERN" -type f | wc -l)
if [ "$archive_count" -eq 0 ]; then
    echo "ERROR: No archives found matching pattern: $ARCHIVE_PATTERN"
    exit 1
fi

echo "Found $archive_count archives to process"

# 2. EXTRACTION WITH RELATIVE PATHS
# ------------------------------------------------------------------------------
echo "[1/2] Extracting archives with relative paths..."

extract_archive() {
    archive_file=$1
    archive_name=$(basename "$archive_file")

    echo -n "      Processing $archive_name ... "

    # Check if archive is valid
    if ! tar -tf "$archive_file" >/dev/null 2>&1; then
        echo "ERROR (Corrupt archive)"
        return 1
    fi

    # Extract with relative paths to extract directory
    # Archives contain relative paths, extraction creates subdirectories
    pushd "$EXTRACT_DIR" > /dev/null
    tar -xf "$archive_file"
    popd > /dev/null
    
    echo "OK"
    return 0


# Process all matching archives sequentially
failed_count=0
success_count=0

for archive_file in "$ARCHIVE_DIR"/$ARCHIVE_PATTERN; do
    if [ -f "$archive_file" ]; then
        if extract_archive "$archive_file"; then
            ((++success_count))
        else
            ((++failed_count))
        fi
    fi
done

# 3. VERIFICATION
# ------------------------------------------------------------------------------
echo "[2/2] Verifying extracted files..."

file_count=$(find "$EXTRACT_DIR" -type f | wc -l)
dir_count=$(find "$EXTRACT_DIR" -type d | wc -l)
    
echo "      Extracted directories: $dir_count"
echo "      Extracted files: $file_count"

# Check for any "scratch" directories in current directory (sign of failed paths)
if [ -d "scratch" ]; then
    echo "      WARNING: Found 'scratch' directory in current path!"
    echo "      Some files may not have been extracted with relative paths."
fi

# 4. SUMMARY
# ------------------------------------------------------------------------------
echo ""
echo "--- Unpack Complete ---"
echo "Successfully extracted: $success_count"
if [ "$failed_count" -gt 0 ]; then
    echo "Failed: $failed_count"
    exit 1
else
    echo "All archives processed successfully."
    exit 0
fi
