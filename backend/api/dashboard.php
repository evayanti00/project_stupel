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


$stmt = $db->prepare(
    'SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ? AND YEARWEEK(date, 1) = YEARWEEK(CURDATE(), 1)'
);
$stmt->execute([$userId]);
$weekExpenses = (float)$stmt->fetchColumn();


$stmt = $db->prepare('SELECT id, title, content, is_task, is_done, created_at, due_date FROM notes WHERE user_id = ? AND is_task = 1 AND is_done = 0 AND due_date IS NOT NULL AND due_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) ORDER BY due_date ASC LIMIT 5');
$stmt->execute([$userId]);
$upcomingTasks = $stmt->fetchAll();

jsonResponse(true, 'OK', [
    'pending_tasks'   => $pendingTasks,
    'total_notes'     => $totalNotes,
    'total_expenses'  => $totalExpenses,
    'week_expenses'   => $weekExpenses,
    'priority_tasks'  => count($upcomingTasks),
    'upcoming_tasks'  => $upcomingTasks,
]);
