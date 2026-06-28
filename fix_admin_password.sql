USE stupel_db;
UPDATE users SET password = '$2y$10$sRLDTDn08SWjK5jzLJn9UeioKH9kXvkmKsU0WVSJYbzZBdlCgQWQ2' WHERE email = 'admin@stupel.com';
SELECT email, LEFT(password, 20) as pass_start FROM users WHERE email = 'admin@stupel.com';
