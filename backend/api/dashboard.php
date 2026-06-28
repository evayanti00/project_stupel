<?php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/jwt.php';

$payload = requireAuth();
$userId  = $payload['user_id'];
$db      = getDB();

// Pending tasks
$stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 1 AND is_done = 0');
$stmt->execute([$userId]);
$pendingTasks = (int)$stmt->fetchColumn();

// Total notes (non-task)
$stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 0');
$stmt->execute([$userId]);
$totalNotes = (int)$stmt->fetchColumn();

// Total expenses this month
$stmt = $db->prepare(
    'SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ? AND MONTH(date) = MONTH(NOW()) AND YEAR(date) = YEAR(NOW())'
);
$stmt->execute([$userId]);
$totalExpenses = (float)$stmt->fetchColumn();

jsonResponse(true, 'OK', [
    'pending_tasks'  => $pendingTasks,
    'total_notes'    => $totalNotes,
    'total_expenses' => $totalExpenses,
]);
