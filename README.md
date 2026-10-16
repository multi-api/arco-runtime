# arco-runtime

Immutable FrankenPHP runtime builds for [Arco](https://github.com/multi-api/arco), which deploys PHP/Laravel apps to AWS Lambda Web Functions. Each release mirrors the official static FrankenPHP `linux-aarch64` binary after verifying its GitHub attestation and upstream digest, then re-attests it from this repository.

## Build id scheme

`<frankenphp-version>-r<revision>`, for example `1.13.0-r1`. The release tag is `frankenphp-1.13.0-r1`. Each release contains `frankenphp-linux-aarch64`, `SHA256SUMS` and `build.json` (version, PHP version, sha256, size, origin, extensions).

## Publishing a build

Dry run (builds and verifies, uploads the result as a workflow artifact only):

```bash
gh workflow run publish.yml -f frankenphp_version=1.13.0 -f revision=1 -f publish=false
```

Publish (creates the release and attestation):

```bash
gh workflow run publish.yml -f frankenphp_version=1.13.0 -f revision=1 -f publish=true
```

The workflow has two jobs. `verify` runs with a read-only token: it downloads the upstream binary, verifies its attestation, smoke-tests it (the only step that executes the binary) and uploads the binary, `SHA256SUMS` and `build.json` as a workflow artifact. `publish` (only when `publish=true`) holds the write and OIDC permissions but never executes the binary: it re-verifies the upstream attestation, cross-checks sha256, size, digest and build id against `build.json`, re-checks that the tag is free, then attests and creates the release. Runs for the same build id are serialized.

You can also run `scripts/mirror.sh <version> <revision> <outdir>` locally (needs `gh`, `jq`, and Docker on non-arm64-Linux hosts).

## Immutability rule

Never delete or replace a release. If anything needs to change, publish a new revision (`-r2`, ...). The workflow refuses to overwrite an existing tag.

## Verifying a download

```bash
gh attestation verify frankenphp-linux-aarch64 --repo multi-api/arco-runtime --signer-workflow multi-api/arco-runtime/.github/workflows/publish.yml
```

## PHP CLI build and parity check

`scripts/build-php.sh <php-version> <spc-tag> <extensions-csv> <outdir>` builds a static PHP CLI (`<outdir>/php-linux-aarch64`) with [static-php-cli](https://github.com/crazywhalecc/static-php-cli): musl, ZTS, opcache JIT disabled. It only runs on Linux aarch64 (needs `git`, `composer`, `php`).

`php scripts/parity.php <frankenphp-inspect.json> <php-inspect.json>` checks that the CLI has FrankenPHP's PHP version and exactly its extensions (minus `frankenphp-cli`). Both inputs are the output of `scripts/inspect.php`.

Run the parity tests (needs `php`):

```bash
bash tests/parity-test.sh
```
