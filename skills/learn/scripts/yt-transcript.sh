#!/usr/bin/env bash
# Fetch a clean plain-text transcript + metadata for a YouTube URL via yt-dlp.
# No video is downloaded — captions only.
# Usage: yt-transcript.sh <youtube-url> [lang-prefix]   (default lang: en)
# Output: TITLE/CHANNEL/DATE/URL header, then ---TRANSCRIPT---, then the text.
# Exit codes: 2 = yt-dlp missing, 3 = no captions available for this video.
set -euo pipefail

URL="${1:?usage: yt-transcript.sh <youtube-url> [lang]}"
LANG_PREFIX="${2:-en}"

command -v yt-dlp >/dev/null || { echo "ERROR: yt-dlp not installed (brew install yt-dlp)" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1) Metadata (one line per field, in order — robust against titles containing delimiters).
META="$(yt-dlp --skip-download --no-warnings \
  --print "%(title)s" --print "%(channel,uploader)s" \
  --print "%(upload_date)s" --print "%(webpage_url)s" "$URL" 2>/dev/null || true)"
TITLE="$(printf '%s\n' "$META"  | sed -n '1p')"
CHANNEL="$(printf '%s\n' "$META" | sed -n '2p')"
DATE="$(printf '%s\n' "$META"   | sed -n '3p')"
URLOUT="$(printf '%s\n' "$META"  | sed -n '4p')"
[ -z "$URLOUT" ] && URLOUT="$URL"
if printf '%s' "$DATE" | grep -qE '^[0-9]{8}$'; then
  DATE="${DATE:0:4}-${DATE:4:2}-${DATE:6:2}"
fi

# 2) Captions — prefer manual subs, fall back to auto-generated.
yt-dlp --skip-download --write-subs --write-auto-subs \
  --sub-langs "${LANG_PREFIX}.*,${LANG_PREFIX}" --sub-format vtt \
  -o "$TMP/v.%(ext)s" "$URL" >/dev/null 2>&1 || true

VTT="$(ls "$TMP"/v.*.vtt 2>/dev/null | sort | head -1 || true)"
if [ -z "${VTT:-}" ]; then
  echo "ERROR: no ${LANG_PREFIX} captions found for this video. Paste the transcript instead." >&2
  exit 3
fi

printf 'TITLE: %s\nCHANNEL: %s\nDATE: %s\nURL: %s\n---TRANSCRIPT---\n' \
  "$TITLE" "$CHANNEL" "$DATE" "$URLOUT"

python3 - "$VTT" <<'PY'
import sys, re
out = []
for l in open(sys.argv[1], encoding="utf-8").read().splitlines():
    if "-->" in l or not l.strip():
        continue
    if l.startswith(("WEBVTT", "Kind:", "Language:")):
        continue
    l = re.sub(r"<[^>]+>", "", l)          # strip inline word-timing tags
    l = re.sub(r"\s+", " ", l).strip()
    if not l:
        continue
    if out:                                 # collapse rolling auto-caption duplication
        prev = out[-1]
        if l == prev or prev.endswith(l):
            continue
        if l.startswith(prev):              # new cue extends previous -> replace
            out[-1] = l
            continue
    out.append(l)
print(" ".join(out))
PY
