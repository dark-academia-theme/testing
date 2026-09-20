#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
scratch_root="${repo_root}/.scratch/smoke"
screenshot="${scratch_root}/theme-harness.png"
tape="${scratch_root}/smoke.tape"
ocr="${scratch_root}/theme-harness.txt"

rm -rf "${scratch_root}"
install -d -m 0755 "${scratch_root}"
{
  cat "${repo_root}/tests/smoke.tape"
  # In VHS 0.10, Output *.png means a frame directory. Screenshot is the
  # ordinary FFmpeg-backed single-PNG command and captures the next frame.
  printf 'Screenshot "%s"\n' "${screenshot}"
  printf 'Sleep 1s\n'
} > "${tape}"

verify-theme-harness-runtime > "${scratch_root}/versions.txt"
TMPDIR="${scratch_root}" VHS_NO_SANDBOX=true vhs "${tape}"

dimensions="$(magick identify -format '%wx%h' "${screenshot}")"
[[ "${dimensions}" == 800x450 ]]
histogram="$(magick "${screenshot}" -format '%c' histogram:info:-)"
grep -Fqi '#FF00FF' <<< "${histogram}"
tesseract "${screenshot}" stdout --psm 6 2>/dev/null > "${ocr}"
grep -Fqi 'HARNESS SENTINEL' "${ocr}"

printf 'smoke passed\n'
printf 'dimensions=%s\n' "${dimensions}"
printf 'screenshot=%s\n' "${screenshot}"
