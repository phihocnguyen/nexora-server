-- ─── trades ───────────────────────────────────────────────────────────────────
-- Immutable record of every matched execution. Each row is produced by the
-- matching engine when a buy order and a sell order cross. Fees are stored
-- per-side at time of execution so the record is self-contained.
CREATE TABLE trades (
    id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol        VARCHAR(20)    NOT NULL,
    buy_order_id  UUID           NOT NULL REFERENCES orders(id),
    sell_order_id UUID           NOT NULL REFERENCES orders(id),
    buyer_id      UUID           NOT NULL,
    seller_id     UUID           NOT NULL,
    quantity      NUMERIC(28, 8) NOT NULL,
    price         NUMERIC(28, 8) NOT NULL,  -- execution price (taker's price)
    buyer_fee     NUMERIC(28, 8) NOT NULL DEFAULT 0,
    seller_fee    NUMERIC(28, 8) NOT NULL DEFAULT 0,
    executed_at   TIMESTAMP      NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_trade_quantity   CHECK (quantity   > 0),
    CONSTRAINT chk_trade_price      CHECK (price      > 0),
    CONSTRAINT chk_trade_buyer_fee  CHECK (buyer_fee  >= 0),
    CONSTRAINT chk_trade_seller_fee CHECK (seller_fee >= 0)
);

-- ─── indexes ──────────────────────────────────────────────────────────────────
-- Primary query patterns: trade history by symbol, per-user trade history,
-- linking back to source orders, and time-series feeds.
CREATE INDEX idx_trades_symbol         ON trades(symbol);
CREATE INDEX idx_trades_buy_order_id   ON trades(buy_order_id);
CREATE INDEX idx_trades_sell_order_id  ON trades(sell_order_id);
CREATE INDEX idx_trades_buyer_id       ON trades(buyer_id);
CREATE INDEX idx_trades_seller_id      ON trades(seller_id);
CREATE INDEX idx_trades_executed_at    ON trades(executed_at DESC);
CREATE INDEX idx_trades_symbol_time    ON trades(symbol, executed_at DESC); -- OHLCV aggregation
