#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
F=tests/fixtures
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT
php scripts/parity.php "$F/frankenphp.json" "$F/php-ok.json" > /dev/null
! php scripts/parity.php "$F/frankenphp.json" "$F/php-missing.json" > "$OUT" 2>&1
grep -q "missing: pdo_mysql, Zend OPcache" "$OUT"
! php scripts/parity.php "$F/frankenphp.json" "$F/php-version.json" > "$OUT" 2>&1
grep -q "PHP version 8.5.10 differs from 8.5.11" "$OUT"
echo "parity tests passed"
