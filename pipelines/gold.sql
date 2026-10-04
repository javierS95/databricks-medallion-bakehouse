-- =========================================================
-- GOLD · Modelos de negocio listos para consumo (BI / Genie)
-- =========================================================

-- ---------------------------------------------------------
-- Ventas diarias por franquicia
-- ---------------------------------------------------------
CREATE OR REFRESH MATERIALIZED VIEW workspace.gold.daily_sales_by_franchise
COMMENT 'Ventas diarias por franquicia: transacciones, unidades, ingresos y ticket promedio'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  t.transaction_date,
  t.franchise_id,
  f.name                               AS franchise_name,
  f.city                               AS franchise_city,
  f.country                            AS franchise_country,
  COUNT(*)                             AS n_transactions,
  SUM(t.quantity)                      AS units_sold,
  SUM(t.total_price)                   AS revenue,
  ROUND(SUM(t.total_price) / COUNT(*), 2) AS avg_ticket
FROM workspace.silver.transactions t
LEFT JOIN samples.bakehouse.sales_franchises f
  ON t.franchise_id = f.franchiseID
GROUP BY ALL;

-- ---------------------------------------------------------
-- Desempeño por producto
-- ---------------------------------------------------------
CREATE OR REFRESH MATERIALIZED VIEW workspace.gold.product_performance
COMMENT 'Desempeño por producto: unidades, ingresos y participación sobre el total'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  product,
  COUNT(*)                                                    AS n_transactions,
  SUM(quantity)                                               AS units_sold,
  SUM(total_price)                                            AS revenue,
  ROUND(100 * SUM(total_price) / SUM(SUM(total_price)) OVER (), 2) AS revenue_share_pct
FROM workspace.silver.transactions
GROUP BY product;

-- ---------------------------------------------------------
-- Métricas por cliente (con ciudad vigente desde el SCD2)
-- ---------------------------------------------------------
CREATE OR REFRESH MATERIALIZED VIEW workspace.gold.customer_metrics
COMMENT 'Métricas por cliente: frecuencia, gasto total, ticket promedio y ciudad vigente'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  t.customer_id,
  c.city                               AS current_city,
  MIN(t.transaction_date)              AS first_purchase,
  MAX(t.transaction_date)              AS last_purchase,
  COUNT(*)                             AS n_transactions,
  SUM(t.total_price)                   AS total_spent,
  ROUND(SUM(t.total_price) / COUNT(*), 2) AS avg_ticket
FROM workspace.silver.transactions t
LEFT JOIN workspace.silver.customers_scd2 c
  ON t.customer_id = c.customerID
 AND c.__END_AT IS NULL
GROUP BY ALL;   