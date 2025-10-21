-- ******************************************
-- Archivo: 01_tablas_auditoria.sql
-- Autor: Estudiante de Informática
-- Fecha: 2023
-- Descripción: Crea tabla para auditoría de sueldos
-- ******************************************

-- Tabla para guardar los cambios de sueldos
CREATE TABLE auditoria_sueldos (
    id_auditoria NUMBER PRIMARY KEY,
    numrun_prof NUMBER(10),
    fecha_cambio DATE,
    sueldo_anterior NUMBER(12),
    sueldo_nuevo NUMBER(12),
    usuario VARCHAR2(30),
    terminal VARCHAR2(50),
    fecha_registro TIMESTAMP
);

-- Secuencia para generar IDs de auditoría
CREATE SEQUENCE seq_auditoria_sueldos 
START WITH 1 
INCREMENT BY 1 
NOCACHE 
NOCYCLE;



-- Mensaje de confirmación
PROMPT Tabla de auditoría y secuencia creadas correctamente