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

$stmt = $db->prepare('SELECT id, is_active FROM users WHERE id = ?');
$stmt->execute([$id]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(false, 'User tidak ditemukan');
}

$newStatus = ((int)($user['is_active'] ?? 1) === 1) ? 0 : 1;
$db->prepare('UPDATE users SET is_active = ? WHERE id = ?')->execute([$newStatus, $id]);
jsonResponse(true, 'Status pengguna diperbarui', ['is_active' => $newStatus]);
