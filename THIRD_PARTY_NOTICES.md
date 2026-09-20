# Third-Party Notices

This inventory covers third-party material copied into the repository, included
in the harness image, or invoked only by its GitHub Actions workflow. Package
licenses installed by RPM remain available under `/usr/share/licenses` in the
image.

## Hummingbird base image

- **Affected path:** `container/Containerfile` and the resulting image.
- **Source:** `registry.access.redhat.com/hi/core-runtime` version 2.43 builder,
  OCI index digest
  `sha256:d939459917ebea5ea4f31187050959ad5cc833c6554b54080ebafd0c4142212c`;
  upstream source is <https://gitlab.com/redhat/hummingbird/containers> revision
  `ff8f5060c8fb0c3354400626864fe5866d429e13`.
- **Integrity:** digest-selected OCI index; its `linux/amd64` child manifest is
  `sha256:c6880ce5a0f2a9e025c0bf22c546aacbf8ddb60833ea2baa5fa36a5fadfd37e3`.
- **License:** Red Hat terms referenced by image metadata at
  <https://www.redhat.com/en/about-red-hat-end-user-license-agreements#UBI>.
- **Attribution and use:** the image metadata identifies Red Hat and Project
  Hummingbird. The base and its RPM contents are redistributed in the harness
  image; their installed notices are retained.
- **Material modifications:** none to the base layers; this project adds later
  image layers.

## Hummingbird direct RPM packages

- **Affected path:** `container/Containerfile` and the resulting image.
- **Source:** Hummingbird's signed x86_64 RPM repository at
  <https://packages.redhat.com/api/pulp-content/public-hummingbird/x86_64/>.
- **Versions:** fontconfig `0:2.18.3-1.hum1`, Git `0:2.55.0-2.hum1`,
  glibc-gconv-extra `0:2.43-8.5.hum1`, gzip `0:1.14-4.hum1`, tar
  `2:1.35-10.hum1`, and xz `1:5.8.3-2.hum1`.
- **Integrity:** exact NEVRA pins; DNF package-signature verification is enabled
  with the repository key at
  `/etc/pki/rpm-gpg/RPM-GPG-KEY-hummingbird-release`. Each installed direct RPM
  reports RSA/SHA-256 key ID `199e2f91fd431d51`.
- **Licenses:** fontconfig uses HPND, Fedora's public-domain license reference,
  and Unicode-DFS-2016; Git uses BSD-3-Clause, GPL-2.0-only,
  GPL-2.0-or-later, LGPL-2.1-or-later, and MIT; gzip uses GPL-3.0-or-later and
  GFDL-1.3-only; glibc-gconv-extra carries glibc's composite RPM license
  expression, including LGPL, GPL, BSD, ISC, MIT, Unicode, GFDL, HPND, X11,
  public-domain, and named exception terms; tar uses GPL-3.0-or-later; xz uses
  0BSD, GPL-2.0-or-later, and Fedora's public-domain license reference.
- **Attribution and use:** all six packages are redistributed inside the image.
  Their RPM-installed copyright and license notices are retained under
  `/usr/share/licenses` and `/usr/share/doc` where supplied.
- **Material modifications:** none to the RPM payloads.

## Fedora 43 signing key and RPM packages

- **Affected paths:** `container/repositories/fedora-43.repo`,
  `container/fedora-43-amd64.lock`, `container/Containerfile`, and the resulting
  image.
