/* ============================================================
   DETECTOR DE POSIBLES FOREIGN KEYS
   ============================================================

   Este script:
   
   1. Detecta columnas que puedan ser fk sin identificar
   2. Compara el contenido de estas columnas con el de su correspondiente pk
   3. Informa al usuario para añadir relaciones desconocidas a metages_qa_fk_mapping
   
   
   Para eso:

   1. Ejecuta el script base y guarda su resultado en una tabla temporal
   2. Añade columnas para las métricas de data_test_sql
   3. Ejecuta automáticamente cada data_test_sql
   4. Vuelca esas métricas en la misma fila
   5. Devuelve el resultado final en una sola tabla

   ============================================================ */


/* ============================================================
   1. LIMPIEZA
   ============================================================ */

DROP TEMPORARY TABLE IF EXISTS fk_candidates_enriched;
DROP TEMPORARY TABLE IF EXISTS fk_test_result;

DROP PROCEDURE IF EXISTS run_fk_candidate_tests;


/* ============================================================
   2. EJECUTAR EL SCRIPT BASE TAL CUAL Y GUARDAR SU RESULTADO
   ============================================================ */

CREATE TEMPORARY TABLE fk_candidates_enriched AS

WITH base_tables AS (

    SELECT t.TABLE_NAME
    FROM information_schema.TABLES t
    WHERE t.TABLE_SCHEMA = DATABASE()
      AND LOWER(t.TABLE_NAME) REGEXP '^metages_'
      AND LOWER(t.TABLE_NAME) NOT REGEXP '^metages_qa_'
      AND LOWER(t.TABLE_NAME) NOT REGEXP '^metages__tmp'
      AND LOWER(t.TABLE_NAME) NOT REGEXP 'tmp'
      AND LOWER(t.TABLE_NAME) NOT REGEXP 'backup'
      AND LOWER(t.TABLE_NAME) NOT REGEXP 'old'

),

generic_columns AS (

    SELECT 'id' AS col UNION ALL
    SELECT 'nombre' UNION ALL
    SELECT 'name' UNION ALL
    SELECT 'descripcion' UNION ALL
    SELECT 'description' UNION ALL
    SELECT 'definicion' UNION ALL
    SELECT 'definition' UNION ALL
    SELECT 'tipo' UNION ALL
    SELECT 'type' UNION ALL
    SELECT 'codigo' UNION ALL
    SELECT 'code' UNION ALL
    SELECT 'estado' UNION ALL
    SELECT 'status' UNION ALL
    SELECT 'valor' UNION ALL
    SELECT 'value' UNION ALL
    SELECT 'nota' UNION ALL
    SELECT 'note' UNION ALL
    SELECT 'notas' UNION ALL
    SELECT 'notes' UNION ALL
    SELECT 'child_table' UNION ALL
    SELECT 'child_column' UNION ALL
    SELECT 'parent_table' UNION ALL
    SELECT 'parent_column' UNION ALL
    SELECT 'orphan_count' UNION ALL
    SELECT 'audit_timestamp'

),

candidate_columns AS (

    SELECT
        c.TABLE_NAME,
        c.COLUMN_NAME,
        LOWER(c.COLUMN_NAME) AS child_norm
    FROM information_schema.COLUMNS c
    JOIN base_tables bt
      ON bt.TABLE_NAME = c.TABLE_NAME
    WHERE c.TABLE_SCHEMA = DATABASE()

      AND c.COLUMN_KEY <> 'PRI'
      AND LOWER(c.COLUMN_NAME) NOT REGEXP '_fk$'
      AND LOWER(c.COLUMN_NAME) NOT REGEXP '_id$'
      AND LOWER(c.COLUMN_NAME) <> 'id'

      AND LOWER(c.COLUMN_NAME) NOT IN (
          'created_when',
          'created_who',
          'updated_when',
          'updated_who'
      )

      AND LOWER(c.COLUMN_NAME) NOT IN (
          SELECT col FROM generic_columns
      )

      AND NOT EXISTS (
          SELECT 1
          FROM metages_qa_fk_mapping m
          WHERE m.child_table = c.TABLE_NAME
            AND m.child_column = c.COLUMN_NAME
      )

),

pk_columns AS (

    SELECT
        k.TABLE_NAME,
        k.COLUMN_NAME,
        LOWER(k.COLUMN_NAME) AS parent_norm,
        LOWER(
            CASE
                WHEN LOWER(k.COLUMN_NAME) REGEXP '_id$'
                THEN LEFT(k.COLUMN_NAME, CHAR_LENGTH(k.COLUMN_NAME) - 3)
                ELSE k.COLUMN_NAME
            END
        ) AS parent_base_norm,
        LOWER(REPLACE(k.TABLE_NAME, 'metages_', '')) AS table_norm,
        LOWER(
            CASE
                WHEN REPLACE(k.TABLE_NAME, 'metages_', '') REGEXP 's$'
                THEN LEFT(
                    REPLACE(k.TABLE_NAME, 'metages_', ''),
                    CHAR_LENGTH(REPLACE(k.TABLE_NAME, 'metages_', '')) - 1
                )
                ELSE REPLACE(k.TABLE_NAME, 'metages_', '')
            END
        ) AS table_singular_norm
    FROM information_schema.KEY_COLUMN_USAGE k
    JOIN information_schema.TABLE_CONSTRAINTS t
      ON k.CONSTRAINT_NAME = t.CONSTRAINT_NAME
     AND k.TABLE_SCHEMA = t.TABLE_SCHEMA
     AND k.TABLE_NAME = t.TABLE_NAME
    JOIN base_tables bt
      ON bt.TABLE_NAME = k.TABLE_NAME
    WHERE k.TABLE_SCHEMA = DATABASE()
      AND t.CONSTRAINT_TYPE = 'PRIMARY KEY'

),

