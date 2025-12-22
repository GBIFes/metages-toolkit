-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Vista base que consolida la información de todas las 
--              colecciones (zoológicas, botánicas, mixtas, 
--              micropaleontológicas y paleontológicas), incluyendo 
--              los datos de disciplina, tipo de entidad, ubicación y 
--              estado de publicación en GBIF.
-- Base de datos: gbif_wp
-- Vista: colecciones
-- 
-- ===================================================================

-- CREATE OR REPLACE VIEW colecciones AS

SELECT 
    mb.body_id,
    parent.institucion_proyecto,
    parent.url_institucion, 
    mb.citation AS coleccion_base,
    CONCAT('https://gbif.es/coleccion/', mb.url, '/') as coleccion_url,
    mb.collection_code,
    mb.number_of_subunits,
    mb.percent_database,
    mb.percent_georref, 
    md.disciplina_def,
    mds.disciplina_subtipo_def, 
    ma.town,
    mt.LAT AS latitude,
    mt.`LONG` AS longitude, 
    ma.region,
    CASE
        WHEN mb.body_type_fk = 3 THEN 'coleccion'
        WHEN mb.body_type_fk = 5 THEN 'base de datos'
    END AS tipo_body,
    COALESCE(r.publica_en_gbif, 0) AS publica_en_gbif, 
    r.numberOfRecords, 
    YEAR(mb.created_when) AS fecha_alta_coleccion,
    r.ultima_actualizacion_recursos, 
    md.disciplina_id ,
    mb.condiciones_col,
    mb.acceso_col AS acceso_ejemplares,
    mb.acceso_informatizado, 
    mb.medio_acceso,
    mit.Abreviatura AS software_gestion_col 
FROM metages_body AS mb       
LEFT JOIN metages_disciplina AS md								-- Anhadir disciplina de la coleccion (Zoologica, Botanica, etc)  
    ON mb.disciplina_fk = md.disciplina_id
LEFT JOIN metages_body_disciplina_subtipo mbds 
	ON mb.body_id = mbds.body_fk 
LEFT JOIN metages_disciplina_subtipo mds 						-- Anhadir disciplina subtipo de la coleccion (Plantas, Hongos, etc)
	ON mbds.disciplina_subtipo_fk = mds.disciplina_subtipo_id 
LEFT JOIN metages_address AS ma 								-- Anhadir ciudades donde se gestiona cada coleccion (para mapas)
    ON mb.address_fk = ma.address_id
LEFT JOIN metages_informati_tbl mit                             -- Anhadir software de gestion de colecciones
	ON mb.informati_tbl_fk = mit.Informati_id 
LEFT JOIN (														-- Anhadir numero de registros publicados por coleccion
    SELECT 
        r2.body_fk,
        MAX(r2.publica_en_gbif) AS publica_en_gbif,
        SUM(r2.numberOfRecords) AS numberOfRecords,
        MAX(r2.ultima_actualizacion) AS ultima_actualizacion_recursos
    FROM registros AS r2
    GROUP BY body_fk
) AS r
    ON mb.body_id = r.body_fk
LEFT JOIN (SELECT mip.child_body_fk, 							-- Anhadir institucion a cada coleccion
				  mb.citation AS institucion_proyecto, 
				  CASE
			          WHEN mb.body_type_fk = 2 THEN CONCAT('https://gbif.es/instituciones/', mb.url, '/')
			          WHEN mb.body_type_fk = 4 THEN CONCAT('https://gbif.es/proyectos/', mb.url, '/')
			      END AS url_institucion
		   FROM metages_ispartof mip
		   LEFT JOIN metages_body mb
		   ON mip.parent_body_fk = mb.body_id
		   WHERE mb.private = 0) AS parent
ON mb.body_id = parent.child_body_fk 
LEFT JOIN metages_towns mt 										-- Anhadir coordenadas de cada ciudad (para mapa)
ON ma.town = mt.town 
WHERE mb.body_type_fk IN (3, 5)
  AND mb.disciplina_fk BETWEEN 6 AND 11
  AND mb.private = 0;
