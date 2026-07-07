<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAdmin();
$db = getDB();
$id = (int)($_GET['id'] ?? 0);

if (!$id) {
    jsonResponse(false, 'ID pengguna tidak valid');
}

$stmt = $db->prepare('SELECT id, name, email, role, is_active, balance, created_at FROM users WHERE id = ?');
$stmt->execute([$id]);
$user = $stmt->fetch();

if (!$user) {
    jsonResponse(false, 'User tidak ditemukan');
}

$stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ?');
$stmt->execute([$id]);
$totalNotes = (int)$stmt->fetchColumn();

$stmt = $db->prepare('SELECT COUNT(*) FROM notes WHERE user_id = ? AND is_task = 1');
$stmt->execute([$id]);
$totalTasks = (int)$stmt->fetchColumn();

$stmt = $db->prepare('SELECT COUNT(*) FROM expenses WHERE user_id = ?');
$stmt->execute([$id]);
$totalExpenses = (int)$stmt->fetchColumn();

$stmt = $db->prepare('SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE user_id = ?');
$stmt->execute([$id]);
$totalExpenseAmount = (float)$stmt->fetchColumn();

jsonResponse(true, 'OK', [
    'user' => $user,
    'stats' => [
        'total_notes' => $totalNotes,
        'total_tasks' => $totalTasks,
        'total_expenses' => $totalExpenses,
        'total_expense_amount' => $totalExpenseAmount,
    ],
]);