- **Sources:** the build retrieves the key from
  <https://src.fedoraproject.org/rpms/fedora-repos/raw/f43/f/RPM-GPG-KEY-fedora-43-primary>;
  packages come only from Fedora 43 Everything's signed
  [release](https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/)
  and [updates](https://dl.fedoraproject.org/pub/fedora/linux/updates/43/Everything/x86_64/)
  repositories.
- **Versions:** Chromium Headless and Chromium Common `153.0.8010.36-1.fc43`,
  ImageMagick `1:7.1.2.27-1.fc43`, Tesseract `5.5.3-1.fc43`, English Tesseract
  data `4.1.0-11.fc43`, jq `1.8.1-3.fc43`, ttyd `1.7.7-7.fc43`, ffmpeg-free
  `7.1.5-1.fc43`, VHS `0.10.0-4.fc43`, and the complete 344-RPM transaction
  closure recorded by exact NEVRA, SHA-256, and source repository in
  `container/fedora-43-amd64.lock`.
- **Integrity:** key SHA-256
  `2b1449a082d3264dda8e18369f04e9ac4163bf3f8cb530b0783dc2ab064a08ec`;
  verified key fingerprint `C6E7 F081 CF80 E131 4667 6E88 829B 6066 3164
  5531`; pinned release and updates `repomd.xml` SHA-256 values; per-RPM
  SHA-256 values; and RPM signatures enforced with `gpgcheck=1`.
- **Signing-key license:** Fedora package metadata lists the `fedora-repos`
  source and its `fedora-gpg-keys` subpackage as MIT, but the public-key file
  has no file-specific license or attribution notice. This inventory records
  package-level provenance without asserting that MIT relicenses the key bytes.
  The verified key is imported and the temporary downloaded file is removed in
  the same build layer; the repository and final image do not redistribute the
  key file.
- **Licenses:** Chromium has BSD, LGPL, Apache, IJG, MIT, GPL, ISC, OpenSSL,
  and tri-licensed components; ImageMagick uses the ImageMagick license;
  Tesseract and its English data use Apache-2.0; jq uses MIT, ICU, and
  CC-BY-3.0; ttyd uses MIT; ffmpeg-free uses GPL-3.0-or-later. Package notices
  installed by the signed RPMs are retained in the redistributed image.
- **Material modifications:** the key bytes and RPM payloads are not modified.
  Full Chromium is replaced by Fedora's matching headless package, exposed under
  the command name expected by the harness.

## Fedora VHS and runtime dependencies

- **Affected path:** `container/Containerfile` and the resulting image.
- **Source and version:** Fedora 43 updates VHS `0.10.0-4.fc43`; official
  package metadata is at
  <https://packages.fedoraproject.org/pkgs/vhs/vhs/fedora-43.html>.
- **Integrity:** exact EVR and x86_64 architecture, installed through the signed
  Fedora repositories. The direct runtime dependencies are ffmpeg-free, glibc,
  and ttyd. glibc comes from the pinned Hummingbird base and direct package set;
  the complete remaining 344-package Fedora closure is recorded in
  `container/fedora-43-amd64.lock`.
- **Licenses:** Apache-2.0, BSD-3-Clause, MIT, MPL-2.0, and OFL-1.1 components.
  VHS and its dependencies are redistributed in the image with RPM-installed
  notices preserved.
- **Material modifications:** none to the RPM payloads.

## Nerd Fonts Iosevka

- **Affected paths:** `container/install-font.sh`,
  `container/licenses/Iosevka-OFL-1.1.txt`, and fonts installed under
  `/usr/local/share/fonts/iosevka-nerd-font-mono` in the resulting image.
- **Source and version:** Nerd Fonts `v3.5.1`, asset `Iosevka.tar.xz`, from
  <https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.5.1>.
- **Integrity:** SHA-256
  `3b94ea1dc3955756762f977b7677bca671947dd56bc755a6f8465a8e83b5f257`,
  matching the release's `SHA-256.txt`.
- **License and attribution:** SIL Open Font License 1.1; copyright
  2015–2023 Renzhi Li (Belleve Invis). The required copyright and full license
  are copied from the versioned upstream notice and redistributed in the image.
- **Material modifications:** the verified archive contains 27 files in each of
  its Mono, proportional, and non-Mono families. The build copies only the Mono
  Regular, Bold, Italic, and Bold Italic files byte-for-byte and excludes the
  other 77 files; the selected files themselves are not modified.

## GitHub Actions

All entries affect `.github/workflows/harness-image.yml`. They are invoked only
during CI, are not copied into the harness image, and are not materially
modified. Each integrity mechanism is a full Git commit SHA verified against
the listed upstream release. Because this project does not redistribute their
code, upstream action distributions retain their own required notices.

| Action and source | Commit | Release | License and attribution |
| --- | --- | --- | --- |
| [`actions/checkout`](https://github.com/actions/checkout) | `3d3c42e5aac5ba805825da76410c181273ba90b1` | `v7.0.1` | MIT; retain the GitHub copyright and MIT notice if redistributed. |
| [`docker/login-action`](https://github.com/docker/login-action) | `dbcb813823bdd20940b903addbd779551569679f` | `v4.6.0` | Apache-2.0; retain its license, notices, and attribution if redistributed. |
| [`docker/setup-buildx-action`](https://github.com/docker/setup-buildx-action) | `f87e5991a6d7451dcb8d9637bfbc97413f497069` | `v4.4.1` | Apache-2.0; retain its license, notices, and attribution if redistributed. |
| [`docker/metadata-action`](https://github.com/docker/metadata-action) | `dc802804100637a589fabce1cb79ff13a1411302` | `v6.2.0` | Apache-2.0; retain its license, notices, and attribution if redistributed. |
| [`docker/build-push-action`](https://github.com/docker/build-push-action) | `c3c9e263c25d99ce0380d002d59b67737d91b0dc` | `v7.4.0` | Apache-2.0; retain its license, notices, and attribution if redistributed. |
| [`actions/attest`](https://github.com/actions/attest) | `1e69f48acb82d1966a394da916b4c1698aa569d6` | `v4.2.2` | MIT; retain the GitHub copyright and MIT notice if redistributed. |
| [`anchore/scan-action`](https://github.com/anchore/scan-action) | `27805bf3b4e84b4a5c980df22ed233c00390a439` | `v7.4.2` | MIT; retain the Anchore copyright and MIT notice if redistributed. |
