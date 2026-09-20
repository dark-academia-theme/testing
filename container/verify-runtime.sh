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

verify-theme-harness-fedora-closure

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
shopt -s nullglob
mono_fonts=(/usr/local/share/fonts/iosevka-nerd-font-mono/IosevkaNerdFontMono-*.ttf)
proportional_fonts=(/usr/local/share/fonts/iosevka-nerd-font-mono/IosevkaNerdFontPropo-*.ttf)
non_mono_fonts=(/usr/local/share/fonts/iosevka-nerd-font-mono/IosevkaNerdFont-*.ttf)
[[ "${#mono_fonts[@]}" -eq 4 ]]
[[ "${#proportional_fonts[@]}" -eq 0 ]]
[[ "${#non_mono_fonts[@]}" -eq 0 ]]
[[ -f /usr/share/licenses/iosevka-nerd-fonts/OFL-1.1.txt ]]

expected_style_matches=(
  'Regular|IosevkaNerdFontMono-Regular.ttf'
  'Bold|IosevkaNerdFontMono-Bold.ttf'
  'Italic|IosevkaNerdFontMono-Italic.ttf'
  'Bold Italic|IosevkaNerdFontMono-BoldItalic.ttf'
)
for style_match in "${expected_style_matches[@]}"; do
  style="${style_match%%|*}"
  expected_file="${style_match#*|}"
  resolved_file="$(fc-match -f '%{file}' "Iosevka Nerd Font Mono:style=${style}")"
  [[ "${resolved_file}" == "/usr/local/share/fonts/iosevka-nerd-font-mono/${expected_file}" ]]
done

for codepoint in 0301 2500 e0b0 f0131; do
  resolved_file="$(fc-match -f '%{file}' "Iosevka Nerd Font Mono:charset=${codepoint}")"
  [[ "${resolved_file}" == /usr/local/share/fonts/iosevka-nerd-font-mono/* ]]
done
tesseract --list-langs 2>/dev/null | grep -Fxq eng

printf 'font=%s\n' "${font_match}"
printf 'font_files=%d\n' "${#mono_fonts[@]}"
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
