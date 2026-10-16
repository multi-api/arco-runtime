<?php declare(strict_types=1);
// Usage: php scripts/parity.php <frankenphp-inspect.json> <php-inspect.json>
// Exits 1 unless the PHP CLI has FrankenPHP's PHP version and exactly its extensions (minus frankenphp-cli).
[$a, $b] = array_map(
    static fn (string $f): array => json_decode((string) file_get_contents($f), true, flags: JSON_THROW_ON_ERROR),
    array_slice($argv, 1, 2),
);
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
    fwrite(STDERR, implode("\n", $problems) . "\n");
    exit(1);
}
echo "parity ok: PHP {$a['php']}, " . count($want) . " extensions\n";
