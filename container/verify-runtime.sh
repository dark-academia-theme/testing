#!/usr/bin/env bash
set -euo pipefail

expected_commands=(
  chromium-browser
  fc-match
  ffmpeg
  git
  gzip
  jq
  magick
  tar
  tesseract
  ttyd
  vhs
  xz
)

for command_name in "${expected_commands[@]}"; do
  command -v "${command_name}" >/dev/null
done

[[ "$(id -un)" == nonroot ]]
[[ "${HOME}" == /home/nonroot ]]
[[ "${LANG}" == C.UTF-8 ]]
[[ "${LC_ALL}" == C.UTF-8 ]]
[[ "${TERM}" == xterm-256color ]]
[[ "${COLORTERM}" == truecolor ]]
[[ "${PWD}" == /workspaces* ]]

font_match="$(fc-match -f '%{family}|%{file}\n' 'Iosevka Nerd Font Mono')"
grep -Fq 'Iosevka Nerd Font Mono' <<< "${font_match}"
grep -Fq '|/usr/local/share/fonts/iosevka-nerd-font-mono/' <<< "${font_match}"
tesseract --list-langs 2>/dev/null | grep -Fxq eng

printf 'font=%s\n' "${font_match}"
chromium-browser --version
ffmpeg -version | sed -n '1p'
git --version
gzip --version | sed -n '1p'
jq --version
magick -version | sed -n '1p'
tar --version | sed -n '1p'
tesseract --version | sed -n '1p'
ttyd --version
vhs --version
xz --version | sed -n '1p'
