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
$stmt = $db->prepare('DELETE FROM notes WHERE id = ? AND user_id = ?');
$stmt->execute([$id, $userId]);

if ($stmt->rowCount() === 0) jsonResponse(false, 'Catatan tidak ditemukan', null, 404);

jsonResponse(true, 'Catatan berhasil dihapus');
