<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAuth();
$userId  = $payload['user_id'];

$db    = getDB();
$stmt  = $db->prepare('SELECT * FROM notes WHERE user_id = ? ORDER BY created_at DESC');
$stmt->execute([$userId]);
$notes = $stmt->fetchAll();

jsonResponse(true, 'OK', $notes);
