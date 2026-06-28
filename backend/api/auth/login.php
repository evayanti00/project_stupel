<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed', null, 405);
}

$body     = getRequestBody();
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';

if (!$email || !$password) {
    jsonResponse(false, 'Email dan password harus diisi');
}

$db   = getDB();
$stmt = $db->prepare('SELECT * FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    jsonResponse(false, 'Email atau password salah', null, 401);
}

$token = generateToken([
    'user_id' => $user['id'],
    'email'   => $user['email'],
    'role'    => $user['role'],
    'exp'     => time() + (60 * 60 * 24 * 7), // 7 hari
]);

jsonResponse(true, 'Login berhasil', [
    'token' => $token,
    'user'  => [
        'id'    => $user['id'],
        'name'  => $user['name'],
        'email' => $user['email'],
        'role'  => $user['role'],
    ],
]);
