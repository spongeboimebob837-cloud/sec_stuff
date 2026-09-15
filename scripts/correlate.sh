#!/bin/bash
# correlate_loci.sh — §3.3 md5sum correlation analysis
# Replicates Prof Olivier's exact seenin/md5sum method
# Run this AFTER detect_loci.sh has built all mark files
set -u

export BASE="$PWD"
export OBS="$BASE/environment"

SEENIN="$OBS/seenin"
mkdir -p "$SEENIN"

# ── Copy your new marks into seenin/ ─────────────────────────
echo "Building seenin/ sets..."

for mark in cropbox-present cropbox-absent \
            resources-indirect resources-direct \
            metadata-present metadata-absent \
            decodeparms-present decodeparms-absent; do
    src="$OBS/marks/$mark"
    if [ -f "$src" ]; then
        cp "$src" "$SEENIN/$mark"
    else
        echo "  WARNING: marks/$mark not found — skipping"
    fi
done

# Copy existing paper marks for comparison
# Adjust names if your marks/ folder uses different filenames
for mark in stream-lf stream-cr-lf stream-cr-other stream-absent \
            endobj-lf endobj-cr-lf endstream-lf endstream-cr-lf \
            length-direct length-indirect length-absent; do
    src="$OBS/marks/$mark"
    if [ -f "$src" ]; then
        cp "$src" "$SEENIN/$mark"
    fi
done

echo "  seenin/ contains $(ls "$SEENIN" | wc -l) mark files"
echo


# ── md5sum check ─────────────────────────────────────────────
echo "======================================================="
echo "  CropBox marks vs stream-* marks"
echo "  (same MD5 = identical documents = perfect correlation)"
echo "======================================================="
md5sum "$SEENIN"/cropbox-* "$SEENIN"/stream-* 2>/dev/null | sort
echo

echo "======================================================="
echo "  Resources marks vs stream-* and length-* marks"
echo "======================================================="
md5sum "$SEENIN"/resources-* "$SEENIN"/stream-* \
       "$SEENIN"/length-* 2>/dev/null | sort
echo

echo "======================================================="
echo "  All marks — full correlation view"
echo "======================================================="
md5sum "$SEENIN"/* 2>/dev/null | sort
echo


# ── Group correlated marks automatically ─────────────────────
echo "======================================================="
echo "  Correlated mark pairs (same set of documents)"
echo "======================================================="
md5sum "$SEENIN"/* 2>/dev/null | sort | awk '
{
    hash = $1
    file = $2
    sub(".*/", "", file)
    groups[hash] = groups[hash] (groups[hash] ? "  |  " : "") file
}
END {
    for (h in groups) {
        if (index(groups[h], "|") > 0)
            print "CORRELATED: " groups[h]
    }
}' | sort

echo "======================================================="
echo "(No output above = no perfect correlations found)"