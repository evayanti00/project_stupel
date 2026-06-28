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
$stmt = $db->prepare('SELECT id FROM notes WHERE id = ? AND user_id = ?');
$stmt->execute([$id, $userId]);
if (!$stmt->fetch()) jsonResponse(false, 'Catatan tidak ditemukan', null, 404);

$title   = trim($body['title'] ?? '');
$content = trim($body['content'] ?? '');
$isTask  = (int)($body['is_task'] ?? 0);
$isDone  = (int)($body['is_done'] ?? 0);

if (!$title) jsonResponse(false, 'Judul harus diisi');

$stmt = $db->prepare(
    'UPDATE notes SET title=?, content=?, is_task=?, is_done=? WHERE id=? AND user_id=?'
);
$stmt->execute([$title, $content, $isTask, $isDone, $id, $userId]);

$note = $db->query("SELECT * FROM notes WHERE id = $id")->fetch();
jsonResponse(true, 'Catatan berhasil diperbarui', $note);
