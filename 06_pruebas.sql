-- ******************************************
-- Archivo: 06_pruebas.sql
-- Autor: Estudiante de Informática
-- Fecha: 2023
-- Descripción: Script de pruebas para el paquete de asignaciones
-- ******************************************

-- Configuración de salida
SET SERVEROUTPUT ON
SET LINESIZE 120
SET PAGESIZE 999

-- Prueba 1: Calcular honorarios
DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := pkg_asignaciones.calcular_honorarios(1000000);
    DBMS_OUTPUT.PUT_LINE('Prueba 1: Honorarios para sueldo de 1.000.000 = ' || v_resultado);
END;
/

-- Prueba 2: Calcular asignación por tipo de contrato
DECLARE
    v_resultado NUMBER;
    v_cod NUMBER;
BEGIN
    SELECT cod_tpcontrato INTO v_cod FROM tipo_contrato WHERE nombre_tpcontrato = 'Plazo fijo';
    v_resultado := pkg_asignaciones.calcular_asig_contrato(v_cod, 100000);
    DBMS_OUTPUT.PUT_LINE('Prueba 2: Asignación para contrato Plazo fijo = ' || v_resultado);
    
    SELECT cod_tpcontrato INTO v_cod FROM tipo_contrato WHERE nombre_tpcontrato = 'Honorarios';
    v_resultado := pkg_asignaciones.calcular_asig_contrato(v_cod, 100000);
    DBMS_OUTPUT.PUT_LINE('Prueba 2: Asignación para contrato Honorarios = ' || v_resultado);
    
    SELECT cod_tpcontrato INTO v_cod FROM tipo_contrato WHERE nombre_tpcontrato = 'Indefinido Jornada Completa';
    v_resultado := pkg_asignaciones.calcular_asig_contrato(v_cod, 100000);
    DBMS_OUTPUT.PUT_LINE('Prueba 2: Asignación para contrato Indefinido Jornada Completa = ' || v_resultado);
END;
/

-- Prueba 3: Calcular asignación por profesión
DECLARE
    v_resultado NUMBER;
    v_cod NUMBER;
BEGIN
    SELECT cod_profesion INTO v_cod FROM profesion WHERE nombre_profesion = 'Arquitecto';
    v_resultado := pkg_asignaciones.calcular_asig_profesion(v_cod, 100000);
    DBMS_OUTPUT.PUT_LINE('Prueba 3: Asignación para profesión Arquitecto = ' || v_resultado);
    
    SELECT cod_profesion INTO v_cod FROM profesion WHERE nombre_profesion = 'Abogado';
    v_resultado := pkg_asignaciones.calcular_asig_profesion(v_cod, 100000);
    DBMS_OUTPUT.PUT_LINE('Prueba 3: Asignación para profesión Abogado = ' || v_resultado);
END;
/

-- Prueba 4: Calcular asignación por movilización
DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := pkg_asignaciones.calcular_asig_movilizacion('Santiago', 300000);
    DBMS_OUTPUT.PUT_LINE('Prueba 4: Asignación movilización para Santiago = ' || v_resultado);
    
    v_resultado := pkg_asignaciones.calcular_asig_movilizacion('Ñuñoa', 300000);
    DBMS_OUTPUT.PUT_LINE('Prueba 4: Asignación movilización para Ñuñoa = ' || v_resultado);
END;
/

-- Prueba 5: Procesar asignaciones para el mes actual
BEGIN
    DBMS_OUTPUT.PUT_LINE('Prueba 5: Procesando asignaciones para el mes actual...');
    pkg_asignaciones.procesar_asignaciones_mes(EXTRACT(MONTH FROM SYSDATE), EXTRACT(YEAR FROM SYSDATE));
    DBMS_OUTPUT.PUT_LINE('Procesamiento completado.');
END;
/

