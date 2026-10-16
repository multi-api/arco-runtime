#!/usr/bin/env bash
# Argument validation of scripts/build-php.sh (runs before any build, so it works on any host).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT

# expect_reject <expected stderr substring> <build-php.sh args...>
expect_reject() {
  local want="$1"; shift
  local code=0
  bash scripts/build-php.sh "$@" > "$OUT" 2>&1 || code=$?
  if [[ "$code" != 1 ]]; then echo "FAIL: build-php.sh $* exited $code, expected 1" >&2; cat "$OUT" >&2; exit 1; fi
  if ! grep -qF -- "$want" "$OUT"; then echo "FAIL: build-php.sh $* output lacks '$want':" >&2; cat "$OUT" >&2; exit 1; fi
}

expect_reject "invalid php version" 8.5 2.8.5 ctype dist
expect_reject "invalid spc tag" 8.5.11 --help ctype dist
expect_reject "invalid spc tag" 8.5.11 -2.8.5 ctype dist
expect_reject "invalid extension list" 8.5.11 2.8.5 --debug dist
expect_reject "invalid extension list" 8.5.11 2.8.5 ,ctype dist
expect_reject "invalid output directory" 8.5.11 2.8.5 ctype -rf
expect_reject "invalid output directory" 8.5.11 2.8.5 ctype ../dist
if [[ "$(uname -s)/$(uname -m)" != "Linux/aarch64" ]]; then
  # Valid arguments get past validation and stop at the platform check.
  for out in dist ./dist /tmp/dist; do
    expect_reject "must run on Linux aarch64" 8.5.11 2.8.5 ctype,password-argon2,pdo_mysql "$out"
  done
fi
echo "build-php argument tests passed"
