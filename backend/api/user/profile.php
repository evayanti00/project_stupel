<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAuth();
$userId  = $payload['user_id'];
$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $stmt = $db->prepare('SELECT id, name, email, role, is_verified, balance, created_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    jsonResponse(true, 'OK', $user);

} elseif ($method === 'PUT') {
    $body = getRequestBody();
    $name = trim($body['name'] ?? '');
    $email = trim($body['email'] ?? '');
    $password = $body['password'] ?? '';
    $balance = isset($body['balance']) ? (float)$body['balance'] : null;

    if (!$name || !$email) jsonResponse(false, 'Data tidak lengkap');
    if ($balance !== null && $balance < 0) jsonResponse(false, 'Saldo tidak boleh negatif');

    // check email uniqueness
    $stmt = $db->prepare('SELECT id FROM users WHERE email = ? AND id != ?');
    $stmt->execute([$email, $userId]);
    if ($stmt->fetch()) jsonResponse(false, 'Email sudah digunakan');

    if ($password) {
        $hash = password_hash($password, PASSWORD_BCRYPT);
        if ($balance !== null) {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, password = ?, balance = ? WHERE id = ?');
            $stmt->execute([$name, $email, $hash, $balance, $userId]);
        } else {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, password = ? WHERE id = ?');
            $stmt->execute([$name, $email, $hash, $userId]);
        }
    } else {
        if ($balance !== null) {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, balance = ? WHERE id = ?');
            $stmt->execute([$name, $email, $balance, $userId]);
        } else {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ? WHERE id = ?');
            $stmt->execute([$name, $email, $userId]);
        }
    }

    $stmt = $db->prepare('SELECT id, name, email, role, is_verified, balance, created_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    jsonResponse(true, 'Profil diperbarui', $user);

} else {
    jsonResponse(false, 'Method not allowed', null, 405);
}


