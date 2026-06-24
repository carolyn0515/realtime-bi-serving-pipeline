DROP CATALOG IF EXISTS paimon_lakehouse;

CREATE EXTERNAL CATALOG paimon_lakehouse
PROPERTIES
(
    "type" = "paimon",
    "paimon.catalog.type" = "filesystem",
    "paimon.catalog.warehouse" = "file:/warehouse/paimon"
);

SHOW CATALOGS;

SHOW DATABASES FROM paimon_lakehouse;

SHOW TABLES FROM paimon_lakehouse.lakehouse;
