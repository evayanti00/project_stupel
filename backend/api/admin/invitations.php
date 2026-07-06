<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAdmin();
$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $inv = $db->query('SELECT * FROM invitations ORDER BY created_at DESC')->fetchAll();
    jsonResponse(true, 'OK', $inv);

} elseif ($method === 'POST') {
    $body = getRequestBody();
    $email = trim($body['email'] ?? '');
    if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) jsonResponse(false, 'Email tidak valid');

    // generate token
    $token = bin2hex(random_bytes(16));
    $stmt = $db->prepare('INSERT INTO invitations (email, token, created_by) VALUES (?, ?, ?)');
    $stmt->execute([$email, $token, $payload['user_id']]);

    // in real deployment send email with invitation link including token
    jsonResponse(true, 'Undangan dibuat', ['token' => $token]);

} else {
    jsonResponse(false, 'Method not allowed', null, 405);
}

