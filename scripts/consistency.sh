#!/bin/bash
# consistency_loci.sh — §3.2 consistency check for all candidate loci
# Runs: minus class mark | wc -l for every class × mark combination
# MUST use classes/ (induced classes), NOT tools/ (exemplar sets)
set -u

export BASE="$PWD"
export OBS="$BASE/environment"

CLASSES="$OBS/classes"

# All 15 induced classes with their expected sizes
CLASS_NAMES=(pr01 pr02 pr03 pr04 pr05 pr06 pr07 pr08
             pr09 pr10 pr11 pr12 pr13 pr14 pr15)

# Expected sizes for sanity check (from lecturer announcement)
declare -A EXPECTED=(
  [pr01]=63  [pr02]=63  [pr03]=63  [pr04]=14  [pr05]=19
  [pr06]=19  [pr07]=10  [pr08]=27  [pr09]=27  [pr10]=22
  [pr11]=22  [pr12]=29  [pr13]=15  [pr14]=174 [pr15]=52
)

# ── Sanity check: verify class sizes before running ──────────
echo "Verifying class sizes..."
ALL_OK=1
for cls in "${CLASS_NAMES[@]}"; do
    actual=$(wc -l < "$CLASSES/$cls" 2>/dev/null || echo 0)
    expected="${EXPECTED[$cls]}"
    if [ "$actual" -ne "$expected" ]; then
        echo "  WARNING: $cls expected $expected got $actual"
        ALL_OK=0
    fi
done
if [ "$ALL_OK" -eq 1 ]; then
    echo "  All class sizes correct. Proceeding."
else
    echo "  Class size mismatch — check your environment before trusting results."
fi
echo


# ── Helper: print one consistency table ──────────────────────
# Usage: print_table "Title" mark1 mark2 [mark3 ...]
print_table() {
    local title="$1"; shift
    local marks=("$@")
    local ncols=${#marks[@]}

    echo "======================================================="
    echo "  $title"
    echo "  Value = docs in class NOT having the mark (0 = consistent)"
    echo "======================================================="

    # Header
    printf '%-6s  %5s' "Class" "Size"
    for m in "${marks[@]}"; do printf '  %18s' "$m"; done
    echo

    # Rows
    for cls in "${CLASS_NAMES[@]}"; do
        cls_size=$(wc -l < "$CLASSES/$cls" 2>/dev/null || echo "?")
        printf '%-6s  %5s' "$cls" "$cls_size"
        for mark in "${marks[@]}"; do
            result=$( cd "$OBS" && ./minus "classes/$cls" "marks/$mark" \
                      2>/dev/null | wc -l )
            printf '  %18s' "$result"
        done
        echo
    done
    echo "======================================================="
    echo
}


# ── LOCUS 1: CropBox ─────────────────────────────────────────
print_table "LOCUS 1 — cropbox-* (presence/absence)" \
    cropbox-present cropbox-absent


# ── LOCUS 2: Resources ───────────────────────────────────────
print_table "LOCUS 2 — resources-* (direct vs indirect)" \
    resources-indirect resources-direct

# ── LOCUS 3: Font Objects ─────────────────────────────────────
print_table "LOCUS 3 — fontobj-* (presence vs absence)" \
    font-object-present font-object-absent

print_table "LOCUS 4 — ID-* (presence vs absence)" \
    id_present id_absent

print_table "LOCUS 4 — Sequence-* (presence vs absence)" \
    seq-free-present seq-free-absent


# ── ALTERNATIVE A: Metadata ──────────────────────────────────
print_table "ALTERNATIVE A — metadata-* (presence/absence)" \
    metadata-present metadata-absent


# ── ALTERNATIVE B: DecodeParms ───────────────────────────────
print_table "ALTERNATIVE B — decodeparms-* (presence/absence)" \
    decodeparms-present decodeparms-absent