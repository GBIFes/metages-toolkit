-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-18
-- Última actualización: /
-- 
-- Descripción:
--   Esta vista crea emails personalizados para cada gestor de una colección 
--   institución o proyecto
-- 
-- Asunto:
-- 	Revisión del registro de colecciones de GBIF España
-- 
-- Base de datos: gbif_wp
-- Vista: contactos_entidades_email
-- ===================================================================

-- CREATE OR REPLACE VIEW contactos_entidades_email AS

SELECT email AS A,
	    CONCAT_WS(
	    	CONCAT(CHAR(13), CHAR(10)),
	    	CASE
			    WHEN given_name IS NOT NULL AND given_name <> '' THEN
			        CONCAT('Buenos días ', given_name, ',')
			    ELSE
			        CONCAT('Buenos días,')
			END,
	    	'',
	    	'Soy Rubén Pérez Pérez, de la Unidad de Coordinación de GBIF España.', 
	    	'',
			'',
			'Escribo para comunicarles que estamos trabajando en una nueva versión del "Informe de colecciones biológicas y bases de datos de biodiversidad de GBIF España" y necesitamos que la información del registro esté lo más actualizada posible.',
			'',
			CONCAT('Su ficha de ', tipo_entidad, ': "', nombre_entidad, '" fue actualizada por última vez en ', 
					last_updated, '. Agradeceríamos si fueran tan amables de revisarla en ', url, 
					' y comunicarnos los cambios que sean necesarios.'),
			'',
			'Para reportar las modificaciones pertinentes pueden: ',
			'   - Incluir los cambios como respuesta a este email (si los cambios fueran mínimos)',
			CONCAT('   - Rellenar un nuevo cuestionario desde ',
					CASE
					    WHEN tipo_entidad = 'institución' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-instituciones-y-proyectos/institucion/'
					    WHEN tipo_entidad = 'proyecto' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-instituciones-y-proyectos/proyecto/'
					    WHEN tipo_entidad = 'colección' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-colecciones-biologicas-y-bases-de-datos/' -- Poner cuestionario especifico cuando se separen las bases de datos de este body_type
					    WHEN tipo_entidad = 'base de datos' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-colecciones-biologicas-y-bases-de-datos/base de datos/'
					END,
					' (si los cambios fueran más extensos).'),
			'',
			'',
			'Pueden consultar la última versión del Informe en: ',
			'https://www.gbif.es/wp-content/uploads/2021/10/Informe_colecciones2021.pdf',
			'',
			'Muchas gracias,'
			) AS mensaje 
		
FROM contactos_entidades AS ce

-- Filtrar si fuera necesario a un subset del registro
-- WHERE (ce.body_id IN (781, 793) OR ce.parent_body_id IN (781, 793))
-- AND (ce.nombre_entidad LIKE '%olec%' OR ce.nombre_entidad LIKE '%erbar%' )






/*
INTENTO FALLIDO:
En lugar de crear cada email por separado en SQL, intenté automatizarlo desde Word-Outlook
Despues de problemas de encoding y separadores no escapados, encontré el problema que me hizo cambiar de idea:

Word no es capaz de mandar el mismo mensaje a varios destinatarios, 
la única opción era mandar los mensajes separados (por ahora).
Eso no es factible porque queremos notificar al equipo completo y que estén al tanto 
de que todos están informados para evitar varias propuestas de actualización.

La mejor version de este ejercicio se presenta arriba, donde el output permite copiar-pegar
el mensaje y los destinatarios. No es automatico, pero ahorra mucho trabajo.



SELECT email,
		CASE
		    WHEN given_name IS NOT NULL AND given_name <> '' THEN
		        CONCAT('Buenos días ', given_name, ',')
		    ELSE
		        CONCAT('Buenos días,')
		END AS intro,
		tipo_entidad,
	    nombre_entidad,
	    url AS url_entidad,
	    last_updated,
	    CASE
		    WHEN tipo_entidad = 'institución' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-instituciones-y-proyectos/institucion/'
		    WHEN tipo_entidad = 'proyecto' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-instituciones-y-proyectos/proyecto/'
		    WHEN tipo_entidad = 'colección' THEN 'https://gbif.es/datos-biodiversidad/accede-a-los-datos/registro/cuestionario-para-colecciones-biologicas-y-bases-de-datos/'
		END AS cuestionario
FROM contactos_entidades
-- Filtrar si fuera necesario a un subset del registro
WHERE (body_id IN (781, 793) OR parent_body_id IN (781, 793))
AND (nombre_entidad LIKE '%olec%' OR nombre_entidad LIKE '%erbar%' )

*/