# EWallet Database (PostgreSQL)

Database sederhana untuk project EWallet, terdiri dari 3 tabel.

## ERD

```mermaid
erDiagram
    USERS ||--|| WALLETS : "punya"
    USERS ||--o{ TRANSACTIONS : "mengirim (sender_id)"
    USERS ||--o{ TRANSACTIONS : "menerima (receiver_id)"

    USERS {
        int id PK
        varchar username UK
        varchar email UK
        varchar password
        varchar pin
        varchar full_name
        varchar phone UK
        varchar photo
        timestamp created_at
        timestamp updated_at
    }

    WALLETS {
        int id PK
        int user_id FK
        numeric balance
    }

    TRANSACTIONS {
        int id PK
        int sender_id FK
        int receiver_id FK
        varchar type
        numeric amount
        varchar notes
        timestamp created_at
    }
```

> Ganti bagian ini dengan screenshot ERD (lihat petunjuk di bawah).

## Penjelasan Tabel

| Tabel | Fungsi |
|---|---|
| `users` | Data akun & profil (password dan PIN disimpan dalam bentuk hash) |
| `wallets` | Saldo tiap user (1 user = 1 wallet) |
| `transactions` | Riwayat topup & transfer. Topup: `sender_id` kosong. Transfer: pengirim & penerima terisi |

Income = transaksi di mana user adalah receiver, expense = transaksi di mana user adalah sender.

## File

- `schema.sql` : membuat tabel
- `koda-b1-weekly.sql` : semua query yang dibutuhkan

## Cara Menjalankan

```bash
psql -U postgres -d ewallet -f schema.sql
```