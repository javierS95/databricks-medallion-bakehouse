-- =========================================================
-- BRONZE · Ingesta incremental desde landing con Auto Loader
-- Datos tal como llegan + metadata de trazabilidad.
-- Sin limpieza: bronze es el registro fiel de la fuente.
-- =========================================================

CREATE OR REFRESH STREAMING TABLE workspace.bronze.transactions
COMMENT 'Transacciones crudas ingeridas incrementalmente desde landing.raw/transactions'
TBLPROPERTIES ('quality' = 'bronze')
AS SELECT
  *,
  _metadata.file_path              AS _source_file,
  _metadata.file_modification_time AS _file_modified_at,
  current_timestamp()              AS _ingested_at
FROM STREAM read_files(
  '/Volumes/workspace/landing/raw/transactions/',
  format => 'json',
  schemaHints => 'unitPrice STRING, dateTime STRING'
);

CREATE OR REFRESH STREAMING TABLE workspace.bronze.customers
COMMENT 'Snapshots de clientes ingeridos incrementalmente desde landing.raw/customers'
TBLPROPERTIES ('quality' = 'bronze')
AS SELECT
  *,
  _metadata.file_path AS _source_file,
  current_timestamp() AS _ingested_at
FROM STREAM read_files(
  '/Volumes/workspace/landing/raw/customers/',
  format => 'json'
);