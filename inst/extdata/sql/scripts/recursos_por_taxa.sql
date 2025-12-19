-- Explorando keywords de los recursos para sacar Invertebrados
SELECT mr.recurso_id, mr.body_fk, mr.numberOfRecords, 
    	   mr.url_ipt, mr.title, mtd.descripcion_dataset AS disciplina_def,
    	   mr.met_palabras_clave, mk.keyword  
	FROM metages_recurso mr 
	LEFT JOIN metages_tipo_dataset mtd 
	ON mr.tipo_dataset = CAST(mtd.tipo_dataset_id AS CHAR) OR mr.tipo_dataset = mtd.tipo_dataset 
	LEFT JOIN metages_recursokeyword mr2 
	ON mr.recurso_id = mr2.recurso_fk 
	LEFT JOIN metages_keyword mk 
	ON mr2.keyword_fk = mk.keyword_id 
	WHERE mr.tipo_dataset <> '' 
	AND mr.numberOfRecords <> 0 -- Quita checklists, metadata only y errores
	AND mr.private = 0
	AND mtd.tipo_dataset_id BETWEEN 12 AND 17 -- Solo recursos  
	-- AND mr.met_palabras_clave <> ''

	

