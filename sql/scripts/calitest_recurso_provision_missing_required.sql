  -- Consultas para identificar campos obligatorios
  

   -- provisiones sin fecha   
  select * from metages_provision_recurso mpr 
  where (mpr.provision_fecha is null or TRIM(mpr.provision_fecha) = '')
  and mpr.recurso_fk not in (select recurso_id from metages_recurso r where r.private = 0
  AND r.url_ipt IS NOT NULL
  AND TRIM(r.url_ipt) <> '')
  
  
  -- provisiones sin cantidad  
    select * from metages_provision_recurso mpr 
  where (mpr.provision_cantidad is null or TRIM(mpr.provision_cantidad) = '')
  and mpr.recurso_fk not in (select recurso_id from metages_recurso r where r.private = 0
  AND r.url_ipt IS NOT NULL
  AND TRIM(r.url_ipt) <> '')
  

-- provisiones sin version  
select * from metages_provision_recurso mpr 
  where (mpr.version  is null or TRIM(mpr.version) = '')
  and mpr.recurso_fk not in (select recurso_id from metages_recurso r where r.private = 0
  AND r.url_ipt IS NOT NULL
  AND TRIM(r.url_ipt) <> '')
  
  
-- recursos sin fecha creacion
  select * from metages_recurso mr 
  where mr.private = 0
  AND mr.url_ipt IS NOT NULL
  AND TRIM(mr.url_ipt) <> ''
  and (mr.created_when  is null or TRIM(mr.created_when) = '')
  
  
-- recursos sin numberOfRecords
  select * from metages_recurso mr 
  where mr.private = 0
  AND mr.url_ipt IS NOT NULL
  AND TRIM(mr.url_ipt) <> ''
  and (mr.numberOfRecords is null or TRIM(mr.numberOfRecords) = '')
  
  
  -- recursos sin version
  select * from metages_recurso mr 
  where mr.private = 0
  AND mr.url_ipt IS NOT NULL
  AND TRIM(mr.url_ipt) <> ''
  and (mr.datapaper_version is null or TRIM(mr.datapaper_version) = '')
 