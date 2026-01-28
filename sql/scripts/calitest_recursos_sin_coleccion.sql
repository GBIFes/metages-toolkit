
-- instituciones ligadas a recursos
select * from metages_body mb2 where mb2.body_id in (

-- recursos ligados directamente a instituciones
SELECT *
FROM metages_recurso mr
LEFT JOIN metages_tipo_dataset mtd
    ON mr.tipo_dataset = CAST(mtd.tipo_dataset_id AS CHAR)
    OR mr.tipo_dataset = mtd.tipo_dataset
LEFT JOIN metages_body mb
    ON mr.body_fk = mb.body_id
WHERE
    -- filtros comunes (antiguos y nuevos)
    mr.tipo_dataset <> ''
    AND mr.numberOfRecords <> 0
    AND mr.private = 0
    AND mtd.tipo_dataset_id BETWEEN 12 AND 17

    -- ⛔️ estos son los que YA NO entran en la nueva vista
    AND (
           mb.body_id IS NULL
        OR mb.body_type_fk NOT IN (3, 5)
        OR mb.disciplina_fk NOT BETWEEN 6 AND 11
        OR mb.private <> 0
    ))
