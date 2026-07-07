<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';
require_once __DIR__ . '/../../config/jwt.php';

$payload = requireAuth();
$userId = (int)$payload['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Method not allowed', null, 405);
}

if (!isset($_FILES['photo'])) {
    jsonResponse(false, 'File foto tidak ditemukan');
}

$file = $_FILES['photo'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    jsonResponse(false, 'Upload gagal');
}

if ($file['size'] > 5 * 1024 * 1024) {
    jsonResponse(false, 'Ukuran file maksimal 5MB');
}

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

$allowed = [
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
];

if (!isset($allowed[$mime])) {
    jsonResponse(false, 'Format file tidak didukung. Gunakan JPG, PNG, atau WEBP');
}

$ext = $allowed[$mime];
$filename = 'user_' . $userId . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;

$uploadDir = realpath(__DIR__ . '/../../uploads/profile');
if ($uploadDir === false) {
    $uploadDir = __DIR__ . '/../../uploads/profile';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
}

$targetPath = rtrim($uploadDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $filename;

if (!move_uploaded_file($file['tmp_name'], $targetPath)) {
    jsonResponse(false, 'Tidak dapat menyimpan file');
}

$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$scriptName = $_SERVER['SCRIPT_NAME'] ?? '/project_stupel/backend/api/user/upload-photo.php';
$projectBase = preg_replace('#/backend/api/user/upload-photo\.php$#', '', $scriptName);
$imageUrl = $scheme . '://' . $host . $projectBase . '/backend/uploads/profile/' . $filename;

jsonResponse(true, 'Upload foto berhasil', [
    'url' => $imageUrl,
]);
