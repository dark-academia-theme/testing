#!/usr/bin/env bash
set -euo pipefail

version=3.5.1
sha256=3b94ea1dc3955756762f977b7677bca671947dd56bc755a6f8465a8e83b5f257
archive=/tmp/Iosevka.tar.xz
source_directory=/tmp/iosevka
font_destination=/out/fonts/iosevka-nerd-font-mono
license_source=/tmp/Iosevka-OFL-1.1.txt
license_destination=/out/licenses/iosevka-nerd-fonts/OFL-1.1.txt
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/Iosevka.tar.xz"

curl --fail --location --retry 3 --output "${archive}" "${url}"
printf '%s  %s\n' "${sha256}" "${archive}" | sha256sum --check --strict
install -d -m 0755 "${source_directory}"
tar -xJf "${archive}" -C "${source_directory}"

shopt -s nullglob
mono_fonts=("${source_directory}"/IosevkaNerdFontMono-*.ttf)
proportional_fonts=("${source_directory}"/IosevkaNerdFontPropo-*.ttf)
non_mono_fonts=("${source_directory}"/IosevkaNerdFont-*.ttf)
all_fonts=("${source_directory}"/*.ttf)
selected_fonts=(
  "${source_directory}/IosevkaNerdFontMono-Regular.ttf"
  "${source_directory}/IosevkaNerdFontMono-Bold.ttf"
  "${source_directory}/IosevkaNerdFontMono-Italic.ttf"
  "${source_directory}/IosevkaNerdFontMono-BoldItalic.ttf"
)

[[ "${#mono_fonts[@]}" -eq 27 ]]
[[ "${#proportional_fonts[@]}" -eq 27 ]]
[[ "${#non_mono_fonts[@]}" -eq 27 ]]
[[ "${#all_fonts[@]}" -eq 81 ]]
[[ -f "${source_directory}/LICENSE.md" ]]
for selected_font in "${selected_fonts[@]}"; do
  [[ -f "${selected_font}" ]]
done

install -d -m 0755 "${font_destination}" "$(dirname -- "${license_destination}")"
install -m 0644 "${selected_fonts[@]}" "${font_destination}"
install -m 0644 "${license_source}" "${license_destination}"

printf 'archive fonts: mono=%d proportional=%d non-mono=%d total=%d selected=%d\n' \
  "${#mono_fonts[@]}" "${#proportional_fonts[@]}" \
  "${#non_mono_fonts[@]}" "${#all_fonts[@]}" "${#selected_fonts[@]}"
