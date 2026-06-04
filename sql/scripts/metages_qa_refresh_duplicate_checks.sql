-- ===================================================================
-- Autor: Ruben Perez
-- Fecha de Creación: 2026-01-27
-- Descripción: Analisis de duplicas en metages
--              
-- Base de datos: gbif_wp
-- Procedimiento: metages_qa_refresh_duplicate_checks
-- ===================================================================

DROP PROCEDURE IF EXISTS gbif_wp.metages_qa_refresh_duplicate_checks;

DELIMITER $$
$$



CREATE DEFINER=`gbif_us`@`localhost` PROCEDURE `gbif_wp`.`metages_qa_refresh_duplicate_checks`()
BEGIN
    /* -------------------------------------------------------
       Variables de control del cursor
       ------------------------------------------------------- */
    DECLARE v_done INT DEFAULT 0;

    /* -------------------------------------------------------
       Variables leídas desde metages_qa_duplicate_checks
       ------------------------------------------------------- */
    DECLARE v_check_id INT;
    DECLARE v_check_name VARCHAR(150);
    DECLARE v_from_sql LONGTEXT;
    DECLARE v_key_sql VARCHAR(1000);
    DECLARE v_where_sql LONGTEXT;

    /* -------------------------------------------------------
       SQL generado automáticamente
       ------------------------------------------------------- */
    DECLARE v_explore_sql LONGTEXT;
    DECLARE v_sample_sql LONGTEXT;
    DECLARE v_count_sql LONGTEXT;

    /* -------------------------------------------------------
       Cursor: lee solo checks activos
       ------------------------------------------------------- */
    DECLARE cur CURSOR FOR
        SELECT
            check_id,
            check_name,
            from_sql,
            key_sql,
            where_sql
        FROM metages_qa_duplicate_checks
        WHERE active = 1
        ORDER BY check_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO
            v_check_id,
            v_check_name,
            v_from_sql,
            v_key_sql,
            v_where_sql;

        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        /* Reset por cada check */
        SET v_explore_sql = NULL;
        SET v_sample_sql = NULL;
        SET v_count_sql = NULL;
        SET @dup_count = NULL;

        /* ---------------------------------------------------
           Validación mínima: from_sql obligatorio
           --------------------------------------------------- */
        IF v_from_sql IS NULL OR TRIM(v_from_sql) = '' THEN

            UPDATE metages_qa_duplicate_checks
            SET
                last_run_at = NOW(),
                duplicate_count = NULL,
                explore_sql = NULL,
                sample_sql = NULL,
                status = 'ERROR',
                status_message = 'from_sql vacio'
            WHERE check_id = v_check_id;

        /* ---------------------------------------------------
           Validación mínima: key_sql obligatorio
           --------------------------------------------------- */
        ELSEIF v_key_sql IS NULL OR TRIM(v_key_sql) = '' THEN

            UPDATE metages_qa_duplicate_checks
            SET
                last_run_at = NOW(),
                duplicate_count = NULL,
                explore_sql = NULL,
                sample_sql = NULL,
                status = 'ERROR',
                status_message = 'key_sql vacio'
            WHERE check_id = v_check_id;

        ELSE

            /* ------------------------------------------------
               explore_sql:
               Consulta resumen.

               Devuelve:
               - duplicate_key
               - n = número de filas por clave duplicada

               Usa CTEs:
               - base: dataset lógico del check
               - dup: claves duplicadas
               ------------------------------------------------ */
            SET v_explore_sql = CONCAT(
                'WITH base AS (',
                    'SELECT ',
                        '*, ',
                        v_key_sql,
                        ' AS duplicate_key ',
                    'FROM ',
                        v_from_sql,
                    CASE
                        WHEN v_where_sql IS NOT NULL AND TRIM(v_where_sql) <> ''
                        THEN CONCAT(' WHERE ', v_where_sql)
                        ELSE ''
                    END,
                '), ',
                'dup AS (',
                    'SELECT ',
                        'duplicate_key, ',
                        'COUNT(*) AS n ',
                    'FROM base ',
                    'GROUP BY duplicate_key ',
                    'HAVING COUNT(*) > 1',
                ') ',
                'SELECT ',
                    'duplicate_key, ',
                    'n ',
                'FROM dup ',
                'ORDER BY n DESC, duplicate_key;'
            );

            /* ------------------------------------------------
               v_count_sql:
               Consulta ejecutada internamente por el procedimiento.

               Calcula duplicate_count como:
               número de claves distintas duplicadas.

               Ejemplo:
               A aparece 3 veces
               B aparece 2 veces
               C aparece 1 vez

               duplicate_count = 2
               ------------------------------------------------ */
            SET v_count_sql = CONCAT(
                'WITH base AS (',
                    'SELECT ',
                        v_key_sql,
                        ' AS duplicate_key ',
                    'FROM ',
                        v_from_sql,
                    CASE
                        WHEN v_where_sql IS NOT NULL AND TRIM(v_where_sql) <> ''
                        THEN CONCAT(' WHERE ', v_where_sql)
                        ELSE ''
                    END,
                '), ',
                'dup AS (',
                    'SELECT duplicate_key ',
                    'FROM base ',
                    'GROUP BY duplicate_key ',
                    'HAVING COUNT(*) > 1',
                ') ',
                'SELECT COUNT(*) INTO @dup_count ',
                'FROM dup'
            );

            /* ------------------------------------------------
               sample_sql:
               Consulta de inspección.

               Devuelve todas las filas de base que pertenecen
               a una clave duplicada, además del conteo n.

               IMPORTANTE:
               Para checks con joins, v_from_sql debe venir limpio:
               - sin SELECT *
               - sin columnas repetidas
               - usando aliases únicos

               Ejemplo recomendado para from_sql con joins:

               (
                   SELECT
                       mb.body_id AS body_id,
                       mb.collection_code AS collection_code,
                       mb.private AS body_private,
                       mi.parent_body_fk AS parent_body_fk
                   FROM metages_body mb
                   LEFT JOIN metages_ispartof mi
                       ON mb.body_id = mi.child_body_fk
               ) src
               ------------------------------------------------ */
            SET v_sample_sql = CONCAT(
                'WITH base AS (',
                    'SELECT ',
                        '*, ',
                        v_key_sql,
                        ' AS duplicate_key ',
                    'FROM ',
                        v_from_sql,
                    CASE
                        WHEN v_where_sql IS NOT NULL AND TRIM(v_where_sql) <> ''
                        THEN CONCAT(' WHERE ', v_where_sql)
                        ELSE ''
                    END,
                '), ',
                'dup AS (',
                    'SELECT ',
                        'duplicate_key, ',
                        'COUNT(*) AS n ',
                    'FROM base ',
                    'GROUP BY duplicate_key ',
                    'HAVING COUNT(*) > 1',
                ') ',
                'SELECT ',
                    'base.*, ',
                    'dup.n ',
                'FROM base ',
                'INNER JOIN dup ',
                    'ON base.duplicate_key = dup.duplicate_key ',
                'ORDER BY dup.n DESC, base.duplicate_key;'
            );

            /* ------------------------------------------------
               Ejecutar solo la consulta de conteo.
               explore_sql y sample_sql se guardan como texto.
               ------------------------------------------------ */
            SET @sql_count = v_count_sql;

            PREPARE stmt FROM @sql_count;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            /* ------------------------------------------------
               Guardar resultados en la propia tabla de checks
               ------------------------------------------------ */
            UPDATE metages_qa_duplicate_checks
            SET
                last_run_at = NOW(),
                duplicate_count = @dup_count,
                explore_sql = v_explore_sql,
                sample_sql = v_sample_sql,
                status = 'OK',
                status_message = NULL
            WHERE check_id = v_check_id;

        END IF;

    END LOOP;

    CLOSE cur;
END$$
DELIMITER ;
