-- recursos con IPTurl duplicada
with t1 as (
	select mr.url_ipt, 
			count(*) as num,
			mr.private 
	from metages_recurso mr 
	group by mr.url_ipt, mr.private  
	having count(*) > 1
	and mr.url_ipt <> ''
	and mr.private = 0)

select mr.title , mr.url_ipt , mr.url_gbiforg  from metages_recurso mr 
where mr.url_ipt in (select t1.url_ipt from t1)
order by mr.url_ipt 


-- recursos con titulo duplicado
with t1 as (select mr.title , count(*) as num ,
mr.private 
from metages_recurso mr 
group by mr.title, mr.private 
having count(*) > 1
and mr.title <> ''
and mr.private = 0)

select mr.title , mr.url_ipt , mr.url_gbiforg  from metages_recurso mr 
where mr.title in (select t1.title from t1)
order by mr.title 


-- recursos sin  IPT url
select * from metages_recurso mr 
where (mr.url_ipt is null 
or mr.url_ipt = '')
and mr.private = 0

-- recursos sin titulo
select * from metages_recurso mr 
where mr.title is null 
or mr.title = ''
and mr.private = 0