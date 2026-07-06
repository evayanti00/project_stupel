<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') jsonResponse(false, 'Method not allowed', null, 405);

$payload = requireAuth();
$userId  = $payload['user_id'];
$id      = (int)($_GET['id'] ?? 0);

if (!$id) jsonResponse(false, 'ID tidak valid');

$db   = getDB();
$stmt = $db->prepare('SELECT amount FROM expenses WHERE id = ? AND user_id = ?');
$stmt->execute([$id, $userId]);
$row = $stmt->fetch();
if (!$row) jsonResponse(false, 'Pengeluaran tidak ditemukan', null, 404);
$amount = (float)$row['amount'];

$stmt = $db->prepare('DELETE FROM expenses WHERE id = ? AND user_id = ?');
$stmt->execute([$id, $userId]);

// restore balance
$db->prepare('UPDATE users SET balance = balance + ? WHERE id = ?')->execute([$amount, $userId]);

jsonResponse(true, 'Pengeluaran berhasil dihapus');
