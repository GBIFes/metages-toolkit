-- Recursos con url que no se ha podido leer
SELECT tipo_recurso, monitor_status, COUNT(*)
FROM metages_recurso_monitor
GROUP BY tipo_recurso, monitor_status;

-- Recursos con cambios
SELECT tipo_recurso, event_type, COUNT(*)
FROM metages_recurso_monitor_log
GROUP BY tipo_recurso, event_type;



