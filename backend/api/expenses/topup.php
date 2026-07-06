<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(false, 'Method not allowed', null, 405);

$payload = requireAuth();
$userId  = $payload['user_id'];
$body    = getRequestBody();

$amount = (float)($body['amount'] ?? 0);
$operation = isset($body['operation']) && $body['operation'] === 'subtract' ? 'subtract' : 'add';
if ($amount <= 0) {
    jsonResponse(false, 'Nominal harus lebih besar dari 0');
}

$db = getDB();
if ($operation === 'add') {
    $stmt = $db->prepare('UPDATE users SET balance = balance + ? WHERE id = ?');
    $stmt->execute([$amount, $userId]);
} else {
    $stmt = $db->prepare('UPDATE users SET balance = balance - ? WHERE id = ?');
    $stmt->execute([$amount, $userId]);
}

$stmt = $db->prepare('SELECT balance FROM users WHERE id = ?');
$stmt->execute([$userId]);
$balanceRow = $stmt->fetch();
$balance = isset($balanceRow['balance']) ? (float)$balanceRow['balance'] : 0;

jsonResponse(true, 'Saldo berhasil ditambahkan', ['balance' => $balance]);
