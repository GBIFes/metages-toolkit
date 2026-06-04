-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-04-28
-- Descripción: Vista que relaciona paginas de gbif.es con el archivo 
--              .php que la genera. Permite conocer el nombre del archivo 
--              que codifica una pagina, para buscarlo, encontrarlo y analizarlo
--              o modificarlo	
-- Base de datos: gbif_wp
-- Vista: codigo_web_gbifes
-- 
-- ===================================================================

 CREATE OR REPLACE VIEW codigo_web_gbifes AS


SELECT wp.ID, wp.post_name, wp.post_title, wp.post_content, wp2.meta_key, wp2.meta_value 
FROM wp_posts wp 
LEFT JOIN wp_postmeta wp2 ON wp.ID = wp2.post_id 
WHERE wp2.meta_value LIKE '%.php'
-- AND wp.post_name LIKE 'contacto' -- Escribir aqui nombre del slug de la pagina