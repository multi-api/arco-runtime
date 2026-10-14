<?php
// Run with: frankenphp php-cli inspect.php  — prints PHP version and loaded extensions as JSON.
echo json_encode(['php' => PHP_VERSION, 'extensions' => get_loaded_extensions()], JSON_THROW_ON_ERROR), "\n";
