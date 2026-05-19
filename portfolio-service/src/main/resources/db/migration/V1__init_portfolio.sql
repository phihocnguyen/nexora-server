-- ─── portfolios ───────────────────────────────────────────────────────────────
-- One portfolio per user. Aggregated P&L figures are kept denormalized here
-- and updated whenever a trade.executed event arrives from trading-service.
CREATE TABLE portfolios (
    id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID           NOT NULL UNIQUE,
    name           VARCHAR(100)   NOT NULL DEFAULT 'Main Portfolio',
    total_value    NUMERIC(28, 8) NOT NULL DEFAULT 0, -- current market value in base currency
    total_cost     NUMERIC(28, 8) NOT NULL DEFAULT 0, -- total amount invested
    unrealized_pnl NUMERIC(28, 8) NOT NULL DEFAULT 0,
    realized_pnl   NUMERIC(28, 8) NOT NULL DEFAULT 0,
    currency       VARCHAR(10)    NOT NULL DEFAULT 'USD',
    created_at     TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ─── holdings ─────────────────────────────────────────────────────────────────
-- One row per (portfolio, symbol). Tracks current position size and cost basis.
-- avg_cost_price is recalculated on each buy using the weighted average method.
CREATE TABLE holdings (
    id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id   UUID           NOT NULL REFERENCES portfolios(id),
    user_id        UUID           NOT NULL,
    symbol         VARCHAR(20)    NOT NULL,
    quantity       NUMERIC(28, 8) NOT NULL DEFAULT 0,
    avg_cost_price NUMERIC(28, 8) NOT NULL DEFAULT 0, -- weighted average entry price
    total_cost     NUMERIC(28, 8) NOT NULL DEFAULT 0, -- quantity * avg_cost_price
    current_price  NUMERIC(28, 8),                   -- last known market price
    current_value  NUMERIC(28, 8),                   -- quantity * current_price
    unrealized_pnl NUMERIC(28, 8),                   -- current_value - total_cost
    realized_pnl   NUMERIC(28, 8) NOT NULL DEFAULT 0, -- booked profit from sells
    created_at     TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP      NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_holdings_portfolio_symbol UNIQUE (portfolio_id, symbol),
    CONSTRAINT chk_holding_quantity         CHECK (quantity >= 0)
);

-- ─── portfolio_snapshots ──────────────────────────────────────────────────────
-- Append-only time-series of portfolio value. Written periodically (e.g. hourly
-- or daily) by a scheduled job, and after every significant trade event.
-- Used for charting portfolio performance over time.
CREATE TABLE portfolio_snapshots (
    id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id   UUID           NOT NULL REFERENCES portfolios(id),
    user_id        UUID           NOT NULL,
    total_value    NUMERIC(28, 8) NOT NULL,
    total_cost     NUMERIC(28, 8) NOT NULL,
    unrealized_pnl NUMERIC(28, 8) NOT NULL,
    realized_pnl   NUMERIC(28, 8) NOT NULL,
    snapshot_time  TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ─── indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_holdings_portfolio_id          ON holdings(portfolio_id);
CREATE INDEX idx_holdings_user_id               ON holdings(user_id);
CREATE INDEX idx_holdings_symbol                ON holdings(symbol);
CREATE INDEX idx_snapshots_portfolio_id         ON portfolio_snapshots(portfolio_id);
CREATE INDEX idx_snapshots_snapshot_time        ON portfolio_snapshots(snapshot_time DESC);
CREATE INDEX idx_snapshots_portfolio_time       ON portfolio_snapshots(portfolio_id, snapshot_time DESC); -- range queries
