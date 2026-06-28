<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAdmin(); // Hanya admin yang bisa akses

$db   = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Daftar semua user
    $users = $db->query('SELECT id, name, email, role, created_at FROM users ORDER BY id')->fetchAll();
    jsonResponse(true, 'OK', $users);

} elseif ($method === 'POST') {
    // Tambah user
    $body     = getRequestBody();
    $name     = trim($body['name'] ?? '');
    $email    = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';
    $role     = $body['role'] ?? 'user';

    if (!$name || !$email || !$password) jsonResponse(false, 'Data tidak lengkap');

    $stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
    $stmt->execute([$email]);
    if ($stmt->fetch()) jsonResponse(false, 'Email sudah terdaftar');

    $hash = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $db->prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)');
    $stmt->execute([$name, $email, $hash, $role]);
    jsonResponse(true, 'User berhasil dibuat');

} elseif ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) jsonResponse(false, 'ID tidak valid');

    $stmt = $db->prepare('DELETE FROM users WHERE id = ? AND role != "admin"');
    $stmt->execute([$id]);
    if ($stmt->rowCount() === 0) jsonResponse(false, 'User tidak ditemukan');
    jsonResponse(true, 'User berhasil dihapus');
} else {
    jsonResponse(false, 'Method not allowed', null, 405);
}
