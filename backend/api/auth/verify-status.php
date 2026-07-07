<?php
require_once __DIR__ . '/../../config/cors.php';

jsonResponse(false, 'Fitur verifikasi email dinonaktifkan', [
    'is_verified' => 1,
    'is_active' => 1,
], 410);
