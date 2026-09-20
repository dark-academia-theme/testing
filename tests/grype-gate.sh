#!/usr/bin/env bash
set -euo pipefail

usage='usage: grype-gate.sh <hummingbird-report.json> <fedora-report.json> <exceptions.json>'
hummingbird_report="${1:?${usage}}"
fedora_report="${2:?${usage}}"
exceptions="${3:?${usage}}"
today="$(date -u +%F)"
work_directory="$(mktemp -d)"
normalized_report="${work_directory}/normalized.json"
evaluated_report="${work_directory}/evaluated.json"
trap 'rm -rf "${work_directory}"' EXIT

jq -e '
  .distro.name == "hummingbird"
  and (.matches | type == "array")
' "${hummingbird_report}" >/dev/null
jq -e '
  .distro.name == "fedora"
  and .distro.version == "43"
  and (.matches | type == "array")
' "${fedora_report}" >/dev/null
jq -e --arg today "${today}" '
  .schema_version == 1
  and (.exceptions | type == "array")
  and all(
    .exceptions[];
    (.ids | type == "array" and length > 0)
    and (.artifact.name | type == "string" and length > 0)
    and (.artifact.version | type == "string" and length > 0)
    and (.artifact.type | type == "string" and length > 0)
    and (.artifact.location | type == "string" and length > 0)
    and (.expires | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
    and .expires >= $today
  )
  and (
    [.exceptions[].ids[]] as $ids
    | ($ids | length) == ($ids | unique | length)
  )
' "${exceptions}" >/dev/null

for report in "${hummingbird_report}" "${fedora_report}"; do
  unknown_rpm_matches="$(
    jq '[
      .matches[]
      | select(.artifact.type == "rpm")
      | select(.artifact.version | test("\\.(fc43|hum[0-9]+)(\\.|$)") | not)
    ] | length' "${report}"
  )"
  if ((unknown_rpm_matches > 0)); then
    printf 'cannot classify %d RPM matches by source distribution in %s\n' \
      "${unknown_rpm_matches}" "${report}" >&2
    exit 1
  fi
done

jq -n \
  --slurpfile hummingbird "${hummingbird_report}" \
  --slurpfile fedora "${fedora_report}" '
  {
    matches: [
      $hummingbird[0].matches[]
      | select(
          .artifact.type != "rpm"
          or (.artifact.version | test("\\.hum[0-9]+(\\.|$)"))
        )
    ] + [
      $fedora[0].matches[]
      | select(
          .artifact.type == "rpm"
          and (.artifact.version | test("\\.fc43(\\.|$)"))
        )
    ]
  }
' > "${normalized_report}"

jq --slurpfile exception_config "${exceptions}" '
  def fixable_critical_high:
    (.vulnerability.severity == "Critical" or .vulnerability.severity == "High")
    and (
      .vulnerability.fix.state == "fixed"
      or ((.vulnerability.fix.versions // []) | length > 0)
    );
  def kev:
    ((.vulnerability.knownExploited // []) | length) > 0;
  [
    $exception_config[0].exceptions[] as $exception
    | $exception.ids[]
    | {
        id: ., name: $exception.artifact.name,
        version: $exception.artifact.version,
        type: $exception.artifact.type,
        location: $exception.artifact.location,
        expires: $exception.expires
      }
  ] as $allowed
  | .matches |= map(
      . as $match
      | (fixable_critical_high) as $fixable
      | (kev) as $kev
      | . + {
          _policy: {
            fixable: $fixable,
            kev: $kev,
            excepted: (
              $fixable
              and ($kev | not)
              and any(
                $allowed[];
                .id == $match.vulnerability.id
                and .name == $match.artifact.name
                and .version == $match.artifact.version
                and .type == $match.artifact.type
                and (
                  .location as $location
                  | any($match.artifact.locations[]?; .path == $location)
                )
              )
            )
          }
        }
    )
' "${normalized_report}" > "${evaluated_report}"

configured_exception_ids="$(jq '[.exceptions[].ids[]] | length' "${exceptions}")"
matched_exception_ids="$(
  jq '[.matches[] | select(._policy.excepted) | .vulnerability.id] | unique | length' \
    "${evaluated_report}"
)"
if ((matched_exception_ids != configured_exception_ids)); then
  printf 'configured exceptions=%d but exact current matches=%d\n' \
    "${configured_exception_ids}" "${matched_exception_ids}" >&2
  exit 1
fi

package_matches="$(jq '.matches | length' "${evaluated_report}")"
unique_vulnerabilities="$(
  jq '[.matches[].vulnerability.id] | unique | length' "${evaluated_report}"
)"
fixable_matches="$(
  jq '[.matches[] | select(._policy.fixable)] | length' "${evaluated_report}"
)"
fixable_unique="$(
  jq '[.matches[] | select(._policy.fixable) | .vulnerability.id] | unique | length' \
    "${evaluated_report}"
)"
kev_matches="$(
  jq '[.matches[] | select(._policy.kev)] | length' "${evaluated_report}"
)"
kev_unique="$(
  jq '[.matches[] | select(._policy.kev) | .vulnerability.id] | unique | length' \
    "${evaluated_report}"
)"
excepted_matches="$(
  jq '[.matches[] | select(._policy.excepted)] | length' "${evaluated_report}"
)"
excepted_unique="$(
  jq '[.matches[] | select(._policy.excepted) | .vulnerability.id] | unique | length' \
    "${evaluated_report}"
)"
blocking_matches="$(
  jq '[
    .matches[]
    | select((._policy.fixable or ._policy.kev) and (._policy.excepted | not))
  ] | length' "${evaluated_report}"
)"

printf 'package_matches=%s unique_vulnerabilities=%s\n' \
  "${package_matches}" "${unique_vulnerabilities}"
printf 'fixable_critical_high_matches=%s unique=%s\n' \
  "${fixable_matches}" "${fixable_unique}"
printf 'cisa_kev_matches=%s unique=%s\n' "${kev_matches}" "${kev_unique}"
printf 'excepted_fixable_matches=%s unique=%s\n' \
  "${excepted_matches}" "${excepted_unique}"

if ((excepted_matches > 0)); then
  printf 'active vulnerability exceptions:\n'
  jq -r '
    .matches[]
    | select(._policy.excepted)
    | [
        .vulnerability.id,
        .vulnerability.severity,
        .artifact.name,
        .artifact.version,
        ((.artifact.locations // []) | map(.path) | join(","))
      ]
    | @tsv
  ' "${evaluated_report}"
fi

if ((blocking_matches > 0)); then
  jq -r '
    .matches[]
    | select((._policy.fixable or ._policy.kev) and (._policy.excepted | not))
    | [
        .vulnerability.id,
        .vulnerability.severity,
        .artifact.name,
        .artifact.version,
        (.vulnerability.fix.state // "unknown"),
        ((.vulnerability.knownExploited // []) | length | tostring)
      ]
    | @tsv
  ' "${evaluated_report}"
  exit 1
fi
