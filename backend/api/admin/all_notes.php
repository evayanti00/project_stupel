<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

requireAdmin();

$db = getDB();
$notes = $db->query(
    'SELECT n.*, u.name as user_name, u.email as user_email
     FROM notes n JOIN users u ON n.user_id = u.id
     ORDER BY n.created_at DESC'
)->fetchAll();

jsonResponse(true, 'OK', $notes);
