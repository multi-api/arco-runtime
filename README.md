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

You can also run `scripts/mirror.sh <version> <revision> <outdir>` locally (needs `gh`, `jq`, and Docker on non-arm64-Linux hosts).

## Immutability rule

Never delete or replace a release. If anything needs to change, publish a new revision (`-r2`, ...). The workflow refuses to overwrite an existing tag.

## Verifying a download

```bash
gh attestation verify frankenphp-linux-aarch64 --repo multi-api/arco-runtime
```
