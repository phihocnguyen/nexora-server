-- ─── orders ───────────────────────────────────────────────────────────────────
-- Represents all orders placed by users. The live order book is derived
-- by querying orders WHERE status IN ('OPEN', 'PARTIAL').
--
-- side          : BUY | SELL
-- type          : MARKET | LIMIT | STOP_LIMIT
-- status        : OPEN | PARTIAL | FILLED | CANCELLED | EXPIRED
-- time_in_force : GTC (Good-Till-Cancel) | IOC (Immediate-Or-Cancel) | FOK (Fill-Or-Kill)
CREATE TABLE orders (
    id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID           NOT NULL,
    symbol           VARCHAR(20)    NOT NULL,         -- e.g. BTC/USD, ETH/USD
    side             VARCHAR(4)     NOT NULL,          -- BUY | SELL
    type             VARCHAR(10)    NOT NULL,          -- MARKET | LIMIT | STOP_LIMIT
    quantity         NUMERIC(28, 8) NOT NULL,
    price            NUMERIC(28, 8),                  -- NULL for MARKET orders
    stop_price       NUMERIC(28, 8),                  -- set for STOP_LIMIT orders
    filled_quantity  NUMERIC(28, 8) NOT NULL DEFAULT 0,
    avg_fill_price   NUMERIC(28, 8),                  -- weighted average fill price
    status           VARCHAR(20)    NOT NULL DEFAULT 'OPEN',
    time_in_force    VARCHAR(3)     NOT NULL DEFAULT 'GTC',
    created_at       TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP      NOT NULL DEFAULT NOW(),
    expires_at       TIMESTAMP,                       -- used for GTD orders
    CONSTRAINT chk_order_quantity        CHECK (quantity        > 0),
    CONSTRAINT chk_order_filled_quantity CHECK (filled_quantity >= 0),
    CONSTRAINT chk_order_side            CHECK (side            IN ('BUY', 'SELL')),
    CONSTRAINT chk_order_type            CHECK (type            IN ('MARKET', 'LIMIT', 'STOP_LIMIT')),
    CONSTRAINT chk_order_status          CHECK (status          IN ('OPEN', 'PARTIAL', 'FILLED', 'CANCELLED', 'EXPIRED')),
    CONSTRAINT chk_order_tif             CHECK (time_in_force   IN ('GTC', 'IOC', 'FOK'))
);

-- ─── indexes ──────────────────────────────────────────────────────────────────
-- Primary query patterns: user history, live order book by symbol, matching engine lookups.
CREATE INDEX idx_orders_user_id          ON orders(user_id);
CREATE INDEX idx_orders_symbol_status    ON orders(symbol, status);
CREATE INDEX idx_orders_symbol_side_status ON orders(symbol, side, status);  -- order book query
CREATE INDEX idx_orders_created_at       ON orders(created_at DESC);
CREATE INDEX idx_orders_updated_at       ON orders(updated_at DESC);
