

CREATE OR REPLACE PACKAGE pkg_asignaciones AS
    -- Variables globales
    g_limite_max_asignacion CONSTANT NUMBER := 250000;
    
    -- Función para calcular honorarios
    FUNCTION calcular_honorarios(
        p_sueldo IN NUMBER
    ) RETURN NUMBER;
    
    -- Función para calcular asignación por tipo de contrato (por código)
    FUNCTION calcular_asig_contrato(
        p_cod_tpcontrato IN NUMBER,
        p_honorarios IN NUMBER
    ) RETURN NUMBER;
    
    -- Función para calcular asignación por profesión (por código, respecto del sueldo)
    FUNCTION calcular_asig_profesion(
        p_cod_profesion IN NUMBER,
        p_sueldo IN NUMBER
    ) RETURN NUMBER;
    
    -- Función para calcular asignación por movilización
    FUNCTION calcular_asig_movilizacion(
        p_comuna IN VARCHAR2,
        p_honorarios IN NUMBER
    ) RETURN NUMBER;
    
    -- Procedimiento para procesar asignaciones mensuales
    PROCEDURE procesar_asignaciones_mes(
        p_mes IN NUMBER,
        p_anio IN NUMBER
    );
    
    
END pkg_asignaciones;


