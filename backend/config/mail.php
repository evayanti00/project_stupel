<?php

function loadMailConfig(): array {
    $config = [
        'driver' => getenv('STUPEL_MAIL_DRIVER') ?: 'mail',
        'from' => getenv('STUPEL_MAIL_FROM') ?: 'no-reply@stupel.local',
        'from_name' => getenv('STUPEL_MAIL_FROM_NAME') ?: 'STUPEL',
        'smtp_host' => getenv('STUPEL_SMTP_HOST') ?: '',
        'smtp_port' => (int)(getenv('STUPEL_SMTP_PORT') ?: 587),
        'smtp_encryption' => strtolower(getenv('STUPEL_SMTP_ENCRYPTION') ?: 'tls'),
        'smtp_user' => getenv('STUPEL_SMTP_USER') ?: '',
        'smtp_pass' => getenv('STUPEL_SMTP_PASS') ?: '',
        'smtp_timeout' => (int)(getenv('STUPEL_SMTP_TIMEOUT') ?: 15),
    ];

    $localPath = __DIR__ . '/mail.local.php';
    if (is_file($localPath)) {
        $local = require $localPath;
        if (is_array($local)) {
            $config = array_merge($config, $local);
        }
    }

    return $config;
}

function mailLog(string $to, string $subject, string $message, bool $sent, string $error = ''): void {
    $logPath = __DIR__ . '/../storage/mail.log';
    if (!is_dir(dirname($logPath))) {
        mkdir(dirname($logPath), 0777, true);
    }

    $entry = "To: $to\n"
        . "Subject: $subject\n"
        . "Sent: " . ($sent ? 'yes' : 'no') . "\n"
        . ($error !== '' ? "Error: $error\n" : '')
        . "Message:\n$message\n---\n";

    file_put_contents($logPath, $entry, FILE_APPEND);
}

function smtpRead($socket): string {
    $data = '';
    while (($line = fgets($socket, 515)) !== false) {
        $data .= $line;
        if (preg_match('/^\d{3} /', $line)) {
            break;
        }
    }
    return $data;
}

function smtpWrite($socket, string $command): void {
    fwrite($socket, $command . "\r\n");
}

function smtpExpect($socket, array $expectedCodes, string $step): void {
    $response = smtpRead($socket);
    $code = (int)substr($response, 0, 3);
    if (!in_array($code, $expectedCodes, true)) {
        throw new RuntimeException($step . ' failed: ' . trim($response));
    }
}

function smtpSendMail(array $cfg, string $to, string $subject, string $message): bool {
    $host = (string)($cfg['smtp_host'] ?? '');
    $port = (int)($cfg['smtp_port'] ?? 587);
    $encryption = strtolower((string)($cfg['smtp_encryption'] ?? 'tls'));
    $user = (string)($cfg['smtp_user'] ?? '');
    $pass = (string)($cfg['smtp_pass'] ?? '');
    $timeout = (int)($cfg['smtp_timeout'] ?? 15);
    $from = (string)($cfg['from'] ?? 'no-reply@stupel.local');
    $fromName = (string)($cfg['from_name'] ?? 'STUPEL');

    if ($host === '' || $user === '' || $pass === '') {
        throw new RuntimeException('SMTP config is incomplete');
    }

    $transport = ($encryption === 'ssl') ? 'ssl://' . $host : $host;
    $context = stream_context_create([
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
            'allow_self_signed' => true,
        ],
    ]);

    $socket = @stream_socket_client(
        $transport . ':' . $port,
        $errno,
        $errstr,
        $timeout,
        STREAM_CLIENT_CONNECT,
        $context
    );

    if (!$socket) {
        throw new RuntimeException('SMTP connect failed: ' . $errstr . ' (' . $errno . ')');
    }

    stream_set_timeout($socket, $timeout);

    smtpExpect($socket, [220], 'connect');
    smtpWrite($socket, 'EHLO localhost');
    smtpExpect($socket, [250], 'EHLO');

    if ($encryption === 'tls') {
        smtpWrite($socket, 'STARTTLS');
        smtpExpect($socket, [220], 'STARTTLS');
        if (!stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
            throw new RuntimeException('STARTTLS crypto handshake failed');
        }
        smtpWrite($socket, 'EHLO localhost');
        smtpExpect($socket, [250], 'EHLO after STARTTLS');
    }

    smtpWrite($socket, 'AUTH LOGIN');
    smtpExpect($socket, [334], 'AUTH LOGIN');
    smtpWrite($socket, base64_encode($user));
    smtpExpect($socket, [334], 'SMTP username');
    smtpWrite($socket, base64_encode($pass));
    smtpExpect($socket, [235], 'SMTP password');

    smtpWrite($socket, 'MAIL FROM:<' . $from . '>');
    smtpExpect($socket, [250], 'MAIL FROM');
    smtpWrite($socket, 'RCPT TO:<' . $to . '>');
    smtpExpect($socket, [250, 251], 'RCPT TO');
    smtpWrite($socket, 'DATA');
    smtpExpect($socket, [354], 'DATA');

    $headers = [];
    $headers[] = 'From: ' . $fromName . ' <' . $from . '>';
    $headers[] = 'Reply-To: ' . $from;
    $headers[] = 'MIME-Version: 1.0';
    $headers[] = 'Content-Type: text/html; charset=UTF-8';
    $headers[] = 'Subject: ' . $subject;
    $headers[] = 'To: ' . $to;

    $data = implode("\r\n", $headers) . "\r\n\r\n" . $message . "\r\n.";
    smtpWrite($socket, $data);
    smtpExpect($socket, [250], 'message body');

    smtpWrite($socket, 'QUIT');
    fclose($socket);

    return true;
}

function sendMail(string $to, string $subject, string $message): bool {
    $cfg = loadMailConfig();
    $driver = strtolower((string)($cfg['driver'] ?? 'mail'));

    try {
        if ($driver === 'smtp') {
            $sent = smtpSendMail($cfg, $to, $subject, $message);
        } else {
            $from = (string)($cfg['from'] ?? 'no-reply@stupel.local');
            $fromName = (string)($cfg['from_name'] ?? 'STUPEL');
            $headers = "From: $fromName <$from>\r\n";
            $headers .= "Reply-To: $from\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
            $sent = mail($to, $subject, $message, $headers);
        }

        mailLog($to, $subject, $message, $sent);
        return $sent;
    } catch (Throwable $e) {
        mailLog($to, $subject, $message, false, $e->getMessage());
        return false;
    }
}
