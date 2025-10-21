-- ******************************************
-- Archivo: 12_proceso_bloque_plsql.sql
-- Descripción: Bloque PL/SQL anónimo que implementa el proceso
-- Requisitos: Ejecutar con variables bind y usar VARRAY para porcentajes
-- ******************************************

SET SERVEROUTPUT ON SIZE UNLIMITED;
-- Prevenir DML en paralelo (evita ORA-12838 al leer tras inserciones direct-path)
ALTER SESSION DISABLE PARALLEL DML;

-- Variables bind requeridas
VARIABLE b_fecha VARCHAR2(6);
VARIABLE b_limite_asig NUMBER;

-- Ejemplo: junio 2021 y límite 250.000
EXEC :b_fecha := '202106';
EXEC :b_limite_asig := 250000;

-- Limpieza de tablas
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_asignacion_mes';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE resumen_mes_profesion';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE errores_proceso';
END;
/

-- Recrear secuencia de errores
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE sq_error';
  EXCEPTION WHEN OTHERS THEN NULL; END;
  EXECUTE IMMEDIATE 'CREATE SEQUENCE sq_error START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
END;
/

DECLARE
  -- Tipos y estructuras
  TYPE t_pct_varray IS VARRAY(5) OF NUMBER;
  v_pct t_pct_varray := t_pct_varray(0.02, 0.04, 0.05, 0.07, 0.09);

  TYPE t_prof_rec IS RECORD (
    numrun_prof    NUMBER,
    dvrun_prof     VARCHAR2(1),
    nombre_completo VARCHAR2(200),
    sueldo         NUMBER,
    cod_tpcontrato NUMBER,
    cod_profesion  NUMBER,
    nom_comuna     VARCHAR2(100)
  );
  r_prof t_prof_rec;

  TYPE t_calc_rec IS RECORD (
    nro_asesorias          NUMBER,
    monto_honorarios       NUMBER,
    asig_movil             NUMBER,
    asig_contrato          NUMBER,
    asig_profesion         NUMBER,
    total_asignaciones     NUMBER
  );
  r_calc t_calc_rec;

  CURSOR cur_profesionales IS
    SELECT p.numrun_prof,
           p.dvrun_prof,
           p.nombre || ' ' || p.appaterno || ' ' || p.apmaterno AS nombre_completo,
           p.sueldo,
           p.cod_tpcontrato,
           p.cod_profesion,
           c.nom_comuna
      FROM profesional p
      JOIN comuna c ON p.cod_comuna = c.cod_comuna;

  v_mes  NUMBER := TO_NUMBER(SUBSTR(:b_fecha, -2));
  v_anio NUMBER := TO_NUMBER(SUBSTR(:b_fecha, 1, 4));

  v_porc_tpcont NUMBER;
  v_porc_prof   NUMBER;
  v_err         VARCHAR2(300);

  asignacion_limite EXCEPTION;
