#!/bin/bash

export BASE="$PWD"
export SRC="$BASE/dataset"
export WORK="$BASE/custom_marks"
export OBS="$BASE/environment"

# echo
echo "--- Locus 2: Resources specification style ---"

RES_INDIRECT="$OBS/marks/resources-indirect"
RES_DIRECT="$OBS/marks/resources-direct"

# Indirect: /Resources followed by object-number generation-number R
grep -laP '/Resources\s+\d+\s+\d+\s+R' "$SRC"/*.pdf 2>/dev/null \
  | sed 's|.*/||' | cut -c1-5 | sort -u > "$RES_INDIRECT"

# Direct: everything else (pure-direct + the 8 absent docs)
( cd "$OBS" && ./minus all "marks/resources-indirect" ) | sort > "$RES_DIRECT"

printf 'resources-indirect : %4d documents\n' "$(wc -l < "$RES_INDIRECT")"
printf 'resources-direct   : %4d documents\n' "$(wc -l < "$RES_DIRECT")"
printf 'union              : %4d (must be 1000)\n' \
  "$(cd "$OBS" && ./union marks/resources-indirect marks/resources-direct | wc -l)"

cp "$RES_INDIRECT" "$RES_DIRECT" "$WORK"