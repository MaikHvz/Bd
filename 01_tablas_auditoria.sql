
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