-- Prueba 6: Listar asignaciones del mes actual (sin JSON)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM detalle_asignacion_mes
    WHERE mes_proceso = EXTRACT(MONTH FROM SYSDATE)
      AND anno_proceso = EXTRACT(YEAR FROM SYSDATE);

    DBMS_OUTPUT.PUT_LINE('Prueba 6: Asignaciones encontradas = ' || v_count);

    FOR r IN (
        SELECT run_profesional, nombre_profesional, monto_total_asignaciones
        FROM detalle_asignacion_mes
        WHERE mes_proceso = EXTRACT(MONTH FROM SYSDATE)
          AND anno_proceso = EXTRACT(YEAR FROM SYSDATE)
        ORDER BY monto_total_asignaciones DESC
        FETCH FIRST 5 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(' - ' || r.run_profesional || ' ' || r.nombre_profesional || ' total=' || r.monto_total_asignaciones);
    END LOOP;
END;
/

-- Prueba 7: Listar errores registrados (sin JSON)
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM errores_proceso;

    DBMS_OUTPUT.PUT_LINE('Prueba 7: Errores registrados = ' || v_count);

    FOR e IN (
        SELECT error_id, mensaje_error_usr, mensaje_error_oracle
        FROM errores_proceso
        ORDER BY error_id DESC
        FETCH FIRST 5 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(' - ID=' || e.error_id || ' usr=' || e.mensaje_error_usr || ' ora=' || e.mensaje_error_oracle);
    END LOOP;
END;
/

-- Prueba 8: Verificar trigger de auditoría
DECLARE
    v_count NUMBER;
BEGIN
    -- Actualizar un sueldo para activar el trigger
    UPDATE profesional
    SET sueldo = sueldo * 1.05
    WHERE ROWNUM = 1;
    
    -- Verificar si se registró en la auditoría
    SELECT COUNT(*) INTO v_count
    FROM auditoria_sueldos
    WHERE TRUNC(fecha_cambio) = TRUNC(SYSDATE);
    
    DBMS_OUTPUT.PUT_LINE('Prueba 8: Registros en auditoría = ' || v_count);
    
    -- Hacer rollback para no afectar datos reales
    ROLLBACK;
END;
/

-- Prueba 9: Disparar trigger de auditoría de sueldos (con commit)
DECLARE
    v_run   profesional.numrun_prof%TYPE;
    v_old   NUMBER;
    v_new   NUMBER;
    v_count NUMBER;
    v_id    NUMBER;
BEGIN
    -- Tomar un profesional y su sueldo actual
    SELECT numrun_prof, sueldo INTO v_run, v_old
      FROM profesional
     WHERE ROWNUM = 1
     FOR UPDATE;

    -- Subir sueldo 5% para disparar el trigger
    v_new := ROUND(v_old * 1.05);
    UPDATE profesional SET sueldo = v_new WHERE numrun_prof = v_run;
    COMMIT;  -- Persistir para que la auditoría quede registrada

    DBMS_OUTPUT.PUT_LINE('Trigger disparado: RUN='||v_run||' sueldo '||v_old||' -> '||v_new);

    -- Verificar auditoría del día
    SELECT COUNT(*) INTO v_count
      FROM auditoria_sueldos
     WHERE numrun_prof = v_run
       AND TRUNC(fecha_cambio) = TRUNC(SYSDATE);
    DBMS_OUTPUT.PUT_LINE('Auditorías registradas hoy para RUN='||v_run||': '||v_count);

    -- Mostrar último ID auditado
    SELECT id_auditoria INTO v_id
      FROM (
        SELECT id_auditoria
          FROM auditoria_sueldos
         WHERE numrun_prof = v_run
         ORDER BY fecha_registro DESC
      )
     WHERE ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('Última auditoría ID='||v_id);

    -- Restaurar sueldo original (genera otra auditoría)
    UPDATE profesional SET sueldo = v_old WHERE numrun_prof = v_run;
    COMMIT;
END;
/
PROMPT Pruebas completadas