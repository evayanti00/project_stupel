<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') jsonResponse(false, 'Method not allowed', null, 405);

$payload = requireAuth();
$userId  = $payload['user_id'];
$id      = (int)($_GET['id'] ?? 0);
$body    = getRequestBody();

if (!$id) jsonResponse(false, 'ID tidak valid');

$db   = getDB();
$stmt = $db->prepare('SELECT amount FROM expenses WHERE id = ? AND user_id = ?');
$stmt->execute([$id, $userId]);
$row = $stmt->fetch();
if (!$row) jsonResponse(false, 'Pengeluaran tidak ditemukan', null, 404);
$oldAmount = (float)$row['amount'];

$desc     = trim($body['description'] ?? '');
$amount   = (float)($body['amount'] ?? 0);
$category = trim($body['category'] ?? '');
$date     = $body['date'] ?? date('Y-m-d');

if (!$desc || $amount <= 0 || !$category) jsonResponse(false, 'Data tidak lengkap');

$stmt = $db->prepare(
    'UPDATE expenses SET description=?, amount=?, category=?, date=? WHERE id=? AND user_id=?'
);
$stmt->execute([$desc, $amount, $category, $date, $id, $userId]);
// adjust user balance: add back old amount then subtract new amount
$db->prepare('UPDATE users SET balance = balance + ? - ? WHERE id = ?')->execute([$oldAmount, $amount, $userId]);

$expense = $db->query("SELECT * FROM expenses WHERE id = $id")->fetch();
jsonResponse(true, 'Pengeluaran berhasil diperbarui', $expense);
