#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
F=tests/fixtures
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT

# expect_fail <expected stderr substring> <parity.php args...>: parity.php must exit 1 and print the message.
expect_fail() {
  local want="$1"; shift
  local code=0
  php scripts/parity.php "$@" > "$OUT" 2>&1 || code=$?
  if [[ "$code" != 1 ]]; then echo "FAIL: parity.php $* exited $code, expected 1" >&2; cat "$OUT" >&2; exit 1; fi
  if ! grep -qF -- "$want" "$OUT"; then echo "FAIL: parity.php $* output lacks '$want':" >&2; cat "$OUT" >&2; exit 1; fi
}

php scripts/parity.php "$F/frankenphp.json" "$F/php-ok.json" > /dev/null
expect_fail "missing: pdo_mysql, Zend OPcache" "$F/frankenphp.json" "$F/php-missing.json"
expect_fail "PHP version 8.5.10 differs from 8.5.11" "$F/frankenphp.json" "$F/php-version.json"
expect_fail "extra: xdebug" "$F/frankenphp.json" "$F/php-extra.json"
expect_fail "usage: php scripts/parity.php" "$F/frankenphp.json"
expect_fail "usage: php scripts/parity.php" "$F/frankenphp.json" "$F/php-ok.json" extra-arg
expect_fail "extensions must be a list of strings" "$F/frankenphp.json" "$F/php-malformed.json"
expect_fail "invalid JSON" "$F/frankenphp.json" "$F/../parity-test.sh"
expect_fail "cannot read" "$F/frankenphp.json" "$F/does-not-exist.json"
echo "parity tests passed"