same_name_parents AS (

    SELECT
        c.TABLE_NAME,
        c.COLUMN_NAME,
        LOWER(c.COLUMN_NAME) AS parent_norm,
        LOWER(REPLACE(c.TABLE_NAME, 'metages_', '')) AS table_norm,
        LOWER(
            CASE
                WHEN REPLACE(c.TABLE_NAME, 'metages_', '') REGEXP 's$'
                THEN LEFT(
                    REPLACE(c.TABLE_NAME, 'metages_', ''),
                    CHAR_LENGTH(REPLACE(c.TABLE_NAME, 'metages_', '')) - 1
                )
                ELSE REPLACE(c.TABLE_NAME, 'metages_', '')
            END
        ) AS table_singular_norm
    FROM information_schema.COLUMNS c
    JOIN base_tables bt
      ON bt.TABLE_NAME = c.TABLE_NAME
    WHERE c.TABLE_SCHEMA = DATABASE()
      AND LOWER(c.COLUMN_NAME) NOT IN (
          SELECT col FROM generic_columns
      )

),

h1_pk_base AS (

    SELECT
        c.TABLE_NAME AS child_table,
        c.COLUMN_NAME AS child_column,
        p.TABLE_NAME AS parent_table,
        p.COLUMN_NAME AS parent_column,
        4 AS score,
        'H1: child = parent_pk_without_id' AS reason
    FROM candidate_columns c
    JOIN pk_columns p
      ON c.TABLE_NAME <> p.TABLE_NAME
     AND c.child_norm = p.parent_base_norm

),

h2_same_col_table_fit AS (

    SELECT
        c.TABLE_NAME AS child_table,
        c.COLUMN_NAME AS child_column,
        p.TABLE_NAME AS parent_table,
        p.COLUMN_NAME AS parent_column,
        4 AS score,
        'H2: same column and column ≈ parent table' AS reason
    FROM candidate_columns c
    JOIN same_name_parents p
      ON c.TABLE_NAME <> p.TABLE_NAME
     AND c.child_norm = p.parent_norm
    WHERE
        p.table_norm = c.child_norm
        OR p.table_singular_norm = c.child_norm
        OR c.child_norm LIKE CONCAT('%', p.table_norm, '%')
        OR c.child_norm LIKE CONCAT('%', p.table_singular_norm, '%')
        OR p.table_norm LIKE CONCAT('%', c.child_norm, '%')
        OR p.table_singular_norm LIKE CONCAT('%', c.child_norm, '%')

),

h3_same_structured_name AS (

    SELECT
        c.TABLE_NAME AS child_table,
        c.COLUMN_NAME AS child_column,
        p.TABLE_NAME AS parent_table,
        p.COLUMN_NAME AS parent_column,
        2 AS score,
        'H3: same structured non-generic column name' AS reason
    FROM candidate_columns c
    JOIN same_name_parents p
      ON c.TABLE_NAME <> p.TABLE_NAME
     AND c.child_norm = p.parent_norm
    WHERE
        (
            INSTR(c.child_norm, '_') > 0
            OR CHAR_LENGTH(c.child_norm) >= 12
        )

),

all_candidates AS (

    SELECT * FROM h1_pk_base
    UNION ALL
    SELECT * FROM h2_same_col_table_fit
    UNION ALL
    SELECT * FROM h3_same_structured_name

),

deduplicated AS (

    SELECT
        child_table,
        child_column,
        parent_table,
        parent_column,
        MAX(score) AS score,
        GROUP_CONCAT(DISTINCT reason ORDER BY reason SEPARATOR ' | ') AS reasons
    FROM all_candidates
    GROUP BY
        child_table,
        child_column,
        parent_table,
        parent_column

)

SELECT
    child_table,
    child_column,
    parent_table,
    parent_column,
    score,
    reasons,
