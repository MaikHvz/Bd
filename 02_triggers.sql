
--  Crea trigger para auditar cambios de sueldos


-- Trigger que se activa cuando cambia el sueldo de un profesional
CREATE OR REPLACE TRIGGER trg_auditoria_sueldos
AFTER UPDATE OF sueldo ON profesional
FOR EACH ROW
BEGIN
    -- Guarda los datos del cambio en la tabla de auditoría
    INSERT INTO auditoria_sueldos (
        id_auditoria,
        numrun_prof,
        fecha_cambio,
        sueldo_anterior,
        sueldo_nuevo,
        usuario,
        terminal,
        fecha_registro
    ) VALUES (
        seq_auditoria_sueldos.NEXTVAL,
        :OLD.numrun_prof,
        SYSDATE,
        :OLD.sueldo,
        :NEW.sueldo,
        USER,
        SYS_CONTEXT('USERENV', 'TERMINAL'),
        SYSTIMESTAMP
    );
END;
/

ALTER TRIGGER trg_auditoria_sueldos ENABLE;
