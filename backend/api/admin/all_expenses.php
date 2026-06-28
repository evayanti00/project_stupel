<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

requireAdmin();

$db = getDB();
$expenses = $db->query(
    'SELECT e.*, u.name as user_name, u.email as user_email
     FROM expenses e JOIN users u ON e.user_id = u.id
     ORDER BY e.date DESC, e.created_at DESC'
)->fetchAll();

jsonResponse(true, 'OK', $expenses);
