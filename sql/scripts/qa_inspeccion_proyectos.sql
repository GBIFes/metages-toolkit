-- Habra que establecer claves relacionales

-- relacion proyectos con body
select mb.citation, mb.body_type_fk , mb.private ,
mp.*
from metages_body mb 
left join metages_body_proy mbp 
on mb.body_id = mbp.body_fk 
left join metages_proyectos mp 
on mbp.proy_fk = mp.proyectos_id
where mp.proyectos_id is not null;


-- relaciones de proyectos con otras tablas
select mp.url, mp.proyectos_nombre , 
mpt.*, 
mpc.*,
mpi.*
from metages_proyectos mp 
left join metages_proy_estados mpe  -- no parece haber conexion
on mp.estadoproyecto_types_fk =mpe.proy_estados_id 
left join metages_proy_tipos mpt  -- tipo de proyecto (CESP, BID...) -> como el cat
on mp.proy_tipos_fk = mpt.proy_tipos_id 
left join metages_proy_cat mpc  -- categoria del proyecto (GBIF.org, UdC, Ministerio...)
on mpt.proy_cat_fk = mpc.proy_cat_id
left join metages_proyectos_items mpi -- los items pueden ser fotos, videos, documentos o webs relacionados con un proyecto
on mp.proyectos_id = mpi.proyecto_fk  ;


-- relacion de proyectos con personas
select mp.url, mpp.* 
from metages_proyectos mp 
left join metages_pers_proy mpp 
on mp.proyectos_id = mpp.proyecto_fk 
