-- ─── users ───────────────────────────────────────────────────────────────────
-- Local projection of user accounts, synced from auth-service via Kafka.
-- No cross-service FK — user_id is treated as an opaque UUID.
CREATE TABLE users (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email      VARCHAR(255) NOT NULL UNIQUE,
    username   VARCHAR(100) NOT NULL UNIQUE,
    status     VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, CLOSED
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─── wallets ──────────────────────────────────────────────────────────────────
-- One row per (user, currency). Balances are split into available and locked
-- portions so that funds reserved for open orders are accounted for separately.
CREATE TABLE wallets (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID         NOT NULL REFERENCES users(id),
    currency          VARCHAR(10)  NOT NULL,             -- e.g. USD, BTC, ETH
    balance           NUMERIC(28, 8) NOT NULL DEFAULT 0, -- total = available + locked
    available_balance NUMERIC(28, 8) NOT NULL DEFAULT 0,
    locked_balance    NUMERIC(28, 8) NOT NULL DEFAULT 0,
    status            VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, FROZEN, CLOSED
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_wallets_user_currency UNIQUE (user_id, currency),
    CONSTRAINT chk_wallet_balance       CHECK (balance           >= 0),
    CONSTRAINT chk_wallet_available     CHECK (available_balance >= 0),
    CONSTRAINT chk_wallet_locked        CHECK (locked_balance    >= 0)
);

-- ─── transactions ─────────────────────────────────────────────────────────────
-- Immutable double-entry ledger. Every balance change produces one row.
-- balance_before + amount = balance_after (amount may be negative for debits).
CREATE TABLE transactions (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id        UUID          NOT NULL REFERENCES wallets(id),
    user_id          UUID          NOT NULL,
    type             VARCHAR(30)   NOT NULL, -- DEPOSIT | WITHDRAWAL | TRANSFER_IN |
                                             -- TRANSFER_OUT | TRADE_LOCK |
                                             -- TRADE_RELEASE | FEE
    amount           NUMERIC(28, 8) NOT NULL,
    balance_before   NUMERIC(28, 8) NOT NULL,
    balance_after    NUMERIC(28, 8) NOT NULL,
    reference_id     VARCHAR(255),           -- trade_id, order_id, external tx hash
    reference_type   VARCHAR(50),            -- TRADE | ORDER | DEPOSIT | WITHDRAWAL
    status           VARCHAR(20)   NOT NULL DEFAULT 'COMPLETED', -- PENDING | COMPLETED | FAILED
    description      TEXT,
    created_at       TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ─── indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_wallets_user_id           ON wallets(user_id);
CREATE INDEX idx_transactions_wallet_id    ON transactions(wallet_id);
CREATE INDEX idx_transactions_user_id      ON transactions(user_id);
CREATE INDEX idx_transactions_reference_id ON transactions(reference_id);
CREATE INDEX idx_transactions_created_at   ON transactions(created_at DESC);
CREATE INDEX idx_transactions_type         ON transactions(type);