BEGIN
  FOR p IN cur_profesionales LOOP
    -- Mapear cursor al record
    r_prof.numrun_prof := p.numrun_prof;
    r_prof.dvrun_prof := p.dvrun_prof;
    r_prof.nombre_completo := p.nombre_completo;
    r_prof.sueldo := p.sueldo;
    r_prof.cod_tpcontrato := p.cod_tpcontrato;
    r_prof.cod_profesion := p.cod_profesion;
    r_prof.nom_comuna := p.nom_comuna;

    -- Inicializar
    r_calc.nro_asesorias := 0;
    r_calc.monto_honorarios := 0;
    r_calc.asig_movil := 0;
    r_calc.asig_contrato := 0;
    r_calc.asig_profesion := 0;
    r_calc.total_asignaciones := 0;

    -- Cantidad y monto de asesorías (SELECTs separados)
    SELECT NVL(COUNT(*), 0)
      INTO r_calc.nro_asesorias
      FROM asesoria
     WHERE numrun_prof = r_prof.numrun_prof
       AND EXTRACT(MONTH FROM inicio_asesoria) = v_mes
       AND EXTRACT(YEAR  FROM inicio_asesoria) = v_anio;

    SELECT NVL(SUM(honorario), 0)
      INTO r_calc.monto_honorarios
      FROM asesoria
     WHERE numrun_prof = r_prof.numrun_prof
       AND EXTRACT(MONTH FROM inicio_asesoria) = v_mes
       AND EXTRACT(YEAR  FROM inicio_asesoria) = v_anio;

    -- Porcentaje tipo contrato
    BEGIN
      SELECT incentivo/100 INTO v_porc_tpcont
        FROM tipo_contrato
       WHERE cod_tpcontrato = r_prof.cod_tpcontrato;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
        VALUES (sq_error.NEXTVAL, 'NO_DATA_FOUND', 'No existe tipo contrato para RUN='||r_prof.numrun_prof);
        v_porc_tpcont := 0; -- continuar con cero
      WHEN OTHERS THEN
        v_err := SQLERRM;
        INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
        VALUES (sq_error.NEXTVAL, v_err, 'Error al obtener tipo contrato para RUN='||r_prof.numrun_prof);
        v_porc_tpcont := 0; -- continuar con cero
    END;

    -- Asignación por tipo contrato (sobre honorarios)
    r_calc.asig_contrato := ROUND(r_calc.monto_honorarios * v_porc_tpcont);

    -- Porcentaje profesión
    BEGIN
      SELECT asignacion INTO v_porc_prof
        FROM porcentaje_profesion
       WHERE cod_profesion = r_prof.cod_profesion;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
        VALUES (sq_error.NEXTVAL, 'NO_DATA_FOUND', 'No existe porcentual de profesión para RUN='||r_prof.numrun_prof);
        v_porc_prof := 0;
      WHEN OTHERS THEN
        v_err := SQLERRM;
        INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
        VALUES (sq_error.NEXTVAL, v_err, 'Error al obtener porcentual profesión RUN='||r_prof.numrun_prof);
        v_porc_prof := 0;
    END;

    -- Asignación por profesión (sobre sueldo)
    r_calc.asig_profesion := ROUND(r_prof.sueldo * (v_porc_prof/100));

    -- Asignación movilización usando VARRAY (sobre honorarios)
    IF r_prof.nom_comuna = 'Santiago' AND r_calc.monto_honorarios < 350000 THEN
      r_calc.asig_movil := ROUND(r_calc.monto_honorarios * v_pct(1));
    ELSIF r_prof.nom_comuna = 'Ñuñoa' THEN
      r_calc.asig_movil := ROUND(r_calc.monto_honorarios * v_pct(2));
    ELSIF r_prof.nom_comuna = 'La Reina' AND r_calc.monto_honorarios < 400000 THEN
      r_calc.asig_movil := ROUND(r_calc.monto_honorarios * v_pct(3));
    ELSIF r_prof.nom_comuna = 'La Florida' AND r_calc.monto_honorarios < 800000 THEN
      r_calc.asig_movil := ROUND(r_calc.monto_honorarios * v_pct(4));
    ELSIF r_prof.nom_comuna = 'Macul' AND r_calc.monto_honorarios < 680000 THEN
      r_calc.asig_movil := ROUND(r_calc.monto_honorarios * v_pct(5));
    ELSE
      r_calc.asig_movil := 0;
    END IF;

    -- Total de asignaciones (sin honorarios)
    r_calc.total_asignaciones := r_calc.asig_contrato + r_calc.asig_profesion + r_calc.asig_movil;

    -- Límite máximo por bind
    IF r_calc.total_asignaciones > :b_limite_asig THEN
      INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
      VALUES (sq_error.NEXTVAL, 'ASIGNACION LIMITE', 'RUN='||r_prof.numrun_prof||' superó el límite; ajustado a '||:b_limite_asig);
      r_calc.total_asignaciones := :b_limite_asig;
    END IF;

    -- Insert detalle
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
      v_mes,
      v_anio,
      TO_CHAR(r_prof.numrun_prof)||'-'||r_prof.dvrun_prof,
      r_prof.nombre_completo,
      (SELECT nombre_profesion FROM profesion WHERE cod_profesion = r_prof.cod_profesion),
      r_calc.nro_asesorias,
      r_calc.monto_honorarios,
      r_calc.asig_movil,
      r_calc.asig_contrato,
      r_calc.asig_profesion,
      r_calc.total_asignaciones
    );
  END LOOP;

  -- Cerrar la modificación de detalle antes de leer para resumen
  COMMIT;

  -- Resumen por profesión
  DELETE FROM resumen_mes_profesion WHERE anno_mes_proceso = (v_anio*100 + v_mes);
  INSERT INTO resumen_mes_profesion (
    anno_mes_proceso, profesion, total_asesorias,
    monto_total_honorarios, monto_total_movil_extra, monto_total_asig_tipocont, monto_total_asig_prof, monto_total_asignaciones
  )
  SELECT (v_anio*100 + v_mes), d.profesion, SUM(d.nro_asesorias),
         SUM(d.monto_honorarios),
         SUM(d.monto_movil_extra),
         SUM(d.monto_asig_tipocont),
         SUM(d.monto_asig_profesion),
         SUM(d.monto_total_asignaciones)
    FROM detalle_asignacion_mes d
   WHERE d.mes_proceso = v_mes AND d.anno_proceso = v_anio
   GROUP BY d.profesion;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    v_err := SQLERRM;
    INSERT INTO errores_proceso(error_id, mensaje_error_oracle, mensaje_error_usr)
    VALUES (sq_error.NEXTVAL, v_err, 'Error general en bloque anónimo');
    COMMIT;
    RAISE;
END;
/

-- Consultas de verificación
PROMPT Detalle asignaciones (top 10):
SELECT * FROM (
  SELECT run_profesional, nombre_profesional, monto_total_asignaciones
    FROM detalle_asignacion_mes
   WHERE mes_proceso = TO_NUMBER(SUBSTR(:b_fecha, -2))
     AND anno_proceso = TO_NUMBER(SUBSTR(:b_fecha, 1, 4))
   ORDER BY monto_total_asignaciones DESC
) WHERE ROWNUM <= 10;
/

PROMPT Resumen por profesión:
SELECT *
  FROM resumen_mes_profesion
 WHERE anno_mes_proceso = TO_NUMBER(:b_fecha)
 ORDER BY profesion;
/

PROMPT Errores (últimos 10):
SELECT * FROM (
  SELECT error_id, mensaje_error_usr, mensaje_error_oracle
    FROM errores_proceso
   ORDER BY error_id DESC
) WHERE ROWNUM <= 10;
/