<?php declare(strict_types=1);
// Usage: php scripts/parity.php <frankenphp-inspect.json> <php-inspect.json>
// Exits 1 unless the PHP CLI has FrankenPHP's PHP version and exactly its extensions (minus frankenphp-cli).

function fail(string $message): never
{
    fwrite(STDERR, $message . "\n");
    exit(1);
}

/** @return array{php: string, extensions: list<string>} */
function load(string $file): array
{
    $json = @file_get_contents($file);
    if ($json === false) {
        fail("cannot read $file");
    }
    try {
        $data = json_decode($json, true, flags: JSON_THROW_ON_ERROR);
    } catch (JsonException $e) {
        fail("invalid JSON in $file: {$e->getMessage()}");
    }
    if (!is_array($data) || !is_string($data['php'] ?? null)) {
        fail("$file: php must be a string");
    }
    $extensions = $data['extensions'] ?? null;
    if (!is_array($extensions) || !array_is_list($extensions) || array_filter($extensions, 'is_string') !== $extensions) {
        fail("$file: extensions must be a list of strings");
    }

    return ['php' => $data['php'], 'extensions' => $extensions];
}

if ($argc !== 3) {
    fail('usage: php scripts/parity.php <frankenphp-inspect.json> <php-inspect.json>');
}
$a = load($argv[1]);
$b = load($argv[2]);

$problems = [];
if ($a['php'] !== $b['php']) {
    $problems[] = "PHP version {$b['php']} differs from {$a['php']}";
}
$want = array_values(array_diff($a['extensions'], ['frankenphp-cli']));
$missing = array_values(array_diff($want, $b['extensions']));
$extra = array_values(array_diff($b['extensions'], $want));
if ($missing !== []) {
    $problems[] = 'missing: ' . implode(', ', $missing);
}
if ($extra !== []) {
    $problems[] = 'extra: ' . implode(', ', $extra);
}
if ($problems !== []) {
    fail(implode("\n", $problems));
}
echo "parity ok: PHP {$a['php']}, " . count($want) . " extensions\n";
