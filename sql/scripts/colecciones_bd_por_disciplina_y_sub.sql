-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-02-02
-- Descripción: Numero de bases de datos y registros por disciplina y subdisciplina
--              
-- Base de datos: gbif_wp
-- Vista: colecciones_bd_por_disciplina_y_sub
-- ===================================================================


-- CREATE OR REPLACE VIEW colecciones_bd_por_disciplina_y_sub AS 

SELECT
  disciplina,
  n_bases_datos,
  n_bases_datos_publican,
  n_registros_publicados
FROM (
  -- por disciplina
  SELECT
    c.disciplina_def AS disciplina,
    COUNT(*) AS n_bases_datos,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_bases_datos_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'base de datos'
  GROUP BY c.disciplina_def

  UNION ALL
  
  -- por subdisciplina
  SELECT
    c.disciplina_subtipo_def AS disciplina,
    COUNT(*) AS n_bases_datos,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_bases_datos_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'base de datos'
  AND disciplina_subtipo_def IS NOT NULL
  GROUP BY c.disciplina_subtipo_def

  UNION ALL

  -- TOTAL disciplinas
  SELECT
    'TOTAL' AS disciplina,
    COUNT(*) AS n_bases_datos,
    COUNT(
      CASE
        WHEN c.publica_en_gbif = 1 THEN 1
      END
    ) AS n_bases_datos_publican,
	SUM(c.numberOfRecords) AS n_registros_publicados
  FROM colecciones c
  WHERE c.tipo_body = 'base de datos'
) AS t;
