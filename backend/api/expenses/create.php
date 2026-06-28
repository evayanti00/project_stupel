<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(false, 'Method not allowed', null, 405);

$payload = requireAuth();
$userId  = $payload['user_id'];
$body    = getRequestBody();

$desc     = trim($body['description'] ?? '');
$amount   = (float)($body['amount'] ?? 0);
$category = trim($body['category'] ?? '');
$date     = $body['date'] ?? date('Y-m-d');

if (!$desc || $amount <= 0 || !$category) {
    jsonResponse(false, 'Deskripsi, nominal, dan kategori harus diisi');
}

$db   = getDB();
$stmt = $db->prepare(
    'INSERT INTO expenses (user_id, description, amount, category, date) VALUES (?, ?, ?, ?, ?)'
);
$stmt->execute([$userId, $desc, $amount, $category, $date]);

$expense = $db->query("SELECT * FROM expenses WHERE id = " . $db->lastInsertId())->fetch();
jsonResponse(true, 'Pengeluaran berhasil ditambahkan', $expense);
