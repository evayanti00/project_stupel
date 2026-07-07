<?php
require_once __DIR__ . '/../../config/cors.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST' && $method !== 'GET') {
    jsonResponse(false, 'Method not allowed', null, 405);
}

if ($method === 'GET') {
    echo '<h3>Fitur verifikasi email dinonaktifkan</h3><p>Silakan kembali ke aplikasi dan login seperti biasa.</p>';
    exit;
}

jsonResponse(false, 'Fitur verifikasi email dinonaktifkan', null, 410);
