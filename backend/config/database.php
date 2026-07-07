<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'stupel_db');
define('DB_USER', 'root');
define('DB_PASS', '');
define('JWT_SECRET', 'stupel_secret_key_2024_ganti_ini');

function ensureUserColumns(PDO $pdo): void {
    $statements = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active TINYINT(1) NOT NULL DEFAULT 1",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_token VARCHAR(255) NULL",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token VARCHAR(255) NULL",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_expires_at DATETIME NULL",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(30) NULL",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT NULL",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT NULL",
    ];

    foreach ($statements as $sql) {
        try {
            $pdo->exec($sql);
        } catch (PDOException $e) {
            // Ignore if the column already exists or the server doesn't support this syntax.
        }
    }
}

function ensureNoteColumns(PDO $pdo): void {
    $statements = [
        "ALTER TABLE notes ADD COLUMN IF NOT EXISTS images TEXT NULL",
        "ALTER TABLE notes ADD COLUMN IF NOT EXISTS description TEXT NULL",
        "ALTER TABLE notes ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NULL",
        "ALTER TABLE notes ADD COLUMN IF NOT EXISTS status VARCHAR(30) NULL",
    ];

    foreach ($statements as $sql) {
        try {
            $pdo->exec($sql);
        } catch (PDOException $e) {
            // Ignore if the column already exists or the server doesn't support this syntax.
        }
    }
}

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        ensureUserColumns($pdo);
        ensureNoteColumns($pdo);
    }
    return $pdo;
}

function jsonResponse(bool $success, string $message, $data = null, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json');
    $res = ['success' => $success, 'message' => $message];
    if ($data !== null) $res['data'] = $data;
    echo json_encode($res);
    exit;
}

function getRequestBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}
