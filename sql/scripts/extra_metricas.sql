-- Tipos y número de entidades

SELECT COUNT(*) AS '2014', mb.body_type, mb.body_type_id   
FROM metages_bodytype mb 
LEFT JOIN metages_body mb2 ON mb.body_type_id = mb2.body_type_fk
WHERE private = 0
AND mb2.created_when < '2014-01-01'
GROUP BY body_type, mb.body_type_id;  

SELECT COUNT(*) AS '2019', mb.body_type, mb.body_type_id   
FROM metages_bodytype mb 
LEFT JOIN metages_body mb2 ON mb.body_type_id = mb2.body_type_fk
WHERE private = 0
AND mb2.created_when < '2019-01-01'
GROUP BY body_type, mb.body_type_id;  

SELECT COUNT(*), mb.body_type, mb.body_type_id   
FROM metages_bodytype mb 
LEFT JOIN metages_body mb2 ON mb.body_type_id = mb2.body_type_fk
WHERE private = 0
-- AND mb2.disciplina_fk BETWEEN 6 AND 11
GROUP BY body_type, mb.body_type_id;  





-- Número de juegos de datos publicados
-- Diferentes de la info en https://ipt.gbif.es/ == 553
-- Diferentes a la informacion en https://www.gbif.org/dataset/search?publishing_country=ES == 605

-- EXPLICACION potencial: Metages no tiene datos de GBIF.org o IPT y hay otras datasets de GBIF.ES
-- que se publican desde otros IPTs y que no se registran en Metages. 
WITH recurso_limpio AS (
	SELECT mr.*, YEAR(mr.created_when) AS fecha FROM metages_recurso mr 
	WHERE mr.publica_en_gbif = 1
	AND mr.private = 0)

SELECT COUNT(*) AS numero_recursos, MAX(fecha) + 1 AS fecha -- Se añade 1 para especificar que los datos compilan el año anterior completo (En este caso, hasta final de 2013, que es lo mismo que a inicios de 2014)
FROM recurso_limpio  
WHERE fecha < '2014'
UNION
SELECT COUNT(*) AS numero_recursos, MAX(fecha) + 1 AS fecha 
FROM recurso_limpio 
WHERE fecha < '2019'
UNION
SELECT COUNT(*) AS numero_recursos, YEAR(CURDATE()) AS fecha
FROM recurso_limpio;


-- Número de registros publicados
-- Publishing: https://www.gbif.org/country/ES/publishing == 75,072,217
-- About: https://www.gbif.org/country/ES/about == 94,166,450
-- R: TO-DO





-- Proporcion de Condiciones de las colecciones
SELECT COUNT(*), c.condiciones_col 
FROM colecciones c 
GROUP BY condiciones_col 


-- Top 10 colecciones con más ejemplares por disciplina
SELECT coleccion_base,
	   collection_code,
	   number_of_subunits,
	   disciplina_def
FROM (SELECT c.*,
			ROW_NUMBER() OVER (
				PARTITION BY c.disciplina_def
				ORDER BY c.number_of_subunits DESC) AS rn
	  FROM colecciones c
	  WHERE c.number_of_subunits > 0) AS sub  
WHERE rn <= 10
ORDER BY disciplina_def, number_of_subunits DESC;



-- Top 10 recursos con más registros por disciplina
SELECT title,
	   num_records AS numberOfRecords,
	   disciplina_def
FROM (
	SELECT r.title,
		   r.disciplina_def,
		   CAST(r.numberOfRecords AS UNSIGNED) AS num_records,
		   ROW_NUMBER() OVER (
				PARTITION BY r.disciplina_def
				ORDER BY CAST(r.numberOfRecords AS UNSIGNED) DESC
							) AS rn
	FROM registros r
	  ) AS sub  
WHERE rn <= 10
ORDER BY disciplina_def, num_records DESC;
