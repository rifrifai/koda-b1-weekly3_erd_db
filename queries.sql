-- Query EWallet (PostgreSQL)
-- $1, $2, ... = parameter dari aplikasi
SELECT id, username, email, password
FROM users
WHERE email = $1 OR username = $1;

WITH new_user AS (
    INSERT INTO users (username, email, password)
    VALUES ($1, $2, $3)
    RETURNING id
)
INSERT INTO wallets (user_id)
SELECT id FROM new_user;

SELECT username, email, photo
FROM users
WHERE id = $1;

SELECT pin FROM users WHERE id = $1;

SELECT (pin IS NOT NULL) AS has_pin FROM users WHERE id = $1;

SELECT
    t.id,
    t.type,
    t.amount,
    t.notes,
    t.created_at,
    CASE WHEN t.receiver_id = $1 THEN 'income' ELSE 'expense' END AS direction,
    s.full_name AS sender_name,
    r.full_name AS receiver_name
FROM transactions t
LEFT JOIN users s ON s.id = t.sender_id
JOIN users r ON r.id = t.receiver_id
WHERE t.sender_id = $1 OR t.receiver_id = $1
ORDER BY t.created_at DESC;

-- GET USER HISTORY WITH OPTION (income/expense, date range)
-- $1 = user id
-- $2 = 'income' / 'expense' (NULL = semua)
-- $3 = tanggal mulai (NULL = bebas)
-- $4 = tanggal akhir (NULL = bebas)
SELECT *
FROM (
    SELECT
        t.id,
        t.type,
        t.amount,
        t.notes,
        t.created_at,
        CASE WHEN t.receiver_id = $1 THEN 'income' ELSE 'expense' END AS direction
    FROM transactions t
    WHERE t.sender_id = $1 OR t.receiver_id = $1
) AS history
WHERE ($2::text IS NULL OR direction = $2)
    AND ($3::date IS NULL OR created_at >= $3::date)
    AND ($4::date IS NULL OR created_at <  $4::date + INTERVAL '1 day')
ORDER BY created_at DESC;

-- GET USER ACCOUNT INFORMATION (balance, income, expense)
SELECT
    w.balance,
    COALESCE(SUM(t.amount) FILTER (WHERE t.receiver_id = $1), 0) AS income,
    COALESCE(SUM(t.amount) FILTER (WHERE t.sender_id   = $1), 0) AS expense
FROM wallets w
LEFT JOIN transactions t
        ON t.sender_id = $1 OR t.receiver_id = $1
WHERE w.user_id = $1
GROUP BY w.balance;

-- FIND RECEIVER WITH PAGINATION
-- $1 = id user sendiri, $2 = kata kunci, $3 = limit, $4 = offset
SELECT id, username, full_name, phone, photo
FROM users
WHERE id <> $1
    AND (
        username  ILIKE '%' || $2 || '%'
        OR full_name ILIKE '%' || $2 || '%'
        OR phone     ILIKE '%' || $2 || '%'
    )
ORDER BY full_name
LIMIT $3 OFFSET $4;

-- CREATE TRANSACTION / TOPUP

-- TOPUP ($1 = user id, $2 = nominal, $3 = catatan)
BEGIN;
    INSERT INTO transactions (sender_id, receiver_id, type, amount, notes)
    VALUES (NULL, $1, 'topup', $2, $3);

    UPDATE wallets SET balance = balance + $2 WHERE user_id = $1;
COMMIT;

-- TRANSFER ($1 = pengirim, $2 = penerima, $3 = nominal, $4 = catatan)
-- Jika saldo kurang, CHECK (balance >= 0) akan membuat transaksi gagal
BEGIN;
    UPDATE wallets SET balance = balance - $3 WHERE user_id = $1;
    UPDATE wallets SET balance = balance + $3 WHERE user_id = $2;

    INSERT INTO transactions (sender_id, receiver_id, type, amount, notes)
    VALUES ($1, $2, 'transfer', $3, $4);
COMMIT;

-- GET USER PROFILE (photo, full name, phone, email)
SELECT photo, full_name, phone, email
FROM users
WHERE id = $1;

-- CHANGE PIN ($1 = user id, $2 = hash PIN baru)
UPDATE users
SET pin = $2, updated_at = NOW()
WHERE id = $1;

-- CHANGE PASSWORD ($1 = user id, $2 = hash password baru)
UPDATE users
SET password = $2, updated_at = NOW()
WHERE id = $1;

-- CHANGE USER PROFILE
-- $1 = user id, $2 = full name, $3 = phone, $4 = photo
UPDATE users
SET full_name  = $2,
    phone      = $3,
    photo      = $4,
    updated_at = NOW()
WHERE id = $1;
