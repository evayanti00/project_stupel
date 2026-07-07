<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';
require_once __DIR__ . '/../../config/mail.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST' && $method !== 'GET') {
    jsonResponse(false, 'Method not allowed', null, 405);
}

$body = getRequestBody();
$email = trim($body['email'] ?? '');
$newPassword = $body['new_password'] ?? '';
$token = trim($body['token'] ?? '');

if (!$email) {
    $email = trim($_GET['email'] ?? '');
}
if (!$token) {
    $token = trim($_GET['token'] ?? '');
}
if (!$newPassword && isset($_POST['new_password'])) {
    $newPassword = $_POST['new_password'];
}

if (!$email) {
    if ($method === 'GET') {
        echo '<p>Email harus diisi.</p>';
        exit;
    }
    jsonResponse(false, 'Email harus diisi');
}

$db = getDB();
$stmt = $db->prepare('SELECT id, reset_token, reset_expires_at FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    if ($method === 'GET') {
        echo '<p>Email tidak ditemukan.</p>';
        exit;
    }
    jsonResponse(false, 'Email tidak ditemukan');
}

if ($newPassword) {
    if (strlen($newPassword) < 6) {
        if ($method === 'GET') {
            echo '<p>Password minimal 6 karakter.</p>';
            exit;
        }
        jsonResponse(false, 'Password minimal 6 karakter');
    }
    if ($token && $token !== ($user['reset_token'] ?? '')) {
        if ($method === 'GET') {
            echo '<p>Token reset password tidak valid.</p>';
            exit;
        }
        jsonResponse(false, 'Token reset password tidak valid');
    }
    $hash = password_hash($newPassword, PASSWORD_BCRYPT);
    $db->prepare('UPDATE users SET password = ?, reset_token = NULL, reset_expires_at = NULL WHERE id = ?')->execute([$hash, $user['id']]);
    if ($method === 'GET') {
        echo '<h3>Password berhasil diperbarui</h3><p>Anda dapat masuk kembali ke aplikasi.</p>';
        exit;
    }
    jsonResponse(true, 'Password berhasil diperbarui');
}

if ($method === 'GET' && $token) {
    echo '<form method="POST" action="reset-password.php">';
    echo '<input type="hidden" name="email" value="' . htmlspecialchars($email) . '">';
    echo '<input type="hidden" name="token" value="' . htmlspecialchars($token) . '">';
    echo '<label>Password Baru</label><input type="password" name="new_password" required><br><br>';
    echo '<button type="submit">Simpan Password</button>';
    echo '</form>';
    exit;
}

$resetToken = bin2hex(random_bytes(16));
$expiresAt = date('Y-m-d H:i:s', strtotime('+1 hour'));
$db->prepare('UPDATE users SET reset_token = ?, reset_expires_at = ? WHERE id = ?')->execute([$resetToken, $expiresAt, $user['id']]);
$link = 'http://localhost/project_stupel/backend/api/auth/reset-password.php?email=' . urlencode($email) . '&token=' . $resetToken;
$message = '<p>Halo,</p><p>Silakan klik tautan berikut untuk mengatur password baru:</p><p><a href="' . $link . '">' . $link . '</a></p>';
sendMail($email, 'Reset Password STUPEL', $message);

if ($method === 'GET') {
    echo '<p>Link reset password telah dikirim.</p>';
    exit;
}
jsonResponse(true, 'Reset password diproses. Silakan cek email Anda.');
