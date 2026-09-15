#!/bin/bash

export BASE="$PWD"
export SRC="$BASE/dataset"
export WORK="$BASE/custom_marks"
export OBS="$BASE/environment"

# echo
echo "--- Locus 3: Font object specification style ---"

FObject_Present="$OBS/marks/font-object-present"
FObject_Absent="$OBS/marks/font-object-absent"

# Indirect: /Font << followed by object-number generation-number R
grep -laP '/Font <<' "$SRC"/*.pdf 2>/dev/null \
  | sed 's|.*/||' | cut -c1-5 | sort -u > "$FObject_Present"

# Direct: everything else (pure-direct + the 8 absent docs)
( cd "$OBS" && ./minus all "marks/font-object-present" ) | sort > "$FObject_Absent"

printf 'Font-Object-Present  : %4d documents\n' "$(wc -l < "$FObject_Present")"
printf 'Font-Object-Absent   : %4d documents\n' "$(wc -l < "$FObject_Absent")"
printf 'union              : %4d (must be 1000)\n' \
  "$(cd "$OBS" && ./union "$FObject_Present" "$FObject_Absent" | wc -l)"

cp "$FObject_Present" "$FObject_Absent" "$WORK"