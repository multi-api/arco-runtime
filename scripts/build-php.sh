#!/usr/bin/env bash
# Builds a static PHP CLI matching a FrankenPHP static build (same PHP version and extensions, musl, ZTS).
# Usage: scripts/build-php.sh <php-version> <spc-tag> <extensions-csv> <outdir>
# Uses the spc release binary for <spc-tag> (needs gh); options verified against static-php-cli 2.8.5 (spc download/build/doctor).
set -euo pipefail

PHP_VERSION="${1:?php version, e.g. 8.5.11}"
SPC_TAG="${2:?static-php-cli release tag, e.g. 2.8.5}"
EXTS="${3:?comma-separated extensions}"
OUT="${4:?output directory}"

[[ "$PHP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid php version: $PHP_VERSION" >&2; exit 1; }
[[ "$SPC_TAG" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || { echo "invalid spc tag: $SPC_TAG" >&2; exit 1; }
[[ "$EXTS" =~ ^[a-z0-9][a-z0-9_,-]*$ ]] || { echo "invalid extension list: $EXTS" >&2; exit 1; }
# A relative name starting alphanumeric, ./name or an absolute path; never "-" first, never "..".
[[ "$OUT" =~ ^([0-9A-Za-z]|\./|/) && "$OUT" != *..* ]] || { echo "invalid output directory: $OUT" >&2; exit 1; }
[[ "$(uname -s)/$(uname -m)" == "Linux/aarch64" ]] || { echo "must run on Linux aarch64" >&2; exit 1; }

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# spc's self-contained release binary (no PHP or Composer needed), checked against the release's own digest.
SPC_ASSET="spc-linux-aarch64.tar.gz"
echo "Downloading static-php-cli $SPC_TAG ($SPC_ASSET)"
gh release download "$SPC_TAG" --repo crazywhalecc/static-php-cli --pattern "$SPC_ASSET" --dir "$WORK"
EXPECTED="$(gh api "repos/crazywhalecc/static-php-cli/releases/tags/$SPC_TAG" --jq ".assets[] | select(.name==\"$SPC_ASSET\") | .digest")"
ACTUAL="sha256:$(sha256sum "$WORK/$SPC_ASSET" | cut -d' ' -f1)"
[[ -n "$EXPECTED" && "$ACTUAL" == "$EXPECTED" ]] || { echo "$SPC_ASSET digest $ACTUAL != release digest $EXPECTED" >&2; exit 1; }
[[ "$(tar -tzf "$WORK/$SPC_ASSET")" == "spc" ]] || { echo "unexpected $SPC_ASSET layout (expected a single spc file)" >&2; exit 1; }
tar -xzf "$WORK/$SPC_ASSET" -C "$WORK" spc
rm "$WORK/$SPC_ASSET"
[[ -f "$WORK/spc" && -x "$WORK/spc" ]] || { echo "spc is not an executable file" >&2; exit 1; }

# The spc binary uses the current directory for buildroot/, source/ and downloads/.
cd "$WORK"
./spc doctor --auto-fix
./spc download --with-php="$PHP_VERSION" --for-extensions="$EXTS" --prefer-pre-built --retry 5
SPC_LIBC=musl ./spc build "$EXTS" --build-cli --enable-zts --disable-opcache-jit

cp buildroot/bin/php "$OUT/php-linux-aarch64"
chmod 0755 "$OUT/php-linux-aarch64"
BUILT_VERSION="$("$OUT/php-linux-aarch64" -n -r 'echo PHP_VERSION;')"
[[ "$BUILT_VERSION" == "$PHP_VERSION" ]] || { echo "built PHP $BUILT_VERSION, expected $PHP_VERSION" >&2; exit 1; }
echo "Built $OUT/php-linux-aarch64 ($(wc -c < "$OUT/php-linux-aarch64") bytes)"
