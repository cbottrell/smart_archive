#!/bin/bash

# ==============================================================================
# SMART UNPACK V2 - Unpacks tar archives with absolute paths preserved
# ==============================================================================
# Designed to work with tar files created by updated smart_archive.sh
# which uses -P flag to preserve absolute paths (e.g., /scratch/pawsey1149/...)
# ==============================================================================
# CONFIGURATION
# ==============================================================================
# ARCHIVE_DIR="$1"                      # Directory containing .tar files
# ARCHIVE_PATTERN="EAGLE_*.tar"         # Pattern for tar files to unpack
# TARGET_DIR="/"                        # Target directory for extraction
# EXTRACT_DIR="/scratch/pawsey1149/bottrell/Simulations"  # Where to verify extracted files
# ==============================================================================

# Exit on error (safety)
set -e

# Error handler to show where script fails
trap 'echo "ERROR: Script failed at line $LINENO"; exit 1' ERR

# 1. VALIDATION
# ------------------------------------------------------------------------------
if [ -z "$ARCHIVE_DIR" ]; then
    echo "Usage: $0"
    echo "Set ARCHIVE_DIR, ARCHIVE_PATTERN, TARGET_DIR environment variables"
    exit 1
fi

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "ERROR: ARCHIVE_DIR does not exist: $ARCHIVE_DIR"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: TARGET_DIR does not exist: $TARGET_DIR"
    exit 1
fi

echo "--- Starting Smart Unpack V2 (Absolute Paths) ---"
echo "Source Archives: $ARCHIVE_DIR/$ARCHIVE_PATTERN"
echo "Target Directory: $TARGET_DIR"
echo "Extract Verification: $EXTRACT_DIR"

# Count archives
archive_count=$(find "$ARCHIVE_DIR" -maxdepth 1 -name "$ARCHIVE_PATTERN" -type f | wc -l)
if [ "$archive_count" -eq 0 ]; then
    echo "ERROR: No archives found matching pattern: $ARCHIVE_PATTERN"
    exit 1
fi

echo "Found $archive_count archives to process"

# 2. EXTRACTION WITH ABSOLUTE PATHS PRESERVED
# ------------------------------------------------------------------------------
echo "[1/2] Extracting archives with absolute paths..."

extract_archive() {
    archive_file=$1
    archive_name=$(basename "$archive_file")

    echo -n "      Processing $archive_name ... "

    # Check if archive is valid
    if ! tar -tf "$archive_file" >/dev/null 2>&1; then
        echo "ERROR (Corrupt archive)"
        return 1
    fi

    # Extract with absolute paths preserved:
    # -P (preserve absolute paths - do NOT strip leading /)
    # No --transform needed; paths are already absolute (/scratch/pawsey1149/...)
    # Use pushd/popd instead of subshell to handle set -e better
    pushd "$TARGET_DIR" > /dev/null
    tar -xPf "$archive_file"
    popd > /dev/null
    
    echo "OK"
    return 0
}

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
echo "Successfully extracted: $success_count"
if [ "$failed_count" -gt 0 ]; then
    echo "Failed: $failed_count"
    exit 1
else
    echo "All archives processed successfully."
    exit 0
fi
