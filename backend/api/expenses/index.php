<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload  = requireAuth();
$userId   = $payload['user_id'];

$db   = getDB();
$stmt = $db->prepare('SELECT * FROM expenses WHERE user_id = ? ORDER BY date DESC, created_at DESC');
$stmt->execute([$userId]);

jsonResponse(true, 'OK', $stmt->fetchAll());
