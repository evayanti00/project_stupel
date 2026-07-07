<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAuth();
$userId  = $payload['user_id'];
$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $stmt = $db->prepare('SELECT id, name, email, role, phone, bio, profile_photo_url, is_verified, balance, created_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    $stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 1');
    $stmt->execute([$userId]);
    $totalTasks = (int)$stmt->fetchColumn();

    $stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 1 AND is_done = 1');
    $stmt->execute([$userId]);
    $completedTasks = (int)$stmt->fetchColumn();

    $stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 0');
    $stmt->execute([$userId]);
    $totalNotes = (int)$stmt->fetchColumn();

    $stmt = $db->prepare('SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ?');
    $stmt->execute([$userId]);
    $totalExpenses = (float)$stmt->fetchColumn();

    jsonResponse(true, 'OK', [
        'user' => $user,
        'stats' => [
            'total_tasks' => $totalTasks,
            'completed_tasks' => $completedTasks,
            'total_notes' => $totalNotes,
            'total_expenses' => $totalExpenses,
        ],
    ]);

} elseif ($method === 'PUT') {
    $body = getRequestBody();
    $name = trim($body['name'] ?? '');
    $email = trim($body['email'] ?? '');
    $phone = trim($body['phone'] ?? '');
    $bio = trim($body['bio'] ?? '');
    $photoUrl = trim($body['profile_photo_url'] ?? '');
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
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, phone = ?, bio = ?, profile_photo_url = ?, password = ?, balance = ? WHERE id = ?');
            $stmt->execute([$name, $email, $phone ?: null, $bio ?: null, $photoUrl ?: null, $hash, $balance, $userId]);
        } else {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, phone = ?, bio = ?, profile_photo_url = ?, password = ? WHERE id = ?');
            $stmt->execute([$name, $email, $phone ?: null, $bio ?: null, $photoUrl ?: null, $hash, $userId]);
        }
    } else {
        if ($balance !== null) {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, phone = ?, bio = ?, profile_photo_url = ?, balance = ? WHERE id = ?');
            $stmt->execute([$name, $email, $phone ?: null, $bio ?: null, $photoUrl ?: null, $balance, $userId]);
        } else {
            $stmt = $db->prepare('UPDATE users SET name = ?, email = ?, phone = ?, bio = ?, profile_photo_url = ? WHERE id = ?');
            $stmt->execute([$name, $email, $phone ?: null, $bio ?: null, $photoUrl ?: null, $userId]);
        }
    }

    $stmt = $db->prepare('SELECT id, name, email, role, phone, bio, profile_photo_url, is_verified, balance, created_at FROM users WHERE id = ?');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    jsonResponse(true, 'Profil diperbarui', $user);

} else {
    jsonResponse(false, 'Method not allowed', null, 405);
}


