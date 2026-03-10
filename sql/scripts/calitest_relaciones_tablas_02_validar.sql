/* ============================================================
   VALIDACIÓN DEL MAPEO
   ============================================================

   Este script valida cada relación de metages_qa_fk_mapping y guarda
   el resultado directamente en la tabla.

   Se verifican:

   - existencia de tabla hija
   - existencia de columna hija
   - existencia de tabla padre
   - existencia de columna padre

   ============================================================ */


UPDATE metages_qa_fk_mapping m

LEFT JOIN information_schema.tables ct
ON ct.table_schema = DATABASE()
AND ct.table_name = m.child_table

LEFT JOIN information_schema.columns cc
ON cc.table_schema = DATABASE()
AND cc.table_name = m.child_table
AND cc.column_name = m.child_column

LEFT JOIN information_schema.tables pt
ON pt.table_schema = DATABASE()
AND pt.table_name = m.parent_table

LEFT JOIN information_schema.columns pc
ON pc.table_schema = DATABASE()
AND pc.table_name = m.parent_table
AND pc.column_name = m.parent_column

SET

m.validation_status =

CASE
WHEN ct.table_name IS NULL THEN 'INVALID'
WHEN cc.column_name IS NULL THEN 'INVALID'
WHEN pt.table_name IS NULL THEN 'INVALID'
WHEN pc.column_name IS NULL THEN 'INVALID'
ELSE 'VALID'
END,

m.validation_message =

CASE
WHEN ct.table_name IS NULL
THEN 'child table does not exist'

WHEN cc.column_name IS NULL
THEN 'child column does not exist'

WHEN pt.table_name IS NULL
THEN 'parent table does not exist'

WHEN pc.column_name IS NULL
THEN 'parent column does not exist'

ELSE NULL
END

WHERE m.enabled = TRUE;