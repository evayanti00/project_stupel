<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed', null, 405);
}

$body = getRequestBody();
$name     = trim($body['name'] ?? '');
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';
$inviteToken = trim($body['token'] ?? '');
$balance  = isset($body['balance']) ? (float)$body['balance'] : 0;

if (!$name || !$email || !$password) {
    jsonResponse(false, 'Semua field harus diisi');
}
if ($balance < 0) {
    jsonResponse(false, 'Saldo awal tidak boleh negatif');
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(false, 'Format email tidak valid');
}
if (strlen($password) < 6) {
    jsonResponse(false, 'Password minimal 6 karakter');
}

$db = getDB();
$stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
$stmt->execute([$email]);
if ($stmt->fetch()) {
    jsonResponse(false, 'Email sudah terdaftar');
}

$isVerified = 1;
if ($inviteToken) {
    $stmt = $db->prepare('SELECT id FROM invitations WHERE token = ? AND email = ? AND status = "pending"');
    $stmt->execute([$inviteToken, $email]);
    if (!$stmt->fetch()) {
        jsonResponse(false, 'Kode undangan tidak valid atau sudah digunakan');
    }
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$stmt = $db->prepare('INSERT INTO users (name, email, password, is_verified, verification_token, balance) VALUES (?, ?, ?, ?, NULL, ?)');
$stmt->execute([$name, $email, $hash, $isVerified, $balance]);

if ($inviteToken) {
    $db->prepare('UPDATE invitations SET status = "used", used_at = NOW() WHERE token = ?')->execute([$inviteToken]);
}

jsonResponse(true, 'Akun berhasil dibuat. Silakan login.');
