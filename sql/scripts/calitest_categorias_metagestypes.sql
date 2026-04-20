-- Categoria dentro de types a la cual pertenece cada fk

-- metages_cursos_gral.type_curso_type_fk
select distinct mt.types_fk 
from metages_cursos_gral mcg 
left join metages_types mt 
on mcg.type_curso_type_fk = mt.types_id 


-- metages_cursos_gral.niveldetaller_types_fk
select distinct mt.types_fk 
from metages_cursos_gral mcg 
left join metages_types mt 
on mcg.niveldetaller_types_fk = mt.types_id 

-- metages_cursos_gral.ambitodetaller_types_fk
select distinct mt.types_fk 
from metages_cursos_gral mcg 
left join metages_types mt 
on mcg.ambitodetaller_types_fk = mt.types_id 

-- metages_cursos_gral.estadodetaller_types_fk
select distinct mt.types_fk 
from metages_cursos_gral mcg 
left join metages_types mt 
on mcg.estadodetaller_types_fk = mt.types_id 

-- metages_cursos_gral_item.cursos_gral_item_type_fk
select distinct mt.types_fk 
from metages_cursos_gral_item mcg 
left join metages_types mt 
on mcg.cursos_gral_item_type_fk = mt.types_id 

-- metages_pers_cur.pers_cur_relacion_fk
select distinct mt.types_fk 
from metages_pers_cur mcg 
left join metages_types mt 
on mcg.pers_cur_relacion_fk = mt.types_id 

-- metages_pers_proy.type_relation_fk
select distinct mt.types_fk 
from metages_pers_proy mcg 
left join metages_types mt 
on mcg.type_relation_fk = mt.types_id 

-- metages_proyectos.tematicaproyecto_types_fk
select distinct mt.types_fk 
from metages_proyectos mcg 
left join metages_types mt 
on mcg.tematicaproyecto_types_fk = mt.types_id 

-- metages_proyectos.estadoproyecto_types_fk
select distinct mt.types_fk 
from metages_proyectos mcg 
left join metages_types mt 
on mcg.estadoproyecto_types_fk = mt.types_id 

-- metages_proyectos.ambitoproyecto_types_fk
select distinct mt.types_fk 
from metages_proyectos mcg 
left join metages_types mt 
on mcg.ambitoproyecto_types_fk = mt.types_id 

-- metages_proyectos_items.proyecto_item_type_fk
select distinct mt.types_fk 
from metages_proyectos_items mcg 
left join metages_types mt 
on mcg.proyecto_item_type_fk = mt.types_id 

-- metages_questionnaire.type_questionnaire_fk
select distinct mt.types_fk 
from metages_questionnaire mcg 
left join metages_types mt 
on mcg.type_questionnaire_fk = mt.types_id 

-- metages_questionnaire.type_sub_questionnaire_fk
select distinct mt.types_fk 
from metages_questionnaire mcg 
left join metages_types mt 
on mcg.type_sub_questionnaire_fk = mt.types_id 