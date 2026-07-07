<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAdmin();
$db = getDB();
$body = getRequestBody();
$id = (int)($body['id'] ?? 0);

if (!$id) {
    jsonResponse(false, 'ID pengguna tidak valid');
}

$stmt = $db->prepare('SELECT id, email FROM users WHERE id = ?');
$stmt->execute([$id]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(false, 'User tidak ditemukan');
}

jsonResponse(true, 'Reset password email telah dipersiapkan', ['email' => $user['email']]);
