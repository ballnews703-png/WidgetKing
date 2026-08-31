#!/bin/sh
# WidgetKing test battery. Run from anywhere: sh tests/run.sh
# Requires: node 18+, `npm install` inside tests/, and a Chromium binary at
# /opt/pw-browsers/chromium (or set PW_CHROMIUM to your chromium path and
# adjust the executablePath in the specs).
cd "$(dirname "$0")" || exit 1
fail=0
for f in preflight.mjs core.mjs check*.mjs; do
  [ -f "$f" ] || continue
  if node "$f" > ".out_$f.txt" 2>&1; then
    echo "$f: $(tail -1 ".out_$f.txt")"
  else
    echo "$f: FAILED"; tail -3 ".out_$f.txt"; fail=1
  fi
done
exit $fail
