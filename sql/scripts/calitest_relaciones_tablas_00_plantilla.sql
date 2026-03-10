/* ============================================================
   INICIALIZACIÓN DEL SISTEMA QA DE RELACIONES
   ============================================================

   Este script crea la tabla persistente `metages_qa_fk_mapping`.

   Se ejecuta UNA SOLA VEZ.

   Esta tabla almacenará el catálogo de relaciones lógicas
   entre tablas del sistema MetaGES.

   No se debe volver a ejecutar salvo que se quiera recrear
   completamente el sistema. Por ejemplo, si se ha eliminado
   la tablas `metages_qa_fk_mapping` por error.
   ============================================================ */


CREATE TABLE IF NOT EXISTS metages_qa_fk_mapping (

    id INT AUTO_INCREMENT PRIMARY KEY,

    /* ========================================================
       TABLA HIJA
       ======================================================== */

    child_table VARCHAR(255) NOT NULL,
    child_column VARCHAR(255) NOT NULL,

    /* ========================================================
       TABLA PADRE
       ======================================================== */

    parent_table VARCHAR(255) NOT NULL,
    parent_column VARCHAR(255) NOT NULL,

    /* ========================================================
       CONTROL DEL SISTEMA QA
       ======================================================== */

    enabled BOOLEAN DEFAULT TRUE,

    validation_status VARCHAR(20) DEFAULT 'PENDING',

    validation_message VARCHAR(255) DEFAULT NULL,

    /* ========================================================
       METADATOS DE LA RELACIÓN
       ======================================================== */

    relation_type VARCHAR(50) DEFAULT 'many-to-one',

    confidence VARCHAR(20) DEFAULT 'auto',

    notes TEXT,

    /* ========================================================
       METADATOS DEL REGISTRO
       ======================================================== */

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    /* ========================================================
       RESTRICCIONES
       ======================================================== */

    UNIQUE KEY uq_fk_relation (child_table, child_column)

);


/* ============================================================
   ÍNDICES ÚTILES
   ============================================================ */

CREATE INDEX idx_fk_child ON metages_qa_fk_mapping(child_table);

CREATE INDEX idx_fk_parent ON metages_qa_fk_mapping(parent_table);

CREATE INDEX idx_fk_enabled ON metages_qa_fk_mapping(enabled);

CREATE INDEX idx_fk_validation_status ON metages_qa_fk_mapping(validation_status);