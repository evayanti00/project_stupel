<?php
// Copy this file to mail.local.php and fill in your SMTP credentials.
// Do NOT commit mail.local.php to git.

return [
    'driver' => 'smtp', // smtp | mail
    'from' => 'your_email@gmail.com',
    'from_name' => 'STUPEL',
    'smtp_host' => 'smtp.gmail.com',
    'smtp_port' => 587,
    'smtp_encryption' => 'tls', // tls | ssl | none
    'smtp_user' => 'your_email@gmail.com',
    'smtp_pass' => 'your_app_password',
    'smtp_timeout' => 15,
];
