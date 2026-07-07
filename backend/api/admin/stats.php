<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAdmin();
$db = getDB();

$stmt = $db->query('SELECT COUNT(*) FROM users');
$totalUsers = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COUNT(*) FROM users WHERE role = "user"');
$totalMembers = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COUNT(*) FROM users WHERE is_active = 1');
$activeUsers = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COUNT(*) FROM notes');
$totalNotes = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COUNT(*) FROM notes WHERE is_task = 1');
$totalTasks = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COUNT(*) FROM expenses');
$totalExpenses = (int)$stmt->fetchColumn();

$stmt = $db->query('SELECT COALESCE(SUM(amount), 0) FROM expenses');
$totalExpenseAmount = (float)$stmt->fetchColumn();

$stmt = $db->query(
    'SELECT DATE_FORMAT(created_at, "%Y-%m") AS month_key, COUNT(*) AS total '
    . 'FROM users '
    . 'WHERE created_at >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 5 MONTH), "%Y-%m-01") '
    . 'GROUP BY month_key '
    . 'ORDER BY month_key'
);
$growthRows = $stmt->fetchAll();

$growthMap = [];
foreach ($growthRows as $row) {
    $growthMap[$row['month_key']] = (int)$row['total'];
}

$userGrowth = [];
$month = new DateTime('first day of -5 month');
for ($i = 0; $i < 6; $i++) {
    $key = $month->format('Y-m');
    $userGrowth[] = [
        'month' => $key,
        'label' => $month->format('M y'),
        'total' => (int)($growthMap[$key] ?? 0),
    ];
    $month->modify('+1 month');
}

jsonResponse(true, 'OK', [
    'total_users' => $totalUsers,
    'total_members' => $totalMembers,
    'active_users' => $activeUsers,
    'total_notes' => $totalNotes,
    'total_tasks' => $totalTasks,
    'total_expenses' => $totalExpenses,
    'total_expense_amount' => $totalExpenseAmount,
    'user_growth' => $userGrowth,
]);
