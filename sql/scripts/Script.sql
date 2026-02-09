SET @year1 = 2014;
SET @year2 = 2019;

SELECT *
FROM (
  -- disciplinas
  SELECT
    disciplina AS categoria,
    COUNT(DISTINCT CASE WHEN anho = @year1 THEN body_id END) AS colecciones_2014,
    SUM(CASE WHEN anho = @year1 THEN registros END) AS registros_2014,
    COUNT(DISTINCT CASE WHEN anho = @year2 THEN body_id END) AS colecciones_2019,
    SUM(CASE WHEN anho = @year2 THEN registros END) AS registros_2019,
    0 AS nivel
  FROM colecciones
  GROUP BY disciplina

  UNION ALL

  -- subdisciplinas
  SELECT
    subdisciplina AS categoria,
    COUNT(DISTINCT CASE WHEN anho = @year1 THEN collection_id END),
    SUM(CASE WHEN anho = @year1 THEN registros END),
    COUNT(DISTINCT CASE WHEN anho = @year2 THEN collection_id END),
    SUM(CASE WHEN anho = @year2 THEN registros END),
    1 AS nivel
  FROM tabla_base
  WHERE subdisciplina IS NOT NULL
  GROUP BY subdisciplina
) t
ORDER BY nivel, categoria;

