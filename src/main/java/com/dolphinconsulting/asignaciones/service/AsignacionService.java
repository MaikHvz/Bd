package com.dolphinconsulting.asignaciones.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Service
public class AsignacionService {

    private final JdbcTemplate jdbcTemplate;

    public AsignacionService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // Invoca el procedimiento principal del paquete
    public void procesarAsignaciones(int mes, int anio) {
        String sql = "BEGIN pkg_asignaciones.procesar_asignaciones_mes(?, ?); END;";
        jdbcTemplate.update(sql, mes, anio);
    }

    // Lista detalles de asignaciones por mes/año, opcionalmente filtrado por RUN
    public List<Map<String, Object>> listarAsignaciones(Integer mes, Integer anio, String run) {
        String base = "SELECT numrun_prof, mes, anio, asig_honorarios, asig_contrato, asig_profesion, asig_movilizacion, total_asignaciones, fecha_registro " +
                      "FROM detalle_asignacion_mes WHERE mes = ? AND anio = ?";
        if (run != null && !run.isBlank()) {
            base += " AND numrun_prof = ?";
            return jdbcTemplate.queryForList(base + " ORDER BY numrun_prof", mes, anio, run);
        }
        return jdbcTemplate.queryForList(base + " ORDER BY numrun_prof", mes, anio);
    }

    // Auditoría de sueldos
    public List<Map<String, Object>> listarAuditorias() {
        String sql = "SELECT id_auditoria, numrun_prof, fecha_cambio, sueldo_anterior, sueldo_nuevo, usuario, terminal, fecha_registro " +
                     "FROM auditoria_sueldos ORDER BY fecha_registro DESC";
        return jdbcTemplate.queryForList(sql);
    }

    // Búsqueda por nombre o RUT
    public List<Map<String, Object>> buscarProfesionales(String q) {
        String sqlNombre = "SELECT numrun_prof, dv_run, nombre, appaterno, apmaterno, sueldo, cod_tpcontrato, cod_comuna, cod_profesion " +
                           "FROM profesional WHERE UPPER(nombre || ' ' || appaterno || ' ' || apmaterno) LIKE UPPER(?)";
        String sqlRut = "SELECT numrun_prof, dv_run, nombre, appaterno, apmaterno, sueldo, cod_tpcontrato, cod_comuna, cod_profesion " +
                        "FROM profesional WHERE numrun_prof = ?";
        try {
            // Si es numérico, buscar por RUN
            long rut = Long.parseLong(q.replace(".", "").replace("-", "").trim());
            return jdbcTemplate.queryForList(sqlRut, rut);
        } catch (NumberFormatException e) {
            // Si no es numérico, buscar por nombre
            return jdbcTemplate.queryForList(sqlNombre, "%" + q + "%");
        }
    }

    // Actualiza sueldo para disparar el trigger
    public int actualizarSueldo(String run, BigDecimal nuevoSueldo) {
        String sql = "UPDATE profesional SET sueldo = ? WHERE numrun_prof = ?";
        return jdbcTemplate.update(sql, nuevoSueldo, run);
    }

    // Pruebas de funciones del paquete
    public BigDecimal calcularHonorarios(BigDecimal sueldo) {
        String sql = "SELECT pkg_asignaciones.calcular_honorarios(?) FROM dual";
        return jdbcTemplate.queryForObject(sql, BigDecimal.class, sueldo);
    }

    public BigDecimal calcularAsigContrato(Integer codTpContrato, BigDecimal honorarios) {
        String sql = "SELECT pkg_asignaciones.calcular_asig_contrato(?, ?) FROM dual";
        return jdbcTemplate.queryForObject(sql, BigDecimal.class, codTpContrato, honorarios);
    }

    public BigDecimal calcularAsigProfesion(Integer codProfesion, BigDecimal sueldo) {
        String sql = "SELECT pkg_asignaciones.calcular_asig_profesion(?, ?) FROM dual";
        return jdbcTemplate.queryForObject(sql, BigDecimal.class, codProfesion, sueldo);
    }

    public BigDecimal calcularAsigMovilizacion(Integer codComuna, BigDecimal honorarios) {
        String sql = "SELECT pkg_asignaciones.calcular_asig_movilizacion(?, ?) FROM dual";
        return jdbcTemplate.queryForObject(sql, BigDecimal.class, codComuna, honorarios);
    }
}