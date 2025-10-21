-- VARIABLES GLOBALES (afuera del bloque PL/SQL)

VARIABLE b_fecha VARCHAR2(6);

EXEC :b_fecha := '202509';

VARIABLE b_limite_asig NUMBER;

EXEC :b_limite_asig := 250000;



-- BLOQUE PRINCIPAL

DECLARE

  -- Cursores para leer datos base

    CURSOR cur_profesionales IS
    SELECT
        p.numrun_prof,
        p.dvrun_prof,
        p.nombre,
        p.sueldo,
        p.cod_tpcontrato,
        p.cod_profesion,
        c.nom_comuna
    FROM
             profesional p
        JOIN comuna c ON p.cod_comuna = c.cod_comuna;



  -- Variables de cálculo

    v_monto_honorarios   NUMBER(12) := 0;
    v_asig_mov           NUMBER(12) := 0;
    v_asig_tpcont        NUMBER(12) := 0;
    v_asig_prof          NUMBER(12) := 0;
    v_total_asignaciones NUMBER(12) := 0;
    v_porc_tpcont        NUMBER(6, 4);
    v_porc_prof          NUMBER(6, 4);



  -- Mensajes de error

    v_msg                VARCHAR2(300);
    v_msgusr             VARCHAR2(300);



  -- Excepción personalizada si se supera el límite de asignaciones

    asignacion_limite EXCEPTION;
BEGIN

  -- Recorremos cada profesional

    FOR reg IN cur_profesionales LOOP

    -- Inicializar variables por profesional

        v_monto_honorarios := 0;
        v_asig_mov := 0;
        v_asig_tpcont := 0;
        v_asig_prof := 0;
        v_total_asignaciones := 0;
        v_porc_tpcont := 0;
        v_porc_prof := 0;



    -- Obtener porcentaje del tipo de contrato

        BEGIN
            SELECT
                incentivo / 100
            INTO v_porc_tpcont
            FROM
                tipo_contrato
            WHERE
                cod_tpcontrato = reg.cod_tpcontrato;

        EXCEPTION
            WHEN no_data_found THEN
                v_msg := sqlerrm;
                v_msgusr := 'No existe tipo contrato para RUN=' || reg.numrun_prof;
                INSERT INTO errores_proceso (
                    error_id,
                    mensaje_error_oracle,
                    mensaje_error_usr
                ) VALUES (
                    sq_error.NEXTVAL,
                    v_msg,
                    v_msgusr
                );

                CONTINUE;
            WHEN OTHERS THEN
                v_msg := sqlerrm;
                v_msgusr := 'Error al obtener tipo contrato para RUN=' || reg.numrun_prof;
                INSERT INTO errores_proceso (
                    error_id,
                    mensaje_error_oracle,
                    mensaje_error_usr
                ) VALUES (
                    sq_error.NEXTVAL,
                    v_msg,
                    v_msgusr
                );

                CONTINUE;
        END;



    -- Calcular asignación por tipo de contrato

        v_asig_tpcont := round(reg.sueldo * v_porc_tpcont);



    -- Obtener porcentaje de la profesión

        BEGIN
            SELECT
                asignacion
            INTO v_porc_prof
            FROM
                porcentaje_profesion
            WHERE
                cod_profesion = reg.cod_profesion;

        EXCEPTION
            WHEN no_data_found THEN
                v_msg := sqlerrm;
                v_msgusr := 'No existe porcentual de profesion para RUN=' || reg.numrun_prof;
                INSERT INTO errores_proceso (
                    error_id,
                    mensaje_error_oracle,
                    mensaje_error_usr
                ) VALUES (
                    sq_error.NEXTVAL,
                    v_msg,
                    v_msgusr
                );

                CONTINUE;
            WHEN OTHERS THEN
                v_msg := sqlerrm;
                v_msgusr := 'Error al obtener porcentual profesion run=' || reg.numrun_prof;
                INSERT INTO errores_proceso (
                    error_id,
                    mensaje_error_oracle,
                    mensaje_error_usr
                ) VALUES (
                    sq_error.NEXTVAL,
                    v_msg,
                    v_msgusr
                );

                CONTINUE;
        END;



    -- Calcular asignación por profesión

        v_asig_prof := round(reg.sueldo * v_porc_prof);



    -- Calcular monto honorarios

        v_monto_honorarios := round(reg.sueldo * 0.10);



    -- Calcular monto movilización extra

        BEGIN
            IF
                reg.nom_comuna = 'Santiago'
                AND v_monto_honorarios < 350000
            THEN
                v_asig_mov := round(v_monto_honorarios * 0.02);
            ELSIF reg.nom_comuna = 'Ñuñoa' THEN
                v_asig_mov := round(v_monto_honorarios * 0.04);
            ELSIF
                reg.nom_comuna = 'La Reina'
                AND v_monto_honorarios < 400000
            THEN
                v_asig_mov := round(v_monto_honorarios * 0.05);
            ELSIF
                reg.nom_comuna = 'La Florida'
                AND v_monto_honorarios < 800000
            THEN
                v_asig_mov := round(v_monto_honorarios * 0.07);
            ELSIF
                reg.nom_comuna = 'Macul'
                AND v_monto_honorarios < 680000
            THEN
                v_asig_mov := round(v_monto_honorarios * 0.09);
            ELSE
                v_asig_mov := 0;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                v_asig_mov := 0;
        END;



    -- Totalizar asignaciones

        v_total_asignaciones := v_monto_honorarios + v_asig_mov + v_asig_tpcont + v_asig_prof;



    -- Validar límite máximo global de asignaciones

        BEGIN
            IF v_total_asignaciones > :b_limite_asig THEN
                RAISE asignacion_limite;
            END IF;
        EXCEPTION
            WHEN asignacion_limite THEN
                v_msg := 'ASIGNACION LIMITE';
                v_msgusr := 'El RUN='
                            || reg.numrun_prof
                            || ' supero el limite. Total calculado='
                            || v_total_asignaciones
                            || ' - Se ajusta a '
                            || :b_limite_asig;

                INSERT INTO errores_proceso (
                    error_id,
                    mensaje_error_oracle,
                    mensaje_error_usr
                ) VALUES (
                    sq_error.NEXTVAL,
                    v_msg,
                    v_msgusr
                );

        -- Se ajusta el total

                v_total_asignaciones := :b_limite_asig;
        END;



    -- Insertar resultado final en detalle_asignacion_mes

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
            substr(:b_fecha, - 2),
            substr(:b_fecha, 1, 4),
            reg.numrun_prof,
            reg.nombre,
            reg.cod_profesion,
            1,
            v_monto_honorarios,
            v_asig_mov,
            v_asig_tpcont,
            v_asig_prof,
            v_total_asignaciones
        );

    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_msg := sqlerrm;
        v_msgusr := 'Error general en proceso de asignaciones';
        BEGIN
            INSERT INTO errores_proceso (
                error_id,
                mensaje_error_oracle,
                mensaje_error_usr
            ) VALUES (
                sq_error.NEXTVAL,
                v_msg,
                v_msgusr
            );

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        RAISE;
END;
/