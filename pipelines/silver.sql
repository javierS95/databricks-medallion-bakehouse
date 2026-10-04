-- =========================================================
-- SILVER · Datos limpios, tipados, deduplicados y validados
-- =========================================================

-- ---------------------------------------------------------
-- Transacciones: limpieza + tipado + dedup + calidad
-- ---------------------------------------------------------
CREATE OR REFRESH MATERIALIZED VIEW workspace.silver.transactions (
  CONSTRAINT transaction_id_not_null EXPECT (transaction_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT quantity_not_null       EXPECT (quantity IS NOT NULL)       ON VIOLATION DROP ROW,
  CONSTRAINT unit_price_valid        EXPECT (unit_price > 0)             ON VIOLATION DROP ROW,
  CONSTRAINT total_price_consistent  EXPECT (abs(total_price - quantity * unit_price) < 0.01)
)
COMMENT 'Transacciones limpias: tipos corregidos, precios normalizados, sin duplicados'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  transactionID                                              AS transaction_id,
  customerID                                                 AS customer_id,
  franchiseID                                                AS franchise_id,
  to_timestamp(dateTime, 'yyyy-MM-dd HH:mm:ss')              AS transaction_ts,
  to_date(to_timestamp(dateTime, 'yyyy-MM-dd HH:mm:ss'))     AS transaction_date,
  product,
  CAST(quantity AS INT)                                      AS quantity,
  try_cast(replace(unitPrice, ',', '.') AS DECIMAL(10,2))    AS unit_price,
  CAST(totalPrice AS DECIMAL(10,2))                          AS total_price,
  paymentMethod                                              AS payment_method,
  _source_file,
  _ingested_at
FROM workspace.bronze.transactions
QUALIFY ROW_NUMBER() OVER (PARTITION BY transactionID ORDER BY _ingested_at DESC) = 1;

-- ---------------------------------------------------------
-- Clientes: historial de cambios con SCD tipo 2
-- ---------------------------------------------------------
CREATE OR REFRESH STREAMING TABLE workspace.silver.customers_scd2
COMMENT 'Historial de clientes (SCD tipo 2): cada cambio de atributos genera una nueva versión';

CREATE FLOW customers_scd2_flow AS AUTO CDC INTO workspace.silver.customers_scd2
FROM STREAM(workspace.bronze.customers)
KEYS (customerID)
SEQUENCE BY updated_at
COLUMNS * EXCEPT (_source_file, _ingested_at)
STORED AS SCD TYPE 2
TRACK HISTORY ON * EXCEPT (updated_at);