/* ============================================================
   AUDITOR DE HUÉRFANOS
   ============================================================

   Este script audita huérfanos usando metages_qa_fk_mapping.

   Solo evalúa relaciones:
   - enabled = TRUE
   - validation_status = 'VALID'

   El resultado se guarda en la tabla permanente:
       metages_qa_orphan_report

   ============================================================ */


/* ============================================================
   1. CREAR TABLA DE RESULTADOS SI NO EXISTE
   ============================================================ */

CREATE TABLE IF NOT EXISTS metages_qa_orphan_report (

    child_table VARCHAR(255) NOT NULL,
    child_column VARCHAR(255) NOT NULL,
    parent_table VARCHAR(255) NOT NULL,
    parent_column VARCHAR(255) NOT NULL,
    orphan_count INT NOT NULL,
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);


/* ============================================================
   2. LIMPIAR RESULTADOS ANTERIORES
   ============================================================ */

TRUNCATE TABLE metages_qa_orphan_report;


/* ============================================================
   3. GENERAR UNA ÚNICA SENTENCIA SQL
   ============================================================ */

SET SESSION group_concat_max_len = 1000000;

SELECT CONCAT(
    'INSERT INTO metages_qa_orphan_report ',
    '(child_table, child_column, parent_table, parent_column, orphan_count) ',
    GROUP_CONCAT(
        CONCAT(
            'SELECT ',
            QUOTE(child_table), ', ',
            QUOTE(child_column), ', ',
            QUOTE(parent_table), ', ',
            QUOTE(parent_column), ', ',
            'COUNT(*) AS orphan_count ',
            'FROM ', child_table, ' c ',
            'LEFT JOIN ', parent_table, ' p ',
            'ON c.', child_column, ' = p.', parent_column, ' ',
            'WHERE p.', parent_column, ' IS NULL ',
            'AND c.', child_column, ' IS NOT NULL'
        )
        SEPARATOR ' UNION ALL '
    )
) INTO @sql_audit
FROM metages_qa_fk_mapping
WHERE enabled = TRUE
  AND validation_status = 'VALID';


/* ============================================================
   4. DEPURACIÓN OPCIONAL
   ============================================================ */

SELECT @sql_audit;


/* ============================================================
   5. EJECUTAR AUDITORÍA
   ============================================================ */

SET @sql_audit = IFNULL(@sql_audit, 'SELECT 1');

PREPARE stmt FROM @sql_audit;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;


/* ============================================================
   6. VER INFORME FINAL
   ============================================================ */

SELECT *
FROM metages_qa_orphan_report
ORDER BY orphan_count DESC, child_table, child_column;