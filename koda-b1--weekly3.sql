-- CREATE DATABASE koda_b1_weekly3;
-- Data akun pengguna
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,          -- simpan hash, bukan teks asli
    pin         VARCHAR(255),                   -- simpan hash, boleh kosong sebelum diatur
    full_name   VARCHAR(100),
    phone       VARCHAR(20) UNIQUE,
    photo       VARCHAR(255),                   -- path / URL foto
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP
);

-- Saldo pengguna (1 user = 1 wallet)
CREATE TABLE wallets (
    id       SERIAL PRIMARY KEY,
    user_id  INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance  NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0)
);

-- Riwayat transaksi (topup & transfer)
-- topup    : sender_id = NULL, receiver_id = user yang topup
-- transfer : sender_id = pengirim, receiver_id = penerima
CREATE TABLE transactions (
    id           SERIAL PRIMARY KEY,
    sender_id    INT REFERENCES users(id),
    receiver_id  INT NOT NULL REFERENCES users(id),
    type         VARCHAR(10) NOT NULL CHECK (type IN ('topup', 'transfer')),
    amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    notes        VARCHAR(255),
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trx_sender   ON transactions(sender_id);
CREATE INDEX idx_trx_receiver ON transactions(receiver_id);