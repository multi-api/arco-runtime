#!/usr/bin/env bash
# scripts/add-php-cli.sh adds php_cli to build.json and a line to SHA256SUMS.
set -euo pipefail
cd "$(dirname "$0")/.."
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT

printf 'fake php binary\n' > "$D/php-linux-aarch64"
printf 'fake frankenphp\n' > "$D/frankenphp-linux-aarch64"
(cd "$D" && sha256sum frankenphp-linux-aarch64 > SHA256SUMS)
echo '{"id":"1.13.0-r2","php":"8.5.11","extensions":["Core","frankenphp-cli"]}' > "$D/build.json"
cp tests/fixtures/php-ok.json "$D/php-inspect.json"

bash scripts/add-php-cli.sh "$D" 2.8.5

SHA="$(sha256sum "$D/php-linux-aarch64" | cut -d' ' -f1)"
jq -e --arg sha "$SHA" '
  .php_cli == {sha256: $sha, size: 16, spc: "2.8.5", extensions: ["Core","date","pcre","PDO","pdo_mysql","Zend OPcache"]}
  and .id == "1.13.0-r2" and .php == "8.5.11" and .extensions == ["Core","frankenphp-cli"]
' "$D/build.json" > /dev/null || { echo "FAIL: build.json:" >&2; cat "$D/build.json" >&2; exit 1; }
[[ "$(wc -l < "$D/SHA256SUMS" | tr -d ' ')" == 2 ]] || { echo "FAIL: SHA256SUMS should have 2 lines" >&2; cat "$D/SHA256SUMS" >&2; exit 1; }
(cd "$D" && sha256sum -c SHA256SUMS > /dev/null) || { echo "FAIL: sha256sum -c" >&2; exit 1; }
[[ ! -e "$D/build.json.new" ]] || { echo "FAIL: build.json.new left behind" >&2; exit 1; }
echo "add-php-cli tests passed"
