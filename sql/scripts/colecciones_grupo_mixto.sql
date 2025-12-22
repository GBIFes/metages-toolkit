-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-03
-- Descripción: Esta vista muestra todas las colecciones mixtas 
--              registradas en la base de datos, incluyendo 
--              información básica de la colección, disciplina, 
--              dirección y tipo de entidad.
-- Base de datos: gbif_wp
-- Vista: colecciones_grupo_mixto
-- ===================================================================


-- ===================================================================
-- Crear o reemplazar la vista colecciones_grupo_mixto
-- ===================================================================
CREATE OR REPLACE VIEW colecciones_grupo_mixto AS

SELECT *
FROM colecciones AS c
WHERE disciplina_id = 7;