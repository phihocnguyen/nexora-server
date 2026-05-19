-- Create databases for each service that uses PostgreSQL
CREATE DATABASE portfolio_db;
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO nexora;

CREATE DATABASE trading_db;
GRANT ALL PRIVILEGES ON DATABASE trading_db TO nexora;

CREATE DATABASE wallet_db;
GRANT ALL PRIVILEGES ON DATABASE wallet_db TO nexora;
