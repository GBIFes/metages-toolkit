/* ============================================================
   GENERAR CONSULTAS DE INSPECCIÓN DE HUÉRFANOS
   ============================================================ */

SELECT
CONCAT(

'/* ',
CONVERT(child_table USING utf8mb4), '.', CONVERT(child_column USING utf8mb4),
' → ',
CONVERT(parent_table USING utf8mb4), '.', CONVERT(parent_column USING utf8mb4),
' | huerfanos: ', orphan_count,
' */\n',

'SELECT c.* \n',
'FROM ', CONVERT(child_table USING utf8mb4),' c \n',
'LEFT JOIN ', CONVERT(parent_table USING utf8mb4),' p \n',
'ON c.',CONVERT(child_column USING utf8mb4),' = p.',CONVERT(parent_column USING utf8mb4),' \n',
'WHERE p.',CONVERT(parent_column USING utf8mb4),' IS NULL \n',
'AND c.',CONVERT(child_column USING utf8mb4),' IS NOT NULL;\n\n'

) AS inspection_query

FROM qa_orphan_report
WHERE orphan_count > 0
ORDER BY orphan_count DESC;