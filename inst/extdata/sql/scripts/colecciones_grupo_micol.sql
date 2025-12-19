-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Esta vista muestra todas las colecciones micologicas 
--              registradas en la base de datos, incluyendo 
--              información básica de la colección, disciplina, 
--              dirección y tipo de entidad.
-- Base de datos: gbif_wp
-- Vista: colecciones_grupo_micol
-- ===================================================================


-- ===================================================================
-- Crear o reemplazar la vista colecciones_grupo_micol
-- ===================================================================
CREATE OR REPLACE VIEW colecciones_grupo_micol AS

SELECT *
FROM colecciones AS c
WHERE disciplina_id = 9;