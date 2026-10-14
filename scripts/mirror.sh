#!/usr/bin/env bash
# Mirrors the official FrankenPHP linux-aarch64 binary as an Arco runtime build.
# Usage: scripts/mirror.sh <frankenphp-version> <revision> <outdir>
set -euo pipefail

VERSION="${1:?frankenphp version, e.g. 1.13.0}"
REVISION="${2:?revision number, e.g. 1}"
OUT="${3:?output directory}"
ASSET="frankenphp-linux-aarch64"
ID="${VERSION}-r${REVISION}"
REQUIRED=(ctype curl dom fileinfo mbstring openssl PDO pdo_mysql pdo_pgsql tokenizer xml)
HERE="$(cd "$(dirname "$0")" && pwd)"

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid version: $VERSION" >&2; exit 1; }
[[ "$REVISION" =~ ^[1-9][0-9]*$ ]] || { echo "invalid revision: $REVISION" >&2; exit 1; }

mkdir -p "$OUT"
rm -f "$OUT/$ASSET" "$OUT/SHA256SUMS" "$OUT/build.json"

echo "Downloading $ASSET from php/frankenphp v$VERSION"
gh release download "v$VERSION" --repo php/frankenphp --pattern "$ASSET" --dir "$OUT"
chmod +x "$OUT/$ASSET"

echo "Verifying GitHub attestation"
gh attestation verify "$OUT/$ASSET" --repo php/frankenphp

run() {
  if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
    "$OUT/$ASSET" "$@"
  else
    docker run --rm --platform linux/arm64 -v "$OUT:/out:ro" -v "$HERE:/scripts:ro" node:24-slim "/out/$ASSET" "${@/#$HERE//scripts}"
  fi
}

VERSION_LINE="$(run version)"
echo "$VERSION_LINE"
[[ "$VERSION_LINE" == "FrankenPHP v$VERSION "* ]] || { echo "unexpected version output" >&2; exit 1; }

INSPECT="$(run php-cli "$HERE/inspect.php")"
for ext in "${REQUIRED[@]}"; do
  echo "$INSPECT" | jq -e --arg e "$ext" '.extensions | index($e)' > /dev/null || { echo "missing extension: $ext" >&2; exit 1; }
done

SHA="$(shasum -a 256 "$OUT/$ASSET" | cut -d' ' -f1)"
SIZE="$(wc -c < "$OUT/$ASSET" | tr -d ' ')"
UPSTREAM_DIGEST="$(gh api "repos/php/frankenphp/releases/tags/v$VERSION" --jq ".assets[] | select(.name == \"$ASSET\") | .digest")"
[[ "$UPSTREAM_DIGEST" == "sha256:$SHA" ]] || { echo "upstream digest $UPSTREAM_DIGEST != sha256:$SHA" >&2; exit 1; }

echo "$SHA  $ASSET" > "$OUT/SHA256SUMS"
echo "$INSPECT" | jq \
  --arg id "$ID" --arg frankenphp "$VERSION" --arg sha "$SHA" --argjson size "$SIZE" \
  --arg digest "$UPSTREAM_DIGEST" --arg release "v$VERSION" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{id: $id, frankenphp: $frankenphp, php: .php, arch: "linux-aarch64", sha256: $sha, size: $size,
    origin: {type: "upstream-mirror", repository: "php/frankenphp", release: $release, asset_digest: $digest, attestation_verified: true},
    extensions: .extensions, published_at: $now}' > "$OUT/build.json"

echo "Build $ID ready in $OUT (sha256 $SHA)"
