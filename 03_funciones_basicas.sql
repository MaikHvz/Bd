-- ******************************************
-- Archivo: 03_funciones_basicas.sql
-- Autor: Estudiante de Informática
-- Fecha: 2023
-- Descripción: Crea funciones básicas para cálculos
-- ******************************************

-- Función para calcular honorarios
CREATE OR REPLACE FUNCTION fn_calcular_honorarios(
    p_sueldo IN NUMBER
) RETURN NUMBER IS
BEGIN
    -- Calcula el 10% del sueldo como honorarios
    RETURN ROUND(p_sueldo * 0.10);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Función para calcular asignación por movilización
CREATE OR REPLACE FUNCTION fn_calcular_asig_movilizacion(
    p_comuna IN VARCHAR2,
    p_honorarios IN NUMBER
) RETURN NUMBER IS
    v_asig_mov NUMBER := 0;
BEGIN
    -- Aplica las reglas según la comuna y el monto de honorarios
    IF p_comuna = 'Santiago' AND p_honorarios < 350000 THEN
        v_asig_mov := ROUND(p_honorarios * 0.02);
    ELSIF p_comuna = 'Nunoa' THEN
        v_asig_mov := ROUND(p_honorarios * 0.04);
    ELSIF p_comuna = 'La Reina' AND p_honorarios < 400000 THEN
        v_asig_mov := ROUND(p_honorarios * 0.05);
    ELSIF p_comuna = 'La Florida' AND p_honorarios < 800000 THEN
        v_asig_mov := ROUND(p_honorarios * 0.07);
    ELSIF p_comuna = 'Macul' AND p_honorarios < 680000 THEN
        v_asig_mov := ROUND(p_honorarios * 0.09);
    END IF;
    
    RETURN v_asig_mov;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Procedimiento para registrar errores
CREATE OR REPLACE PROCEDURE sp_registrar_error(
    p_msg IN VARCHAR2,
    p_msgusr IN VARCHAR2
) IS
BEGIN
    -- Inserta el error en la tabla de errores
    INSERT INTO errores_proceso (
        error_id,
        mensaje_error_oracle,
        mensaje_error_usr
    ) VALUES (
        sq_error.NEXTVAL,
        p_msg,
        p_msgusr
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Evita error en el registro de errores
END;
/

-- Mensaje de confirmación
PROMPT Funciones y procedimientos básicos creados correctamente