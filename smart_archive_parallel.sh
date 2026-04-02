#!/bin/bash

# ==============================================================================
# SMART ARCHIVE PARALLEL - Packages files into equal-size tar archives
# ==============================================================================
# Parallelized version: runs MAX_PARALLEL archive creation jobs simultaneously
# ==============================================================================
# CONFIGURATION
# ==============================================================================
# SOURCE_DIR                            # First arg: Directory to package
# OUTPUT_DIR                            # Output directory for archives
# OUTPUT_PREFIX                         # Naming prefix for the tar files
# NUM_PARTS                             # Number of archives to create
# TEMP_DIR                              # Temporary to store file lists
# MAX_PARALLEL                          # Number of parallel jobs (default: 4)
# ==============================================================================

# Exit on error (safety)
set -e

# Error handler to show where script fails
trap 'echo "ERROR: Script failed at line $LINENO"; kill $(jobs -p) 2>/dev/null || true; exit 1' ERR

# 1. VALIDATION
# ------------------------------------------------------------------------------
if [ -z "$SOURCE_DIR" ]; then
    echo "Usage: Set SOURCE_DIR, OUTPUT_DIR, OUTPUT_PREFIX, NUM_PARTS, MAX_PARALLEL environment variables"
    exit 1
fi

# Set default for MAX_PARALLEL
MAX_PARALLEL=${MAX_PARALLEL:-4}

# Safety Check: Ensure TEMP_DIR is not the SOURCE_DIR to prevent accidents
if [[ "$TEMP_DIR" == "$SOURCE_DIR" ]]; then
    echo "ERROR: TEMP_DIR cannot be the same as SOURCE_DIR."
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

echo "--- Starting Smart Archive (Parallel Mode) ---"
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Parallel Jobs: $MAX_PARALLEL"

mkdir -p "$TEMP_DIR"
rm -f "$TEMP_DIR"/*.txt

# 2. INVENTORY & SORTING
# ------------------------------------------------------------------------------
echo "[1/4] Scanning and sorting files..."
find "$SOURCE_DIR" -path "$OUTPUT_DIR" -prune -o -type f -printf "%s\t%p\n" | sort -rn > "$TEMP_DIR/all_files_sorted.txt"

# 3. DISTRIBUTION (Bin Packing)
# ------------------------------------------------------------------------------
echo "[2/4] Distributing files into $NUM_PARTS lists..."

awk -v num_parts="$NUM_PARTS" -v out_dir="$TEMP_DIR" '
BEGIN { for (i=1; i<=num_parts; i++) bins[i] = 0 }
{
    size = $1
    path = $0
    sub(/^[0-9]+\t/, "", path)

    min_idx = 1
    min_val = bins[1]
    for (i=2; i<=num_parts; i++) {
        if (bins[i] < min_val) {
            min_val = bins[i]
            min_idx = i
        }
    }
    bins[min_idx] += size
    output_file = sprintf("%s/list_%03d.txt", out_dir, min_idx)
    print path >> output_file
}
' "$TEMP_DIR/all_files_sorted.txt"

# 4. ARCHIVING (Parallel with Resume Logic)
# ------------------------------------------------------------------------------
echo "[3/4] Processing archives in $OUTPUT_DIR (max $MAX_PARALLEL parallel jobs)..."

create_archive() {
    list_file=$1
    if [ ! -f "$list_file" ]; then return 0; fi

    part_num=$(basename "$list_file" | grep -o '[0-9]\{3\}')
    archive_name="${OUTPUT_DIR}/${OUTPUT_PREFIX}_${part_num}.tar"

    # --- RESUME CHECK ---
    if [ -f "$archive_name" ]; then
        # Try to list the contents. If this fails, the tar is corrupt/incomplete.
        if tar -tf "$archive_name" >/dev/null 2>&1; then
            echo "      Part $part_num exists (OK, Skipping)"
            return 0
        else
            echo "      Part $part_num is CORRUPT (Recreating)"
            rm -f "$archive_name"
        fi
    else
        echo "      Creating Part $part_num..."
    fi
    # --------------------

    # TAR COMMAND:
    # -c (create), -f (filename), --no-recursion (must be before -T), -T (input list)
    # Note: Omitting -P to store relative paths, making archives portable
    tar -cf "$archive_name" --no-recursion -T "$list_file"
}

export -f create_archive
export OUTPUT_DIR
export OUTPUT_PREFIX

# Process archives in parallel using GNU parallel if available, else xargs
job_count=0
for list_file in "$TEMP_DIR"/list_*.txt; do
    if [ -f "$list_file" ]; then
        # Run job in background
        create_archive "$list_file" &
        
        ((++job_count))
        
        # Wait when we reach MAX_PARALLEL
        if [ $((job_count % MAX_PARALLEL)) -eq 0 ]; then
            echo "      Waiting for batch of $MAX_PARALLEL jobs to complete..."
            wait
        fi
    fi
done

# Wait for remaining jobs
if [ $((job_count % MAX_PARALLEL)) -ne 0 ]; then
    wait
fi

# Check for any failed jobs
if ! wait; then
    echo "ERROR: Some archive jobs failed"
    exit 1
fi

# 5. SAFE CLEANUP
# ------------------------------------------------------------------------------
echo "[4/4] Cleaning up..."
rm -f "$TEMP_DIR"/list_*.txt "$TEMP_DIR"/all_files_sorted.txt
rmdir "$TEMP_DIR" 2>/dev/null || true

echo "--- Done! ---"
