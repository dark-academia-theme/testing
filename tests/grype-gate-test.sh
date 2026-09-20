#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "${scratch}"' EXIT

cat > "${scratch}/hummingbird.json" <<'JSON'
{
  "distro": {"name": "hummingbird", "version": "20251124"},
  "matches": [
    {
      "artifact": {"name": "fedora-lib", "version": "1-1.fc43", "type": "rpm", "locations": []},
      "vulnerability": {"id": "CVE-CROSS-H", "severity": "Critical", "fix": {"state": "fixed", "versions": ["2-1.hum1"]}, "knownExploited": []}
    },
    {
      "artifact": {"name": "hummingbird-lib", "version": "1-1.hum1", "type": "rpm", "locations": []},
      "vulnerability": {"id": "CVE-HUM", "severity": "Medium", "fix": {"state": "not-fixed", "versions": []}, "knownExploited": []}
    },
    {
      "artifact": {"name": "stdlib", "version": "go1.25.9", "type": "go-module", "locations": [{"path": "/usr/bin/vhs"}]},
      "vulnerability": {"id": "GO-2026-4918", "severity": "High", "fix": {"state": "fixed", "versions": ["1.25.10"]}, "knownExploited": []}
    }
  ]
}
JSON

cat > "${scratch}/fedora.json" <<'JSON'
{
  "distro": {"name": "fedora", "version": "43"},
  "matches": [
    {
      "artifact": {"name": "fedora-lib", "version": "1-1.fc43", "type": "rpm", "locations": []},
      "vulnerability": {"id": "CVE-FEDORA", "severity": "Medium", "fix": {"state": "not-fixed", "versions": []}, "knownExploited": []}
    },
    {
      "artifact": {"name": "hummingbird-lib", "version": "1-1.hum1", "type": "rpm", "locations": []},
      "vulnerability": {"id": "CVE-CROSS-F", "severity": "Critical", "fix": {"state": "fixed", "versions": ["2-1.fc43"]}, "knownExploited": []}
    }
  ]
}
JSON

gate=(
  "${repo_root}/tests/grype-gate.sh"
  "${scratch}/hummingbird.json"
  "${scratch}/fedora.json"
)
jq '.exceptions[0].ids = ["GO-2026-4918"]' \
  "${repo_root}/tests/grype-exceptions.json" > "${scratch}/exceptions.json"

output="$("${gate[@]}" "${scratch}/exceptions.json")"
grep -Fq 'package_matches=3 unique_vulnerabilities=3' <<< "${output}"
grep -Fq 'excepted_fixable_matches=1 unique=1' <<< "${output}"

jq '.matches[2].vulnerability.id = "GO-NOT-EXCEPTED"' \
  "${scratch}/hummingbird.json" > "${scratch}/unexpected.json"
if "${gate[0]}" "${scratch}/unexpected.json" "${gate[2]}" \
    "${scratch}/exceptions.json" >/dev/null 2>&1; then
  printf 'an unexpected fixable High finding passed the gate\n' >&2
  exit 1
fi

jq '.matches[2].vulnerability.knownExploited = [{"cve": "CVE-KEV"}]' \
  "${scratch}/hummingbird.json" > "${scratch}/kev.json"
if "${gate[0]}" "${scratch}/kev.json" "${gate[2]}" \
    "${scratch}/exceptions.json" >/dev/null 2>&1; then
  printf 'a CISA KEV finding passed through a non-KEV exception\n' >&2
  exit 1
fi

jq '.exceptions[0].expires = "2020-01-01"' \
  "${scratch}/exceptions.json" > "${scratch}/expired.json"
if "${gate[@]}" "${scratch}/expired.json" >/dev/null 2>&1; then
  printf 'an expired vulnerability exception passed the gate\n' >&2
  exit 1
fi

printf 'grype gate tests passed\n'
