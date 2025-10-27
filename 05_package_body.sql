-- ******************************************
-- Archivo: 05_package_body.sql
-- Autor: Estudiante de Informática
-- Fecha: 2023
-- Descripción: Implementación del paquete de asignaciones
-- ******************************************

CREATE OR REPLACE PACKAGE BODY pkg_asignaciones AS

    -- Función para calcular honorarios
    FUNCTION calcular_honorarios(
        p_sueldo IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN ROUND(p_sueldo * 0.10);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END calcular_honorarios;

    -- Función para calcular asignación por tipo de contrato
    FUNCTION calcular_asig_contrato(
        p_cod_tpcontrato IN NUMBER,
        p_honorarios IN NUMBER
    ) RETURN NUMBER IS
        v_pct NUMBER;
        v_err VARCHAR2(300);
    BEGIN
        SELECT incentivo INTO v_pct
        FROM tipo_contrato
        WHERE cod_tpcontrato = p_cod_tpcontrato;

        RETURN ROUND(p_honorarios * (v_pct/100));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            registrar_error('Tipo de contrato no válido: ' || p_cod_tpcontrato,
                            'Error al calcular asignación por contrato');
            RETURN 0;
        WHEN OTHERS THEN
            v_err := SQLERRM;
            registrar_error(v_err, 'Error al calcular asignación por contrato');
            RETURN 0;
    END calcular_asig_contrato;

    -- Función para calcular asignación por profesión
    FUNCTION calcular_asig_profesion(
        p_cod_profesion IN NUMBER,
        p_sueldo IN NUMBER
    ) RETURN NUMBER IS
        v_pct NUMBER;
        v_err VARCHAR2(300);
    BEGIN
        SELECT asignacion INTO v_pct
        FROM porcentaje_profesion
        WHERE cod_profesion = p_cod_profesion;

        RETURN ROUND(p_sueldo * (v_pct/100));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            registrar_error('Profesión no válida: ' || p_cod_profesion,
                            'Error al calcular asignación por profesión');
            RETURN 0;
        WHEN OTHERS THEN
            v_err := SQLERRM;
            registrar_error(v_err, 'Error al calcular asignación por profesión');
            RETURN 0;
    END calcular_asig_profesion;

    -- Función para calcular asignación por movilización
    FUNCTION calcular_asig_movilizacion(
        p_comuna IN VARCHAR2,
        p_honorarios IN NUMBER
    ) RETURN NUMBER IS
        v_asig_mov NUMBER := 0;
        v_comuna_upper VARCHAR2(50) := UPPER(p_comuna);
    BEGIN
        IF v_comuna_upper = 'SANTIAGO' AND p_honorarios < 350000 THEN
            v_asig_mov := ROUND(p_honorarios * 0.02);
        ELSIF v_comuna_upper IN ('ÑUÑOA', 'NUÑOA', 'NUNOA') THEN
            v_asig_mov := ROUND(p_honorarios * 0.04);
        ELSIF v_comuna_upper = 'LA REINA' AND p_honorarios < 400000 THEN
            v_asig_mov := ROUND(p_honorarios * 0.05);
        ELSIF v_comuna_upper = 'LA FLORIDA' AND p_honorarios < 800000 THEN
            v_asig_mov := ROUND(p_honorarios * 0.07);
        ELSIF v_comuna_upper = 'MACUL' AND p_honorarios < 680000 THEN
            v_asig_mov := ROUND(p_honorarios * 0.09);
        END IF;
        RETURN v_asig_mov;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END calcular_asig_movilizacion;

    -- Procedimiento para procesar asignaciones mensuales
PROCEDURE procesar_asignaciones_mes(
    p_mes IN NUMBER,
    p_anio IN NUMBER
) IS
    CURSOR c_profesionales IS
        SELECT 
            p.numrun_prof,
            p.dvrun_prof,
            p.nombre || ' ' || p.appaterno || ' ' || p.apmaterno AS nombre_completo,
            p.sueldo,
            p.cod_tpcontrato,
            p.cod_profesion,
            c.nom_comuna AS nombre_comuna
        FROM profesional p
        JOIN comuna c ON p.cod_comuna = c.cod_comuna;

    v_err VARCHAR2(300);
    v_actualizados NUMBER := 0;
BEGIN
    -- Limpiar tablas y secuencia de errores
    EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_asignacion_mes';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_mes_profesion';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE errores_proceso';

    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE sq_error';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE sq_error START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';

    -- Llenar detalle de asignaciones por profesional
    FOR r_prof IN c_profesionales LOOP
        BEGIN
            llenar_detalle_asignacion_mes(p_mes, p_anio, r_prof.numrun_prof);
        EXCEPTION
            WHEN OTHERS THEN
                v_err := SQLERRM;
                registrar_error(v_err, 'Error al procesar asignaciones para ' || r_prof.nombre_completo);
        END;
    END LOOP;

    -- Generar resumen mensual por profesión
    DELETE FROM resumen_mes_profesion
     WHERE anno_mes_proceso = (p_anio*100 + p_mes);

    INSERT INTO resumen_mes_profesion (
        anno_mes_proceso,
        profesion,
        total_asesorias,
        monto_total_honorarios,
        monto_total_movil_extra,
        monto_total_asig_tipocont,
        monto_total_asig_prof,
        monto_total_asignaciones
    )
    SELECT 
        (p_anio*100 + p_mes),
        d.profesion,
        SUM(d.nro_asesorias),
        SUM(d.monto_honorarios),
        SUM(d.monto_movil_extra),
        SUM(d.monto_asig_tipocont),
        SUM(d.monto_asig_profesion),
        SUM(d.monto_total_asignaciones)
    FROM detalle_asignacion_mes d
    WHERE d.mes_proceso = p_mes
      AND d.anno_proceso = p_anio
    GROUP BY d.profesion
    ORDER BY d.profesion ASC;

    -- Actualizar sueldos de todos los profesionales según detalle_asignacion_mes
    MERGE INTO profesional p
    USING (
        SELECT 
            TO_NUMBER(REGEXP_SUBSTR(d.run_profesional, '^[0-9]+')) AS numrun,
            SUM(NVL(d.monto_total_asignaciones,0)) AS total_asig
        FROM detalle_asignacion_mes d
        WHERE d.mes_proceso = p_mes
          AND d.anno_proceso = p_anio
        GROUP BY TO_NUMBER(REGEXP_SUBSTR(d.run_profesional, '^[0-9]+'))
    ) src
    ON (p.numrun_prof = src.numrun)
    WHEN MATCHED THEN
      UPDATE SET p.sueldo = p.sueldo + src.total_asig;

    v_actualizados := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Sueldos actualizados: ' || v_actualizados);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        v_err := SQLERRM;
        INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
        VALUES (sq_error.NEXTVAL, v_err, 'Error general en procesamiento de asignaciones');
        COMMIT;
END procesar_asignaciones_mes;


PROCEDURE llenar_detalle_asignacion_mes(
    p_mes IN NUMBER,
    p_anio IN NUMBER,
    p_numrun_prof IN NUMBER
) IS
    v_dv            profesional.dvrun_prof%TYPE;
    v_nombre        profesional.nombre%TYPE;
    v_appaterno     profesional.appaterno%TYPE;
    v_apmaterno     profesional.apmaterno%TYPE;
    v_sueldo        profesional.sueldo%TYPE;
    v_cod_tpcontrato profesional.cod_tpcontrato%TYPE;
    v_cod_profesion profesional.cod_profesion%TYPE;
    v_nom_comuna    comuna.nom_comuna%TYPE;
    v_nro_asesorias NUMBER := 0;
    v_monto_honorarios NUMBER := 0;
    v_asig_contrato NUMBER := 0;
    v_asig_profesion NUMBER := 0;
    v_asig_movilizacion NUMBER := 0;
    v_total_asignaciones NUMBER := 0;
    v_profesion_nombre VARCHAR2(50);
    v_err VARCHAR2(300);
    v_run_sin_dv NUMBER;
BEGIN
    -- Datos base del profesional
    SELECT p.dvrun_prof, p.nombre, p.appaterno, p.apmaterno, p.sueldo,
           p.cod_tpcontrato, p.cod_profesion, c.nom_comuna
      INTO v_dv, v_nombre, v_appaterno, v_apmaterno, v_sueldo,
           v_cod_tpcontrato, v_cod_profesion, v_nom_comuna
      FROM profesional p
      JOIN comuna c ON p.cod_comuna = c.cod_comuna
     WHERE p.numrun_prof = p_numrun_prof;

    -- Cantidad y suma de honorarios del mes
    SELECT NVL(COUNT(*), 0)
      INTO v_nro_asesorias
      FROM asesoria
     WHERE numrun_prof = p_numrun_prof
       AND EXTRACT(MONTH FROM inicio_asesoria) = p_mes
       AND EXTRACT(YEAR  FROM inicio_asesoria) = p_anio;

    SELECT NVL(SUM(honorario), 0)
      INTO v_monto_honorarios
      FROM asesoria
     WHERE numrun_prof = p_numrun_prof
       AND EXTRACT(MONTH FROM inicio_asesoria) = p_mes
       AND EXTRACT(YEAR  FROM inicio_asesoria) = p_anio;

    -- Cálculos de asignaciones
    v_asig_contrato    := calcular_asig_contrato(v_cod_tpcontrato, v_monto_honorarios);
    v_asig_profesion   := calcular_asig_profesion(v_cod_profesion, v_sueldo);
    v_asig_movilizacion:= calcular_asig_movilizacion(v_nom_comuna, v_monto_honorarios);

    v_total_asignaciones := v_asig_contrato + v_asig_profesion + v_asig_movilizacion;

    -- Límite máximo
    IF v_total_asignaciones > g_limite_max_asignacion THEN
        registrar_error('Límite excedido', 'El profesional ' || v_nombre || ' excede el límite de asignaciones');
        v_total_asignaciones := g_limite_max_asignacion;
    END IF;

    -- Nombre de profesión
    SELECT nombre_profesion INTO v_profesion_nombre
      FROM profesion
     WHERE cod_profesion = v_cod_profesion;

    -- Limpiar run profesional para que quede solo números (para merge)
    v_run_sin_dv := TO_NUMBER(REGEXP_SUBSTR(TO_CHAR(p_numrun_prof), '^[0-9]+'));

    -- Insertar detalle
    INSERT INTO detalle_asignacion_mes (
        mes_proceso,
        anno_proceso,
        run_profesional,
        nombre_profesional,
        profesion,
        nro_asesorias,
        monto_honorarios,
        monto_movil_extra,
        monto_asig_tipocont,
        monto_asig_profesion,
        monto_total_asignaciones
    ) VALUES (
        p_mes,
        p_anio,
        v_run_sin_dv || '-' || v_dv, -- siempre en formato num-dv
        v_nombre || ' ' || v_appaterno || ' ' || v_apmaterno,
        v_profesion_nombre,
        v_nro_asesorias,
        v_monto_honorarios,
        v_asig_movilizacion,
        v_asig_contrato,
        v_asig_profesion,
        v_total_asignaciones
    );

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        registrar_error('Profesional no encontrado: ' || p_numrun_prof,
                        'Error al llenar detalle asignación');
    WHEN OTHERS THEN
        v_err := SQLERRM;
        registrar_error(v_err, 'Error al llenar detalle asignación');
END llenar_detalle_asignacion_mes;


    -- Procedimiento para registrar errores
    PROCEDURE registrar_error(
        p_msg IN VARCHAR2,
        p_msgusr IN VARCHAR2
    ) IS
    BEGIN
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
            NULL;
    END registrar_error;

END pkg_asignaciones;
/
