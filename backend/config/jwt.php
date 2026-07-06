<?php
require_once __DIR__ . '/database.php';

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string {
    return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
}

function generateToken(array $payload): string {
    $header  = base64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64url_encode(json_encode($payload));
    $sig     = base64url_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$sig";
}

function verifyToken(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$header, $payload, $sig] = $parts;
    $expected = base64url_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    if (!hash_equals($expected, $sig)) return null;
    $data = json_decode(base64url_decode($payload), true);
    if (!$data || (isset($data['exp']) && $data['exp'] < time())) return null;
    return $data;
}

function getAuthHeader(): string {
    // Robustly retrieve Authorization header across different SAPI/servers
    if (function_exists('getallheaders')) {
        $h = getallheaders();
        if (!empty($h['Authorization'])) return $h['Authorization'];
        if (!empty($h['authorization'])) return $h['authorization'];
    }
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) return $_SERVER['HTTP_AUTHORIZATION'];
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) return $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    // fallback: look for Authorization in apache_request_headers if available
    if (function_exists('apache_request_headers')) {
        $h = apache_request_headers();
        if (!empty($h['Authorization'])) return $h['Authorization'];
        if (!empty($h['authorization'])) return $h['authorization'];
    }
    return '';
}

function getAuthToken(): string {
    $header = getAuthHeader();
    if (str_starts_with($header, 'Bearer ')) {
        return substr($header, 7);
    }
    if (!empty($_GET['token'])) {
        return trim($_GET['token']);
    }
    if (!empty($_POST['token'])) {
        return trim($_POST['token']);
    }
    return '';
}

function requireAuth(): array {
    $token = getAuthToken();
    if (!$token) {
        jsonResponse(false, 'Token tidak ditemukan', null, 401);
    }
    $payload = verifyToken($token);
    if (!$payload) {
        jsonResponse(false, 'Token tidak valid atau sudah kadaluarsa', null, 401);
    }
    return $payload;
}

function requireAdmin(): array {
    $payload = requireAuth();
    if (($payload['role'] ?? '') !== 'admin') {
        jsonResponse(false, 'Akses ditolak', null, 403);
    }
    return $payload;
}
