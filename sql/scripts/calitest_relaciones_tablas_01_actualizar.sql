/* ============================================================
   ACTUALIZACIÓN DEL MAPEO DE RELACIONES
   ============================================================

   Este script detecta columnas *_fk en tablas metages_*
   y las añade a qa_fk_mapping si no existen.

   Puede ejecutarse múltiples veces sin riesgo.

   Gracias a:
       UNIQUE(child_table, child_column)
       INSERT IGNORE

   los registros existentes NO se modifican.

   Las nuevas relaciones entran con:

       validation_status = 'PENDING'

   y se validarán posteriormente con el script 03.

   ============================================================ */


INSERT IGNORE INTO qa_fk_mapping (

    child_table,
    child_column,
    parent_table,
    parent_column,
    confidence,
    notes,
    validation_status,
    validation_message

)

SELECT
    c.table_name,
    c.column_name,
    CONCAT('metages_', REPLACE(c.column_name,'_fk','')),
    CONCAT(REPLACE(c.column_name,'_fk',''),'_id'),
    'auto',
    'detectado automáticamente por convención *_fk',
    'PENDING',
    NULL

FROM information_schema.columns c

WHERE c.table_schema = DATABASE()
AND c.table_name LIKE 'metages_%'
AND c.column_name LIKE '%\\_fk';



/* ============================================================
   RELACIONES ESPECIALES
   ============================================================

UPDATE qa_fk_mapping
SET
    parent_table = 'metages_body',
    parent_column = 'body_id',
    confidence = 'manual',
    notes = 'corrección relación ispartof',
    validation_status = 'PENDING',
    validation_message = NULL
WHERE child_table = 'metages_ispartof'
AND child_column = 'child_body_fk';


UPDATE qa_fk_mapping
SET
    parent_table = 'metages_body',
    parent_column = 'body_id',
    confidence = 'manual',
    notes = 'corrección relación ispartof',
    validation_status = 'PENDING',
    validation_message = NULL
WHERE child_table = 'metages_ispartof'
AND child_column = 'parent_body_fk'; */
