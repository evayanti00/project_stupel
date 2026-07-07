<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(false, 'Method not allowed', null, 405);

$payload = requireAuth();
$userId  = $payload['user_id'];
$body    = getRequestBody();

$title   = trim($body['title'] ?? '');
$content = trim($body['content'] ?? '');
$isTask  = (int)($body['is_task'] ?? 0);
$isDone  = (int)($body['is_done'] ?? 0);
$dueDate = $body['due_date'] ?? null;
$images = json_encode($body['images'] ?? []);
$description = $body['description'] ?? null;
$priority = $body['priority'] ?? null;
$status = $body['status'] ?? null;

if (!$title) jsonResponse(false, 'Judul harus diisi');

$db   = getDB();
$stmt = $db->prepare(
    'INSERT INTO notes (user_id, title, content, is_task, is_done, due_date, images, description, priority, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
$stmt->execute([$userId, $title, $content, $isTask, $isDone, $dueDate, $images, $description, $priority, $status]);

$note = $db->query("SELECT * FROM notes WHERE id = " . $db->lastInsertId())->fetch();
jsonResponse(true, 'Catatan berhasil ditambahkan', $note);
