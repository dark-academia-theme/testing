#!/usr/bin/env bash
set -euo pipefail

lock_file="${1:-/usr/share/theme-harness/locks/fedora-43-amd64.lock}"
key_url=https://src.fedoraproject.org/rpms/fedora-repos/raw/f43/f/RPM-GPG-KEY-fedora-43-primary
key_sha256=2b1449a082d3264dda8e18369f04e9ac4163bf3f8cb530b0783dc2ab064a08ec
key_fingerprint=c6e7f081cf80e13146676e88829b606631645531
release_repomd_url=https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/repodata/repomd.xml
updates_repomd_url=https://dl.fedoraproject.org/pub/fedora/linux/updates/43/Everything/x86_64/repodata/repomd.xml
key_file=/tmp/RPM-GPG-KEY-fedora-43-primary
rpm_directory=/tmp/fedora-rpms

release_repomd_sha256=
updates_repomd_sha256=
declare -A expected_hashes=()
declare -a release_packages=()
declare -a updates_packages=()

while IFS= read -r line; do
  case "${line}" in
    '# release-repomd-sha256: '*)
      release_repomd_sha256="${line#*: }"
      ;;
    '# updates-repomd-sha256: '*)
      updates_repomd_sha256="${line#*: }"
      ;;
    '#'*|'')
      ;;
    *)
      IFS=$'\t' read -r nevra sha256 repository extra <<< "${line}"
      [[ -n "${nevra}" && -n "${sha256}" && -n "${repository}" && -z "${extra:-}" ]]
      [[ "${nevra}" == *.x86_64 || "${nevra}" == *.noarch ]]
      [[ "${sha256}" =~ ^[0-9a-f]{64}$ ]]
      [[ -z "${expected_hashes[${nevra}]+present}" ]]
      expected_hashes["${nevra}"]="${sha256}"
      case "${repository}" in
        fedora-release) release_packages+=("${nevra}") ;;
        fedora-updates) updates_packages+=("${nevra}") ;;
        *) printf 'unexpected repository for %s: %s\n' "${nevra}" "${repository}" >&2; exit 1 ;;
      esac
      ;;
  esac
done < "${lock_file}"

[[ -n "${release_repomd_sha256}" && -n "${updates_repomd_sha256}" ]]
[[ "${#expected_hashes[@]}" -gt 0 ]]

curl --fail --location --retry 3 --output /tmp/fedora-release-repomd.xml \
  "${release_repomd_url}"
printf '%s  %s\n' "${release_repomd_sha256}" /tmp/fedora-release-repomd.xml \
  | sha256sum --check --strict
curl --fail --location --retry 3 --output /tmp/fedora-updates-repomd.xml \
  "${updates_repomd_url}"
printf '%s  %s\n' "${updates_repomd_sha256}" /tmp/fedora-updates-repomd.xml \
  | sha256sum --check --strict

curl --fail --location --retry 3 --output "${key_file}" "${key_url}"
printf '%s  %s\n' "${key_sha256}" "${key_file}" | sha256sum --check --strict
rpmkeys --import "${key_file}"
rpmkeys --list | grep -Fq "${key_fingerprint} "

install -d -m 0755 "${rpm_directory}"
dnf -y --disablerepo='*' --enablerepo=fedora-release download \
  --destdir="${rpm_directory}" "${release_packages[@]}"
dnf -y --disablerepo='*' --enablerepo=fedora-updates download \
  --destdir="${rpm_directory}" "${updates_packages[@]}"

declare -A downloaded=()
shopt -s nullglob
rpm_paths=("${rpm_directory}"/*.rpm)
[[ "${#rpm_paths[@]}" -eq "${#expected_hashes[@]}" ]]
for rpm_path in "${rpm_paths[@]}"; do
  nevra="$(rpm -qp --qf '%{NAME}-%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}' "${rpm_path}")"
  [[ -n "${expected_hashes[${nevra}]+present}" ]]
  [[ -z "${downloaded[${nevra}]+present}" ]]
  printf '%s  %s\n' "${expected_hashes[${nevra}]}" "${rpm_path}" \
    | sha256sum --check --strict
  rpmkeys --checksig "${rpm_path}"
  downloaded["${nevra}"]=present
done
[[ "${#downloaded[@]}" -eq "${#expected_hashes[@]}" ]]

dnf -y --disablerepo='*' --setopt=install_weak_deps=False install \
  --allowerasing "${rpm_paths[@]}"

rm -f "${key_file}" /tmp/fedora-release-repomd.xml /tmp/fedora-updates-repomd.xml
rm -rf "${rpm_directory}"
dnf clean all
