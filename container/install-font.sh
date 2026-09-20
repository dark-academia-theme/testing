#!/usr/bin/env bash
set -euo pipefail

version=3.5.1
sha256=3b94ea1dc3955756762f977b7677bca671947dd56bc755a6f8465a8e83b5f257
archive=/tmp/Iosevka.tar.xz
destination=/usr/local/share/fonts/iosevka-nerd-font-mono
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/Iosevka.tar.xz"

curl --fail --location --retry 3 --output "${archive}" "${url}"
printf '%s  %s\n' "${sha256}" "${archive}" | sha256sum --check --strict
install -d -m 0755 "${destination}"
tar -xJf "${archive}" -C "${destination}"
rm -f "${archive}"
fc-cache --force
