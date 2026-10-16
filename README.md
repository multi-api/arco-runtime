# arco-runtime

Immutable FrankenPHP runtime builds for [Arco](https://github.com/multi-api/arco), which deploys PHP/Laravel apps to AWS Lambda Web Functions. Each release mirrors the official static FrankenPHP `linux-aarch64` binary after verifying its GitHub attestation and upstream digest, then re-attests it from this repository.

## Build id scheme

`<frankenphp-version>-r<revision>`, for example `1.13.0-r1`. The release tag is `frankenphp-1.13.0-r1`. Each release contains `frankenphp-linux-aarch64`, `php-linux-aarch64` (a static PHP CLI with the same PHP version and extensions), `SHA256SUMS` and `build.json` (version, PHP version, sha256, size, origin, extensions, and `php_cli`: sha256, size, spc tag, extensions).

## Publishing a build

`spc_tag` is the static-php-cli release used to build the PHP CLI. `extensions` is `defaultExtensions` from FrankenPHP's `build-static.sh` at the release tag (`gh api "repos/php/frankenphp/contents/build-static.sh?ref=v1.13.0" --jq .content | base64 -d | grep ^defaultExtensions=`).

Dry run (builds and verifies, uploads the result as a workflow artifact only):

```bash
gh workflow run publish.yml -f frankenphp_version=1.13.0 -f revision=1 -f spc_tag=2.8.5 \
  -f extensions=amqp,apcu,ast,bcmath,brotli,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,ftp,gd,gmp,gettext,iconv,igbinary,imagick,intl,ldap,lz4,mbregex,mbstring,memcached,mysqli,mysqlnd,opcache,openssl,password-argon2,parallel,pcntl,pdo,pdo_mysql,pdo_pgsql,pdo_sqlite,pgsql,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,xsl,xz,zip,zlib,yaml,zstd -f publish=false
```

Publish (creates the release and attestation):

```bash
gh workflow run publish.yml -f frankenphp_version=1.13.0 -f revision=1 -f spc_tag=2.8.5 \
  -f extensions=amqp,apcu,ast,bcmath,brotli,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,ftp,gd,gmp,gettext,iconv,igbinary,imagick,intl,ldap,lz4,mbregex,mbstring,memcached,mysqli,mysqlnd,opcache,openssl,password-argon2,parallel,pcntl,pdo,pdo_mysql,pdo_pgsql,pdo_sqlite,pgsql,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,xsl,xz,zip,zlib,yaml,zstd -f publish=true
```

The workflow has three jobs. `build-php` runs with a read-only token: it builds the PHP CLI with `scripts/build-php.sh` (static-php-cli) and uploads only that binary. `verify` also runs with a read-only token and never runs build code: it downloads the upstream binary, verifies its attestation, smoke-tests it, then takes the PHP CLI from `build-php`, checks parity (`scripts/parity.php`, run by the runner's PHP), runs the CLI in `public.ecr.aws/lambda/provided:al2023`, enforces a 100 MB size gate, records the CLI's sha256 as a job output, and uploads both binaries, `SHA256SUMS` and `build.json` as a workflow artifact. `publish` (only when `publish=true`) holds the write and OIDC permissions but never executes the binary: it re-verifies the upstream attestation, cross-checks sha256, size, digest and build id (and the PHP CLI's sha256, size and spc tag) against `build.json`, checks the PHP CLI's sha256 against the `verify` job output, re-checks that the tag is free, then attests and creates the release. Runs for the same build id are serialized.

You can also run `scripts/mirror.sh <version> <revision> <outdir>` locally (needs `gh`, `jq`, and Docker on non-arm64-Linux hosts).

## Immutability rule

Never delete or replace a release. If anything needs to change, publish a new revision (`-r2`, ...). The workflow refuses to overwrite an existing tag.

## Verifying a download

```bash
gh attestation verify frankenphp-linux-aarch64 --repo multi-api/arco-runtime --signer-workflow multi-api/arco-runtime/.github/workflows/publish.yml
gh attestation verify php-linux-aarch64 --repo multi-api/arco-runtime --signer-workflow multi-api/arco-runtime/.github/workflows/publish.yml
```

## PHP CLI build and parity check

`scripts/build-php.sh <php-version> <spc-tag> <extensions-csv> <outdir>` builds a static PHP CLI (`<outdir>/php-linux-aarch64`) with [static-php-cli](https://github.com/crazywhalecc/static-php-cli): musl, ZTS, opcache JIT disabled. It only runs on Linux aarch64 (needs `git`, `composer`, `php`).

`php scripts/parity.php <frankenphp-inspect.json> <php-inspect.json>` checks that the CLI has FrankenPHP's PHP version and exactly its extensions (minus `frankenphp-cli`). Both inputs are the output of `scripts/inspect.php`.

Run the parity tests (needs `php`):

```bash
bash tests/parity-test.sh
bash tests/build-php-args-test.sh
bash tests/add-php-cli-test.sh
```
