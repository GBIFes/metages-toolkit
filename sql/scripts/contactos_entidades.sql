-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-10-14
-- Última actualización: 2025-11-17
-- 
-- Descripción:
--   Esta vista muestra los datos de contacto de cada entidad 
--   (instituciones, colecciones y proyectos), combinando:
--    
--     - Contactos personales e institucional
--     - URLs públicas en gbif.es
--     - Datos asociados a los recursos IPT (titulo y URLs del IPT y el portal)
--   La vista produce UNA fila por entidad (body_id).
-- 
-- Base de datos: gbif_wp
-- Vista: contactos_entidades
-- ===================================================================
-- CREATE OR REPLACE VIEW contactos_entidades AS


-- Vinculamos datos de personas y entidades
WITH email_personal AS (
	SELECT mb.body_id,
		   mpr.given_name,
	       mpr.family_name,
	       mpr.job_title,
	       mps.pers_email_pref
	FROM metages_body AS mb 
	LEFT JOIN metages_personinbody AS mp       ON mb.body_id = mp.body_fk
	LEFT JOIN metages_person AS mpr           ON mp.person_fk = mpr.person_id
	LEFT JOIN metages_personas AS mps           ON mpr.person_id = mps.person_fk
),


-- Unimos emails personales e institucionales para deduplicarlos por entidad despues
 email_todos AS (
    SELECT 
        mb.body_id,
        TRIM(jt.email) AS pers_email_pref
    FROM metages_address AS ma
    LEFT JOIN metages_body AS mb ON ma.address_id = mb.address_fk
    -- Limpia correos para poder deduplicarlos en el UNION
    JOIN JSON_TABLE(CONCAT('["',
				            CASE
				                WHEN ma.pers_email_pref LIKE '%/%' THEN
				                    REPLACE(ma.pers_email_pref, '/', '","')
				                ELSE
				                    REPLACE(ma.pers_email_pref, ';', '","')
				            END,
            				'"]'),
        '$[*]' COLUMNS (email VARCHAR(255) PATH '$')) AS jt

    UNION DISTINCT

    -- Emails personales (sin tocar)
    SELECT 
        body_id,
        TRIM(pers_email_pref) AS pers_email_pref
    FROM email_personal
),


-- Informacion sobre los recursos de cada entidad
numero_recursos AS (
    SELECT
        mb.body_id,
        mb.citation,

        SUM(mr.numberOfRecords) AS records_IPT,

        GROUP_CONCAT(mr.url_ipt SEPARATOR ' || ') AS urls_ipt,
        GROUP_CONCAT(mr.url_iso SEPARATOR ' || ') AS urls_portal,
        GROUP_CONCAT(mr.title SEPARATOR ' || ') AS ipt_titles,

        COUNT(NULLIF(mr.url_ipt, '')) AS records_IPT_por_entidad

    FROM metages_body AS mb
    LEFT JOIN metages_recurso AS mr
           ON mb.body_id = mr.body_fk
    WHERE mb.private = 0
    GROUP BY mb.body_id, mb.citation
),


-- Juntamos tablas anteriores con body
contactos_entidades AS (
	SELECT DISTINCT
        mb.body_id,
        isp.parent_body_fk AS parent_body_id,
        mb.citation AS nombre_entidad,
        DATE(COALESCE(mb.updated_when, mb.created_when)) AS last_updated,

        CASE
            WHEN mb.body_type_fk = 2 THEN 'institución'
            WHEN mb.body_type_fk = 3 THEN 'colección'
            WHEN mb.body_type_fk = 4 THEN 'proyecto'
            WHEN mb.body_type_fk = 5 THEN 'base de datos'
        END AS tipo_entidad,
        
        et.pers_email_pref,
        ep.given_name,
	    ep.family_name,
	    ep.job_title,

        CASE
            WHEN mb.body_type_fk = 2 THEN CONCAT('https://gbif.es/instituciones/', mb.url, '/')
            WHEN mb.body_type_fk IN (3, 5) THEN CONCAT('https://gbif.es/coleccion/', mb.url, '/')
            WHEN mb.body_type_fk = 4 THEN CONCAT('https://gbif.es/proyectos/', mb.url, '/')
        END AS url,
        
        urls_portal,
	    records_IPT,
	    records_IPT_por_entidad,
	    urls_ipt,
	    ipt_titles

    FROM metages_body AS mb
    LEFT JOIN metages_ispartof AS isp  		ON isp.child_body_fk = mb.body_id
	LEFT JOIN numero_recursos AS nr			ON mb.body_id = nr.body_id
	LEFT JOIN email_todos AS et				ON mb.body_id = et.body_id
	LEFT JOIN email_personal AS ep			ON et.pers_email_pref = ep.pers_email_pref

    WHERE mb.body_type_fk IN (2, 3, 4, 5)
      AND mb.private = 0
	  AND TRIM(et.pers_email_pref) <> ''
	  AND et.pers_email_pref IS NOT NULL
	  )


SELECT DISTINCT
	body_id,
    parent_body_id,
    nombre_entidad,
    last_updated,
    tipo_entidad,
    url,
    GROUP_CONCAT(given_name SEPARATOR '; ') AS given_name,
    GROUP_CONCAT(DISTINCT
            given_name, ' ', family_name
            SEPARATOR ', '
        ) AS nombre_contacto,
    GROUP_CONCAT(DISTINCT pers_email_pref SEPARATOR ', ') AS email,
    GROUP_CONCAT(job_title SEPARATOR '; ') AS job_titles,
    urls_portal,
    records_IPT,
    records_IPT_por_entidad,
    urls_ipt,
    ipt_titles

FROM contactos_entidades
GROUP BY body_id,
    parent_body_id,
    nombre_entidad,
    last_updated,
    tipo_entidad,
    url,     
    urls_portal,
    records_IPT,
    records_IPT_por_entidad,
    urls_ipt,
    ipt_titles
 ORDER BY records_IPT DESC
     