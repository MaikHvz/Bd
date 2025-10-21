package com.dolphinconsulting.asignaciones.service;

import com.dolphinconsulting.asignaciones.dto.AsignacionDTO;
import com.dolphinconsulting.asignaciones.dto.ProfesionalDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AsignacionService {

    private final JdbcTemplate jdbcTemplate;
    
    /**
     * Llama al procedimiento almacenado para procesar asignaciones
     */
    public void procesarAsignaciones(int mes, int anio) {
        jdbcTemplate.update("BEGIN pkg_asignaciones.procesar_asignaciones_mes(?, ?); END;", mes, anio);
    }

    /**
     * Obtiene las asignaciones desde la tabla DETALLE_ASIGNACION_MES y las mapea a DTO
     */
    public List<AsignacionDTO> obtenerAsignaciones(int mes, int anio) {
        String sql = "SELECT mes_proceso, anno_proceso, run_profesional, nombre_profesional, profesion, " +
                "nro_asesorias, monto_honorarios, monto_movil_extra, monto_asig_tipocont, " +
                "monto_asig_profesion, monto_total_asignaciones " +
                "FROM detalle_asignacion_mes " +
                "WHERE mes_proceso = ? AND anno_proceso = ?";

        RowMapper<AsignacionDTO> mapper = (rs, rowNum) -> {
            AsignacionDTO dto = new AsignacionDTO();
            dto.setMes(rs.getInt("mes_proceso"));
            dto.setAnio(rs.getInt("anno_proceso"));
            dto.setRunProfesional(rs.getString("run_profesional"));
            ProfesionalDTO prof = new ProfesionalDTO();
            prof.setNombre(rs.getString("nombre_profesional"));
            dto.setProfesional(prof);
            dto.setAsignacionHonorarios(rs.getBigDecimal("monto_honorarios"));
            dto.setAsignacionContrato(rs.getBigDecimal("monto_asig_tipocont"));
            dto.setAsignacionProfesion(rs.getBigDecimal("monto_asig_profesion"));
            dto.setAsignacionMovilidad(rs.getBigDecimal("monto_movil_extra"));
            dto.setTotalAsignaciones(rs.getBigDecimal("monto_total_asignaciones"));
            return dto;
        };

        return jdbcTemplate.query(sql, mapper, mes, anio);
    }

    /**
     * Obtiene las auditorías de sueldos (sin cambios de estructura)
     */
    public List<java.util.Map<String, Object>> obtenerAuditorias() {
        return jdbcTemplate.queryForList(
            "SELECT a.id_auditoria, a.numrun_prof, " +
            "p.nombre || ' ' || p.appaterno AS nombre, " +
            "a.fecha_cambio, a.sueldo_anterior, a.sueldo_nuevo, " +
            "a.usuario, a.terminal, a.fecha_registro " +
            "FROM auditoria_sueldos a " +
            "JOIN profesional p ON a.numrun_prof = p.numrun_prof " +
            "ORDER BY a.fecha_registro DESC"
        );
    }
}