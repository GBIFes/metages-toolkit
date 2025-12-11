-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2025-11-28
-- Última actualización: /
-- 
-- Descripción:
--   Estas consultas buscan a donde en metages ha viajado la informacion de un cuestionario especifico 
--   Servirian para:
--     - Disenhar una consulta que borre informacion de todos los sitios donde sea necesario 
--   		al hacer un cuestionario de prueba
--     - Juntar toda la informacion relevante a un cuestionario (ej. Para testar si los cuestionarios funcionan)
-- 

-- Atención:
-- No toda la información se crea de nuevo en cada tabla al rellenar un cuestionario. A veces se vincula a información ya existente para no crear dúplicas, por lo que borrar esos datos tiene que hacerse cautelosamente para asegurarnos de que no se borra información válida. 
 
-- Pasos futuros (opcional):
-- Crear un script que encuentre toda la informacion en metages sobre un body determinado
-- Modificar el script anterior para que borre la información de todos esos sitios cuando sea necesario sin eliminar información ya existente

-- Base de datos: gbif_wp
-- calitest_cuestionarios


/* CAMBIOS EN CUESTIONARIOS LLEGAN A:
Body
PersonInBody 
Address
Communication
Body_ext
Relatedmaterial
IsPartOf
Recurso
Bodykeyword
Body_proy
Institucion
Person
Personas
********* Posiblemente mas tablas (Aqui solo aparecen las que tienen un contacto directo con body + Personas + Person)
*/
-- ===================================================================

-- Identificando los cuestionarios de prueba 
SELECT mb.body_id, citation, mb.created_when, mb.private FROM metages_body mb 
order by created_when desc;


-- Body
SELECT * FROM metages_body mb 
WHERE mb.body_id IN (1146, 1147);


-- Personinbody
SELECT * FROM metages_personinbody mp 
WHERE mp.body_fk IN (1146, 1147);

/* PELIGRO:Una persona puede estar conectada a varios bodies. 
 * No podemos borrar a personas reales por haberlas usado de prueba

-- Person
SELECT * FROM metages_person mp 
WHERE mp.person_id IN (SELECT mp.person_fk  FROM metages_personinbody mp 
WHERE mp.body_fk IN (1146, 1147));

-- Personas
SELECT * FROM metages_personas mp 
WHERE mp.person_fk IN (SELECT mp.person_fk  FROM metages_personinbody mp 
WHERE mp.body_fk IN (1146, 1147));

*/

-- Address
SELECT * FROM metages_address ma 
WHERE ma.address_id IN (SELECT mb.address_fk  FROM metages_body mb
WHERE mb.body_id IN (1146, 1147));


-- Communication
SELECT * FROM metages_communication mc 
WHERE mc.communication_id IN (SELECT mb.communication_fk FROM metages_body mb
WHERE mb.body_id IN (1146, 1147));


-- Institucion
-- Solo necesario si la institucion del cuestionario era real ya que no se vincula si no lo es
SELECT * FROM metages_institucion mi 
WHERE mi.body_fk IN (1146, 1147);

-- Body_ext
SELECT * FROM metages_body_ext mbe 
WHERE mbe.body_fk IN (1146, 1147);


-- Body_proy
-- Solo relevante si el body_type = proyecto?
SELECT * FROM metages_body_proy mbp  
WHERE mbp.body_fk IN (1146, 1147);

-- Body keyword
SELECT * FROM metages_bodykeyword mb   
WHERE mb.body_fk IN (1146, 1147);


-- Recurso
-- Solo necesario si el cuestionario incluia este tipo de informacion
select * from metages_recurso mr 
where mr.body_fk IN (1146, 1147);

-- IsPartOf
-- Solo necesario si la institucion del cuestionario era real ya que no se vincula si no lo es
select * from metages_ispartof mi 
WHERE mi.parent_body_fk IN (1146, 1147)
OR mi.child_body_fk IN (1146, 1147);

-- Related material
select * from metages_relatedmaterial mr 
where mr.body_fk IN (1146, 1147);

