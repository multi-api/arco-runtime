#!/usr/bin/env bash
# Adds the PHP CLI to an Arco runtime build directory: php_cli section in build.json, line in SHA256SUMS.
set -euo pipefail
DIR="${1:?build directory}"; SPC_TAG="${2:?spc tag}"
BIN="$DIR/php-linux-aarch64"
SHA="$(sha256sum "$BIN" | cut -d' ' -f1)"; SIZE="$(wc -c < "$BIN" | tr -d ' ')"
jq --arg sha "$SHA" --argjson size "$SIZE" --arg spc "$SPC_TAG" --slurpfile i "$DIR/php-inspect.json" \
  '.php_cli = {sha256: $sha, size: $size, spc: $spc, extensions: $i[0].extensions}' \
  "$DIR/build.json" > "$DIR/build.json.new"
mv "$DIR/build.json.new" "$DIR/build.json"
echo "$SHA  php-linux-aarch64" >> "$DIR/SHA256SUMS"
