# Testing Infrastructure

## Purpose

Own reusable test infrastructure for Dark Academia application-theme
repositories. The first component is the development-only terminal theme
harness image published as `ghcr.io/dark-academia-theme/theme-harness`.

## Boundaries

- This repository owns shared image construction, package provenance, smoke
  tests, and publication automation.
- Application repositories own application binaries, fixtures, theme-discovery
  behavior, screenshots, and application assertions.
- Consumers pin released images by digest.
- The image is test infrastructure, not a production runtime.
- Do not add generic tooling without an identified testing use case and an
  explicit ownership decision.

## Language

**Theme harness image**:
The shared, development-only terminal capture runtime built by this repository.
It contains common tools but no application under test.

**Harness smoke test**:
The local end-to-end check that exercises VHS, Chromium, FFmpeg, ImageMagick,
Tesseract, and the installed terminal font through a real PNG capture.

**Consumer**:
An application-theme repository that extends a released theme harness image by
immutable digest and adds its own application binary, fixtures, and assertions.
