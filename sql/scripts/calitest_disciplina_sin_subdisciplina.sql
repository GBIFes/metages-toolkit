-- necesitan subdisciplina botanica mixta
SELECT mb.body_id, mb.citation, mb.disciplina_fk, mb.created_when   
FROM metages_body mb  
WHERE mb.body_id NOT IN (SELECT body_fk FROM metages_body_disciplina_subtipo mbds)
AND mb.body_type_fk IN (3, 5)
AND mb.disciplina_fk BETWEEN 6 AND 11
AND mb.private = 0
AND mb.disciplina_fk = 8;

  
-- necesitan subdisciplina zoologica  
SELECT mb.body_id, mb.citation, mb.disciplina_fk, mb.created_when   
FROM metages_body mb  
WHERE mb.body_id NOT IN (SELECT body_fk FROM metages_body_disciplina_subtipo mbds)
AND mb.body_type_fk IN (3, 5)
AND mb.disciplina_fk BETWEEN 6 AND 11
AND mb.private = 0
AND mb.disciplina_fk = 6



