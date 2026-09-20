#!/usr/bin/env bash
set -euo pipefail

lock_file="${1:-/usr/share/theme-harness/locks/fedora-43-amd64.lock}"
expected_key_fingerprint=c6e7f081cf80e13146676e88829b606631645531
declare -A locked_nevras=()

while IFS= read -r line; do
  case "${line}" in
    '#'*|'') continue ;;
  esac
  IFS=$'\t' read -r nevra _ <<< "${line}"
  locked_nevras["${nevra}"]=present
done < "${lock_file}"

fedora_count=0
while IFS= read -r installed_nevra; do
  [[ "${installed_nevra}" == *.fc43.* ]] || continue
  [[ -n "${locked_nevras[${installed_nevra}]+present}" ]]
  ((fedora_count += 1))
done < <(rpm -qa --qf '%{NAME}-%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort)
[[ "${fedora_count}" -gt 0 ]]
[[ "${fedora_count}" -eq "${#locked_nevras[@]}" ]]

expected_fedora_packages=(
  chromium-common-0:153.0.8010.36-1.fc43.x86_64
  chromium-headless-0:153.0.8010.36-1.fc43.x86_64
  ffmpeg-free-0:7.1.5-1.fc43.x86_64
  ImageMagick-1:7.1.2.27-1.fc43.x86_64
  jq-0:1.8.1-3.fc43.x86_64
  tesseract-0:5.5.3-1.fc43.x86_64
  tesseract-langpack-eng-0:4.1.0-11.fc43.noarch
  ttyd-0:1.7.7-7.fc43.x86_64
  vhs-0:0.10.0-4.fc43.x86_64
)
for expected_nevra in "${expected_fedora_packages[@]}"; do
  rpm -q --qf '%{NAME}-%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    "${expected_nevra}" | grep -Fxq "${expected_nevra}"
done
if rpm -q chromium >/dev/null 2>&1; then
  printf 'full Chromium must not be installed\n' >&2
  exit 1
fi

expected_hummingbird_packages=(
  fontconfig-0:2.18.3-1.hum1.x86_64
  git-0:2.55.0-2.hum1.x86_64
  glibc-gconv-extra-0:2.43-8.5.hum1.x86_64
  gzip-0:1.14-4.hum1.x86_64
  tar-2:1.35-10.hum1.x86_64
  xz-1:5.8.3-2.hum1.x86_64
)
for expected_nevra in "${expected_hummingbird_packages[@]}"; do
  rpm -q --qf '%{NAME}-%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    "${expected_nevra}" | grep -Fxq "${expected_nevra}"
done

rpmkeys --list | grep -Fq "${expected_key_fingerprint} "
[[ ! -e /tmp/RPM-GPG-KEY-fedora-43-primary ]]

current_repository=
declare -A disabled_repositories=()
while IFS= read -r line; do
  case "${line}" in
    '['*']')
      current_repository="${line#[}"
      current_repository="${current_repository%]}"
      ;;
    'enabled=0')
      case "${current_repository}" in
        fedora-release|fedora-updates)
          disabled_repositories["${current_repository}"]=present
          ;;
      esac
      ;;
    'enabled='*)
      case "${current_repository}" in
        fedora-release|fedora-updates)
          printf '%s must remain disabled by default\n' "${current_repository}" >&2
          exit 1
          ;;
      esac
      ;;
  esac
done < /etc/yum.repos.d/fedora-43.repo
[[ -n "${disabled_repositories[fedora-release]+present}" ]]
[[ -n "${disabled_repositories[fedora-updates]+present}" ]]

printf 'fedora_lock_entries=%d\n' "${#locked_nevras[@]}"
printf 'installed_fedora_packages=%d\n' "${fedora_count}"
