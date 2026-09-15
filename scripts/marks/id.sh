#!/bin/bash

export BASE="$PWD"
export SRC="$BASE/dataset"
export WORK="$BASE/custom_marks"
export OBS="$BASE/environment"

# echo
echo "--- Locus 3: Font object specification style ---"

ID_Present="$OBS/marks/id_present"
ID_Absent="$OBS/marks/id_absent"


# Indirect: /ID [ ... ] followed by object-number generation-number R
grep -laP '/ID\s+\[(?:<[0-9A-Fa-f]+>\s*)+\]' "$SRC"/*.pdf 2>/dev/null \
  | sed 's|.*/||' | cut -c1-5 | sort -u > "$ID_Present"

# Direct: everything else (pure-direct + the 8 absent docs)
( cd "$OBS" && ./minus all "$ID_Present" ) | sort > "$ID_Absent"

printf 'id_present  : %4d documents\n' "$(wc -l < "$ID_Present")"
printf 'id_absent   : %4d documents\n' "$(wc -l < "$ID_Absent")"
printf 'union              : %4d (must be 1000)\n' \
  "$(cd "$OBS" && ./union "$ID_Present" "$ID_Absent" | wc -l)"

cp "$ID_Present" "$ID_Absent" "$WORK"