CONCAT(
'SELECT ''', child_table, '.', child_column,
' -> ', parent_table, '.', parent_column,
''' AS relation_test, ',

'COUNT(DISTINCT NULLIF(TRIM(c.`', REPLACE(child_column, '`', '``'), '`),'''')) AS child_distinct, ',
'COUNT(DISTINCT NULLIF(TRIM(p.`', REPLACE(parent_column, '`', '``'), '`),'''')) AS parent_distinct, ',

'COUNT(DISTINCT CASE 
    WHEN NULLIF(TRIM(p.`', REPLACE(parent_column, '`', '``'), '`),'''') IS NOT NULL 
    THEN NULLIF(TRIM(c.`', REPLACE(child_column, '`', '``'), '`),'''') 
END) AS child_values_matching_parent, ',

'ROUND(100 * COUNT(DISTINCT CASE 
    WHEN NULLIF(TRIM(p.`', REPLACE(parent_column, '`', '``'), '`),'''') IS NOT NULL 
    THEN NULLIF(TRIM(c.`', REPLACE(child_column, '`', '``'), '`),'''') 
END) / NULLIF(COUNT(DISTINCT NULLIF(TRIM(c.`', REPLACE(child_column, '`', '``'), '`),'''')),0), 2)
AS pct_child_covered_by_parent, ',

'ROUND(100 * COUNT(DISTINCT CASE 
    WHEN NULLIF(TRIM(c.`', REPLACE(child_column, '`', '``'), '`),'''') IS NOT NULL 
    THEN NULLIF(TRIM(p.`', REPLACE(parent_column, '`', '``'), '`),'''') 
END) / NULLIF(COUNT(DISTINCT NULLIF(TRIM(p.`', REPLACE(parent_column, '`', '``'), '`),'''')),0), 2)
AS pct_parent_used_by_child ',

'FROM `', REPLACE(child_table, '`', '``'), '` c ',
'LEFT JOIN `', REPLACE(parent_table, '`', '``'), '` p ',
'ON CONVERT(NULLIF(TRIM(c.`', REPLACE(child_column,'`','``'), '`),'''') USING utf8mb4) ',
' = CONVERT(NULLIF(TRIM(p.`', REPLACE(parent_column,'`','``'), '`),'''') USING utf8mb4) ',
'WHERE CONVERT(NULLIF(TRIM(c.`', REPLACE(child_column,'`','``'), '`),'''') USING utf8mb4) IS NOT NULL;'
) AS data_test_sql
FROM deduplicated
ORDER BY
    score DESC,
    child_table,
    child_column,
    parent_table
;


/* ============================================================
   3. AÑADIR ID Y COLUMNAS DE RESULTADO
   ============================================================ */

ALTER TABLE fk_candidates_enriched
ADD COLUMN candidate_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST,
ADD COLUMN child_distinct INT NULL,
ADD COLUMN parent_distinct INT NULL,
ADD COLUMN child_values_matching_parent INT NULL,
ADD COLUMN pct_child_covered_by_parent DECIMAL(10,2) NULL,
ADD COLUMN pct_parent_used_by_child DECIMAL(10,2) NULL;


/* ============================================================
   4. TABLA TEMPORAL AUXILIAR PARA CADA EJECUCIÓN
   ============================================================ */

CREATE TEMPORARY TABLE fk_test_result (
    relation_test VARCHAR(1000),
    child_distinct INT,
    parent_distinct INT,
    child_values_matching_parent INT,
    pct_child_covered_by_parent DECIMAL(10,2),
    pct_parent_used_by_child DECIMAL(10,2)
);


/* ============================================================
   5. PROCEDIMIENTO: EJECUTAR CADA data_test_sql Y VOLCAR RESULTADOS
   ============================================================ */

DELIMITER $$

CREATE PROCEDURE run_fk_candidate_tests()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_candidate_id INT;
    DECLARE v_sql LONGTEXT;

    DECLARE cur CURSOR FOR
        SELECT candidate_id, data_test_sql
        FROM fk_candidates_enriched
        ORDER BY candidate_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_candidate_id, v_sql;

        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        TRUNCATE TABLE fk_test_result;

        SET @insert_sql = CONCAT(
            'INSERT INTO fk_test_result ',
            v_sql
        );

        PREPARE stmt_insert FROM @insert_sql;
        EXECUTE stmt_insert;
        DEALLOCATE PREPARE stmt_insert;

        UPDATE fk_candidates_enriched c
        JOIN fk_test_result r
          ON 1 = 1
        SET
            c.child_distinct = r.child_distinct,
            c.parent_distinct = r.parent_distinct,
            c.child_values_matching_parent = r.child_values_matching_parent,
            c.pct_child_covered_by_parent = r.pct_child_covered_by_parent,
            c.pct_parent_used_by_child = r.pct_parent_used_by_child
        WHERE c.candidate_id = v_candidate_id;

    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;


/* ============================================================
   6. EJECUTAR
   ============================================================ */

CALL run_fk_candidate_tests();


/* ============================================================
   7. RESULTADO FINAL
   ============================================================ */

SELECT
    child_table,
    child_column,
    parent_table,
    parent_column,
    score,
    reasons,
    child_distinct,
    parent_distinct,
    child_values_matching_parent,
    pct_child_covered_by_parent,
    pct_parent_used_by_child,
    data_test_sql
FROM fk_candidates_enriched
ORDER BY
    score DESC,
    child_table,
    child_column,
    parent_table;


/* ============================================================
   8. LIMPIEZA OPCIONAL
   ============================================================ */

DROP PROCEDURE IF EXISTS run_fk_candidate_tests;