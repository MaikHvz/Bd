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
        RETURN fn_calcular_honorarios(p_sueldo);
    END calcular_honorarios;
    
    -- Función para calcular asignación por tipo de contrato (tabla TIPO_CONTRATO)
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
            INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
            VALUES (sq_error.NEXTVAL, 'Tipo de contrato no válido: ' || p_cod_tpcontrato, 'Error al calcular asignación por contrato');
            COMMIT;
            RETURN 0;
        WHEN OTHERS THEN
            v_err := SQLERRM;
            INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
            VALUES (sq_error.NEXTVAL, v_err, 'Error al calcular asignación por contrato');
            COMMIT;
            RETURN 0;
    END calcular_asig_contrato;
    
    -- Función para calcular asignación por profesión (tabla PORCENTAJE_PROFESION)
    FUNCTION calcular_asig_profesion(
        p_cod_profesion IN NUMBER,
        p_sueldo IN NUMBER
    ) RETURN NUMBER IS
        v_pct NUMBER;
        v_err VARCHAR2(300);
    BEGIN
        SELECT asignacion INTO v_pct
        FROM PORCENTAJE_PROFESION
        WHERE cod_profesion = p_cod_profesion;

        -- La asignación profesional se calcula respecto del sueldo
        RETURN ROUND(p_sueldo * (v_pct/100));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
            VALUES (sq_error.NEXTVAL, 'Profesión no válida: ' || p_cod_profesion, 'Error al calcular asignación por profesión');
            COMMIT;
            RETURN 0;
        WHEN OTHERS THEN
            v_err := SQLERRM;
            INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
            VALUES (sq_error.NEXTVAL, v_err, 'Error al calcular asignación por profesión');
            COMMIT;
            RETURN 0;
    END calcular_asig_profesion;
    
    -- Función para calcular asignación por movilización
    FUNCTION calcular_asig_movilizacion(
        p_comuna IN VARCHAR2,
        p_honorarios IN NUMBER
    ) RETURN NUMBER IS
    BEGIN
        RETURN fn_calcular_asig_movilizacion(p_comuna, p_honorarios);
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
            
        v_nro_asesorias NUMBER := 0;
        v_monto_honorarios NUMBER := 0;
        v_honorarios NUMBER := 0;
        v_asig_contrato NUMBER := 0;
        v_asig_profesion NUMBER := 0;
        v_asig_movilizacion NUMBER := 0;
        v_total_asignaciones NUMBER := 0;
        v_err VARCHAR2(300);
    BEGIN
        -- Limpieza de tablas para permitir re-ejecuciones
        EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_asignacion_mes';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_mes_profesion';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE errores_proceso';
        
        -- Recrear secuencia de errores
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE sq_error';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        EXECUTE IMMEDIATE 'CREATE SEQUENCE sq_error START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
        
        -- Procesar cada profesional
        FOR r_prof IN c_profesionales LOOP
            BEGIN
                -- Asesorías del mes: cantidad y monto
                SELECT NVL(COUNT(*), 0), NVL(SUM(honorario), 0)
                  INTO v_nro_asesorias, v_monto_honorarios
                  FROM asesoria
                 WHERE numrun_prof = r_prof.numrun_prof
                   AND EXTRACT(MONTH FROM inicio_asesoria) = p_mes
                   AND EXTRACT(YEAR FROM inicio_asesoria) = p_anio;

                -- Base de honorarios
                v_honorarios := v_monto_honorarios;
                
                -- Asignación por tipo de contrato (sobre honorarios)
                v_asig_contrato := calcular_asig_contrato(r_prof.cod_tpcontrato, v_honorarios);
                
                -- Asignación por profesión (sobre sueldo)
                v_asig_profesion := calcular_asig_profesion(r_prof.cod_profesion, r_prof.sueldo);
                
                -- Asignación por movilización (sobre honorarios)
                v_asig_movilizacion := calcular_asig_movilizacion(r_prof.nombre_comuna, v_honorarios);
                
                -- Calcular total de asignaciones (no incluye honorarios)
                v_total_asignaciones := v_asig_contrato + v_asig_profesion + v_asig_movilizacion;
                
                -- Verificar límite máximo
                IF v_total_asignaciones > g_limite_max_asignacion THEN
                    INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
                    VALUES (sq_error.NEXTVAL, 'Límite excedido', 'El profesional ' || r_prof.nombre_completo || ' excede el límite de asignaciones');
                    COMMIT;
                    v_total_asignaciones := g_limite_max_asignacion;
                END IF;
                
                -- Insertar en tabla de asignaciones (esquema real)
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
                    TO_CHAR(r_prof.numrun_prof) || '-' || r_prof.dvrun_prof,
                    r_prof.nombre_completo,
                    (SELECT nombre_profesion FROM profesion WHERE cod_profesion = r_prof.cod_profesion),
                    v_nro_asesorias,
                    v_honorarios,
                    v_asig_movilizacion,
                    v_asig_contrato,
                    v_asig_profesion,
                    v_total_asignaciones
                );
                
            EXCEPTION
                WHEN OTHERS THEN
                    v_err := SQLERRM;
                    INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
                    VALUES (sq_error.NEXTVAL, v_err, 'Error al procesar asignaciones para ' || r_prof.nombre_completo);
                    COMMIT;
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
        GROUP BY d.profesion;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            v_err := SQLERRM;
            INSERT INTO errores_proceso (error_id, mensaje_error_oracle, mensaje_error_usr)
            VALUES (sq_error.NEXTVAL, v_err, 'Error general en procesamiento de asignaciones');
            COMMIT;
    END procesar_asignaciones_mes;
    
    -- (Eliminada función JSON: la aplicación consultará directamente DETALLE_ASIGNACION_MES)
    
    -- (Eliminada función JSON de errores; la aplicación puede consultar ERRORES_PROCESO si se requiere)
    
END pkg_asignaciones;
/

-- Mensaje de confirmación
PROMPT Cuerpo del paquete creado correctamente