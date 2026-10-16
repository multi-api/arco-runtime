#!/usr/bin/env bash
# Builds a static PHP CLI matching a FrankenPHP static build (same PHP version and extensions, musl, ZTS).
# Usage: scripts/build-php.sh <php-version> <spc-tag> <extensions-csv> <outdir>
# Options verified against static-php-cli 2.8.5 (spc download/build/doctor).
set -euo pipefail

PHP_VERSION="${1:?php version, e.g. 8.5.11}"
SPC_TAG="${2:?static-php-cli release tag, e.g. 2.8.5}"
EXTS="${3:?comma-separated extensions}"
OUT="${4:?output directory}"

[[ "$PHP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid php version: $PHP_VERSION" >&2; exit 1; }
[[ "$SPC_TAG" =~ ^[0-9A-Za-z._-]+$ ]] || { echo "invalid spc tag: $SPC_TAG" >&2; exit 1; }
[[ "$EXTS" =~ ^[a-z0-9_,-]+$ ]] || { echo "invalid extension list: $EXTS" >&2; exit 1; }
[[ "$(uname -s)/$(uname -m)" == "Linux/aarch64" ]] || { echo "must run on Linux aarch64" >&2; exit 1; }

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Cloning static-php-cli $SPC_TAG"
git clone --depth 1 --branch "$SPC_TAG" https://github.com/crazywhalecc/static-php-cli "$WORK/spc"
cd "$WORK/spc"
composer install --no-dev -a --no-interaction

./bin/spc doctor --auto-fix
./bin/spc download --with-php="$PHP_VERSION" --for-extensions="$EXTS" --prefer-pre-built --retry 5
SPC_LIBC=musl ./bin/spc build "$EXTS" --build-cli --enable-zts --disable-opcache-jit

cp buildroot/bin/php "$OUT/php-linux-aarch64"
chmod 0755 "$OUT/php-linux-aarch64"
echo "Built $OUT/php-linux-aarch64 ($(wc -c < "$OUT/php-linux-aarch64") bytes)"
