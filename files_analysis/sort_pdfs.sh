#!/bin/bash

# ---------- config ----------
DATASET_DIR="../dataset"
CSV="lcwa_gov_pdf_metadata.csv"
OUT_DIR="output"
PRODUCER_DIR="$OUT_DIR/by_producer"
CLASS_DIR="$OUT_DIR/15_classes"
MANIFEST="$OUT_DIR/manifest.csv"

# 15 classes: "ClassFolderName|producer substring" (ordered, first match wins)
class_rules=(
  "Acrobat_Distiller|Acrobat Distiller"
  "Acrobat_PDFWriter|Acrobat PDFWriter"
  "Acrobat_PDFWriter|Acrobat PDF Writer"
  "Acrobat_Net_Distiller|Acrobat Net Distiller"
  "Capture_Scan_Plugins|Paper Capture"
  "Capture_Scan_Plugins|Scan Plug-in"
  "Capture_Scan_Plugins|Scan Library"
  "Capture_Scan_Plugins|Image Conversion Plug-in"
  "Capture_Scan_Plugins|Xerox"
  "Capture_Scan_Plugins|Hewlett-Packard"
  "Capture_Scan_Plugins|OmniPage"
  "Adobe_PDF_Library|Adobe PDF Library"
  "Adobe_PDF_Library|Adobe PDF library"
  "Adobe_PDF_Library|Adobe PDF Scan Library"
  "Ghostscript|Ghostscript"
  "libtiff_tiff2pdf|libtiff / tiff2pdf"
  "MacOS_X_Quartz|Quartz PDFContext"
  "Microsoft_Office|Microsoft"
  "iText|iText"
  "PD4ML|PD4ML"
  "TCPDF|TCPDF"
  "mPDF|mPDF"
  "Corel_PDF_Engine|Corel PDF Engine"
  "PDFlib_PDI|PDFlib"
  "PDFlib_PDI|PDI"
)

# ---------- setup ----------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR" || exit 1
DATASET_DIR="$BASE_DIR/$DATASET_DIR"
mkdir -p "$PRODUCER_DIR" "$CLASS_DIR"

declare -A producer creator
digests=()

# Parse CSV (latin-1, proper quoting) -> digest<TAB>producer<TAB>creator
while IFS=$'\t' read -r d p c; do
  [ -n "$d" ] || continue
  producer[$d]="$p"
  creator[$d]="$c"
  digests+=("$d")
done < <(python3 - "$CSV" <<'PY'
import csv, re, sys
ctrl = re.compile(r'[\x00-\x1f\x7f]')
with open(sys.argv[1], encoding='latin-1', newline='') as f:
    for r in csv.DictReader(f):
        d = (r['digest'] or '').strip()
        if not d:
            continue
        p = ctrl.sub(' ', ' '.join(((r['producer'] or '').strip() or '-').split()))
        c = ctrl.sub(' ', ' '.join(((r['creator_tool'] or '').strip() or '-').split()))
        print(d + '\t' + p + '\t' + c)
PY
)

sanitize() {
  local s="$1"
  s="${s//\//_}"
  s="${s//:/_}"
  while [[ "$s" == *"  "* ]]; do s="${s//  / }"; done
  s="${s# }"
  s="${s% }"
  s="${s%,}"
  [ -n "$s" ] && [ "$s" != "." ] && [ "$s" != ".." ] || s="Unknown producer"
  echo "$s"
}

assign_class() {
  local prod="$1" entry name sub
  for entry in "${class_rules[@]}"; do
    name="${entry%%|*}"
    sub="${entry#*|}"
    case "$prod" in
      *"$sub"*) echo "$name"; return 0 ;;
    esac
  done
  echo "Unknown"
}

quote() {
  local s="${1//\"/\"\"}"
  printf '"%s"' "$s"
}

printf '%s\n' "digest,producer,creator,producer_folder,class,pre_path,post_path" > "$MANIFEST"

declare -A producer_count class_count

total=0
for d in "${digests[@]}"; do
  src="$DATASET_DIR/$d.pdf"
  if [ ! -f "$src" ]; then
    echo "WARN missing: $src"
    continue
  fi

  prod="${producer[$d]:-Unknown producer}"
  cre="${creator[$d]:-Unknown creator}"
  [ "$prod" = "-" ] && prod="Unknown producer"

  pdir="$(sanitize "$prod")"
  cls="$(assign_class "$prod")"

  mkdir -p "$PRODUCER_DIR/$pdir" "$CLASS_DIR/$cls"

  pre="$PRODUCER_DIR/$pdir/${d}_pre.pdf"
  post="$PRODUCER_DIR/$pdir/${d}_post.pdf"
  cpre="$CLASS_DIR/$cls/${d}_pre.pdf"
  cpost="$CLASS_DIR/$cls/${d}_post.pdf"

  xxd -p "$src" | tr -d "\n" | sed "s/656e6473747265616d/\n/g" | sed "s/73747265616d.*//" > "$pre"
  cat "$pre" | xxd -r -p > "$post"

  cp "$pre" "$cpre"
  cp "$post" "$cpost"

  producer_count[$pdir]=$((${producer_count[$pdir]:-0} + 1))
  class_count[$cls]=$((${class_count[$cls]:-0} + 1))

  printf '%s' "$(quote "$d")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$prod")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$cre")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$pdir")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$cls")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$pre")" >> "$MANIFEST"
  printf ',' >> "$MANIFEST"
  printf '%s' "$(quote "$post")" >> "$MANIFEST"
  printf '\n' >> "$MANIFEST"

  total=$((total + 1))
done

sort -t, -k1,1 -f "$OUT_DIR/class_counts.txt" > /dev/null 2>&1 || true
{
  echo "Class,Count"
  for k in "${!class_count[@]}"; do echo "$k,${class_count[$k]}"; done | sort
} > "$OUT_DIR/class_counts.txt"

echo "=============================="
echo "processed: $total PDFs"
echo "producer folders: ${#producer_count[@]} (incl. Unknown producer)"
echo "=============================="
for k in "${!class_count[@]}"; do printf '%-24s %s\n' "$k" "${class_count[$k]}"; done | sort
echo "=============================="
echo "manifest: $MANIFEST"