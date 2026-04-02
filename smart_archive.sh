#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# SOURCE_DIR="$1"                               # First arg: Directory to package
# OUTPUT_DIR="$1"                               # Output directory for archives
# OUTPUT_PREFIX="EAGLE_WDM"                     # Naming prefix for the tar files
# NUM_PARTS=512                                 # Number of archives to create
# TEMP_DIR="/scratch/pawsey1149/bottrell/tmp"   # Temporary to store file lists
# ==============================================================================

# Exit on error (safety)
set -e

# 1. VALIDATION
# ------------------------------------------------------------------------------
if [ -z "$SOURCE_DIR" ]; then
    echo "Usage: $0 <source_directory>"
    exit 1
fi

# Safety Check: Ensure TEMP_DIR is not the SOURCE_DIR to prevent accidents
if [[ "$TEMP_DIR" == "$SOURCE_DIR" ]]; then
    echo "ERROR: TEMP_DIR cannot be the same as SOURCE_DIR."
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

echo "--- Starting Smart Split (Resume Mode) ---"
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"

mkdir -p "$TEMP_DIR"
# We recreate lists every time to ensure the distribution calculation is fresh
# (Sorting logic is deterministic, so bins will remain consistent if source hasn't changed)
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

# 4. ARCHIVING (With Resume Logic)
# ------------------------------------------------------------------------------
echo "[3/4] Processing archives in $OUTPUT_DIR..."

create_archive() {
    list_file=$1
    if [ ! -f "$list_file" ]; then return; fi

    part_num=$(basename "$list_file" | grep -o '[0-9]\{3\}')
    archive_name="${OUTPUT_DIR}/${OUTPUT_PREFIX}_${part_num}.tar"

    # --- RESUME CHECK ---
    if [ -f "$archive_name" ]; then
        echo -n "      Part $part_num exists. Checking integrity... "
        # Try to list the contents. If this fails, the tar is corrupt/incomplete.
        if tar -tf "$archive_name" >/dev/null 2>&1; then
            echo "OK (Skipping)"
            return
        else
            echo "CORRUPT (Recreating)"
            rm -f "$archive_name"
        fi
    else
        echo "      Processing Part $part_num -> Creating..."
    fi
    # --------------------

    # TAR COMMAND:
    # 1. -c (create), -f (filename)
    # 2. --no-recursion (flag MUST be before -T)
    # 3. -T (input list)
    # Note: Omitting -P to store relative paths, making archives portable
    tar -cf "$archive_name" --no-recursion -T "$list_file"
}

# Process sequentially
for list in "$TEMP_DIR"/list_*.txt; do
    create_archive "$list"
done

# 5. SAFE CLEANUP
# ------------------------------------------------------------------------------
echo "[4/4] Cleaning up..."
# Remove only the files we created
rm -f "$TEMP_DIR"/list_*.txt "$TEMP_DIR"/all_files_sorted.txt
# Try to remove directory (will fail safely if not empty)
rmdir "$TEMP_DIR" 2>/dev/null || true

echo "--- Done! ---"
