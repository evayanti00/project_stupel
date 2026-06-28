<?php
define('DB_HOST', 'localhost');
define('DB_NAME', 'stupel_db');
define('DB_USER', 'root');
define('DB_PASS', '');
define('JWT_SECRET', 'stupel_secret_key_2024_ganti_ini');

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
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
