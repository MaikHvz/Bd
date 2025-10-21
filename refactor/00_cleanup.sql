-- 00_cleanup.sql
-- Limpia completamente el esquema actual: elimina vistas, MVs, triggers,
-- paquetes y cuerpos, procedimientos, funciones, secuencias, sinónimos y tablas.
-- ADVERTENCIA: Esto eliminará TODOS los objetos y datos del esquema actual.
-- Asegúrate de ejecutar esto en el esquema correcto.

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
  PROCEDURE exec_drop(p_sql VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_sql;
    DBMS_OUTPUT.PUT_LINE('OK: ' || p_sql);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('SKIP: ' || p_sql || ' -> ' || SQLERRM);
  END;
BEGIN
  -- 1) Vistas
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'VIEW'
  ) LOOP
    exec_drop('DROP VIEW "' || r.object_name || '"');
  END LOOP;

  -- 2) Materialized Views
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'MATERIALIZED VIEW'
  ) LOOP
    exec_drop('DROP MATERIALIZED VIEW "' || r.object_name || '"');
  END LOOP;

  -- 3) Triggers
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'TRIGGER'
  ) LOOP
    exec_drop('DROP TRIGGER "' || r.object_name || '"');
  END LOOP;

  -- 4) Package Bodies
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE BODY'
  ) LOOP
    exec_drop('DROP PACKAGE BODY "' || r.object_name || '"');
  END LOOP;

  -- 5) Packages
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE'
  ) LOOP
    exec_drop('DROP PACKAGE "' || r.object_name || '"');
  END LOOP;

  -- 6) Procedures
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'PROCEDURE'
  ) LOOP
    exec_drop('DROP PROCEDURE "' || r.object_name || '"');
  END LOOP;

  -- 7) Functions
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'FUNCTION'
  ) LOOP
    exec_drop('DROP FUNCTION "' || r.object_name || '"');
  END LOOP;

  -- 8) Sequences
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'SEQUENCE'
  ) LOOP
    exec_drop('DROP SEQUENCE "' || r.object_name || '"');
  END LOOP;

  -- 9) Synonyms (privados del esquema)
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'SYNONYM'
  ) LOOP
    exec_drop('DROP SYNONYM "' || r.object_name || '"');
  END LOOP;

  -- 10) Tablas (al final) con cascade y purge
  FOR r IN (
    SELECT object_name FROM user_objects WHERE object_type = 'TABLE'
  ) LOOP
    exec_drop('DROP TABLE "' || r.object_name || '" CASCADE CONSTRAINTS PURGE');
  END LOOP;
END;
/

PROMPT Esquema limpiado (objetos y datos eliminados).