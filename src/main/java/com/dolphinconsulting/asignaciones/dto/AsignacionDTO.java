package com.dolphinconsulting.asignaciones.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class AsignacionDTO {
    private String runProfesional;
    private Integer mes;
    private Integer anio;
    private BigDecimal asignacionHonorarios;
    private BigDecimal asignacionContrato;
    private BigDecimal asignacionProfesion;
    private BigDecimal asignacionMovilidad;
    private BigDecimal totalAsignaciones;
    private ProfesionalDTO profesional;
}